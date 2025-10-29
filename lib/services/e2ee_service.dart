import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class E2EEKeys {
  final SimpleKeyPair privateKey;
  final SimplePublicKey publicKey;
  E2EEKeys({required this.privateKey, required this.publicKey});
}

class E2EEService {
  static const _prefPrivateKey = 'e2ee_private_key_x25519';
  static const _prefPublicKey = 'e2ee_public_key_x25519';
  final X25519 _x25519 = X25519();
  final AesGcm _aesGcm = AesGcm.with256bits();

  Future<E2EEKeys> ensureKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final privB64 = prefs.getString(_prefPrivateKey);
    final pubB64 = prefs.getString(_prefPublicKey);
    if (privB64 != null && pubB64 != null) {
      final privateKey = await _x25519.newKeyPairFromSeed(base64Decode(privB64));
      final publicKey = SimplePublicKey(base64Decode(pubB64), type: KeyPairType.x25519);
      return E2EEKeys(privateKey: privateKey, publicKey: publicKey);
    }
    final keyPair = await _x25519.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateKeyData = await keyPair.extractPrivateKeyBytes();
    await prefs.setString(_prefPrivateKey, base64Encode(privateKeyData));
    await prefs.setString(_prefPublicKey, base64Encode(publicKey.bytes));
    return E2EEKeys(privateKey: keyPair, publicKey: publicKey);
  }

  Future<void> publishPublicKey() async {
    final keys = await ensureKeys();
    final pubB64 = base64Encode(keys.publicKey.bytes);
    await apiService.setPublicKey(pubB64);
  }

  Future<SimplePublicKey> getUserPublicKey(String userId) async {
    final res = await apiService.getUserById(userId);
    final pk = (res['public_key'] ?? '') as String;
    if (pk.isEmpty) {
      throw Exception('У пользователя нет публичного ключа');
    }
    return SimplePublicKey(base64Decode(pk), type: KeyPairType.x25519);
  }

  Future<SecretKey> _deriveSharedSecret(SimpleKeyPair myPrivate, SimplePublicKey theirPublic) async {
    final shared = await _x25519.sharedSecretKey(keyPair: myPrivate, remotePublicKey: theirPublic);
    // HKDF derive 32 bytes
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    return await hkdf.deriveKey(secretKey: shared, nonce: const [], info: utf8.encode('chat-shared-secret'));
  }

  Future<String> encryptForUser({
    required String recipientUserId,
    required String plaintext,
  }) async {
    final keys = await ensureKeys();
    final theirPublic = await getUserPublicKey(recipientUserId);
    final secretKey = await _deriveSharedSecret(keys.privateKey, theirPublic);
    final nonce = _randomBytes(12);
    final secretBox = await _aesGcm.encrypt(utf8.encode(plaintext), secretKey: secretKey, nonce: nonce);
    final payload = {
      'alg': 'aesgcm',
      'nonce': base64Encode(nonce),
      'cipher': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };
    final encoded = base64Encode(utf8.encode(jsonEncode(payload)));
    return 'ENC::$encoded';
  }

  Future<String> decryptFromUser({
    required String senderUserId,
    required String ciphertext,
  }) async {
    if (!ciphertext.startsWith('ENC::')) return ciphertext;
    final b64 = ciphertext.substring(5);
    final jsonStr = utf8.decode(base64Decode(b64));
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final nonce = base64Decode(data['nonce']);
    final cipher = base64Decode(data['cipher']);
    final mac = Mac(base64Decode(data['mac']));
    final keys = await ensureKeys();
    final theirPublic = await getUserPublicKey(senderUserId);
    final secretKey = await _deriveSharedSecret(keys.privateKey, theirPublic);
    final clear = await _aesGcm.decrypt(SecretBox(cipher, nonce: nonce, mac: mac), secretKey: secretKey);
    return utf8.decode(clear);
  }

  List<int> _randomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }
}

final e2eeService = E2EEService();



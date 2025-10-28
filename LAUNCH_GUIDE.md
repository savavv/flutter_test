# 🚀 Руководство по запуску Telegram Clone

## 📋 Полный запуск проекта

### **1. Запуск бекенда (Python FastAPI)**

#### **Шаг 1: Перейти в папку бекенда**
```bash
cd backend
```

#### **Шаг 2: Установить зависимости (если нужно)**
```bash
# Установить основные зависимости
pip install fastapi uvicorn sqlalchemy python-jose passlib python-multipart python-dotenv pydantic

# Или установить все зависимости
pip install -r requirements.txt
```

#### **Шаг 3: Настроить базу данных**
```bash
# Быстрая настройка SQLite
python start_fast.py
```

#### **Шаг 4: Запустить сервер**
```bash
python run.py
```

**Бекенд будет доступен по адресу:**
- 🌐 **API**: http://localhost:8000
- 📚 **Документация**: http://localhost:8000/docs
- 📖 **ReDoc**: http://localhost:8000/redoc
- ❤️ **Health Check**: http://localhost:8000/health

---

### **2. Запуск Flutter приложения**

#### **Шаг 1: Перейти в корневую папку проекта**
```bash
cd ..  # Выйти из папки backend
```

#### **Шаг 2: Установить зависимости Flutter**
```bash
flutter pub get
```

#### **Шаг 3: Запустить Flutter приложение**
```bash
# Для веб-версии
flutter run -d chrome

# Для Android
flutter run

# Для iOS (только на macOS)
flutter run -d ios
```

**Flutter приложение будет доступно:**
- 🌐 **Web**: http://localhost:8080
- 📱 **Mobile**: На эмуляторе/устройстве

---

## 🔧 **Быстрый запуск (все в одном)**

### **Терминал 1: Бекенд**
```bash
cd backend
python start_fast.py
python run.py
```

### **Терминал 2: Flutter**
```bash
flutter pub get
flutter run -d chrome
```

---

## 🛠️ **Конфигурация для разработки**

### **Бекенд (.env файл)**
```env
DATABASE_TYPE=sqlite
USE_REDIS=false
DEBUG=true
ENCRYPT_PERSONAL_DATA=false
ENCRYPT_MESSAGES=false
```

### **Flutter (lib/main.dart)**
- API URL: `http://localhost:8000`
- WebSocket URL: `ws://localhost:8000`

---

## 🧪 **Тестирование**

### **1. Тест бекенда**
```bash
# Проверить health
curl http://localhost:8000/health

# Проверить API
curl http://localhost:8000/api/v1/auth/send-verification \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "+79914036115"}'
```

### **2. Тест Flutter**
1. Откройте http://localhost:8080
2. Введите номер телефона: `+79914036115`
3. Введите код: `9779` (из логов бекенда)
4. Настройте профиль
5. Протестируйте функции

---

## 🐛 **Решение проблем**

### **Проблема: Ошибка установки зависимостей**
```bash
# Решение 1: Обновить pip
pip install --upgrade pip

# Решение 2: Установить по одной
pip install fastapi uvicorn sqlalchemy

# Решение 3: Использовать виртуальное окружение
python -m venv venv
venv\Scripts\activate  # Windows
source venv/bin/activate  # Linux/Mac
```

### **Проблема: Ошибка базы данных**
```bash
# Удалить старую базу и создать новую
rm telegram_clone.db
python start_simple.py
```

### **Проблема: Flutter не подключается к API**
```bash
# Проверить, что бекенд запущен
curl http://localhost:8000/health

# Проверить CORS настройки в backend/app/main.py
```

---

## 📊 **Структура проекта**

```
flutter_application_1/
├── lib/                    # Flutter код
│   ├── main.dart
│   ├── screens/
│   ├── widgets/
│   └── theme/
├── backend/               # Python бекенд
│   ├── app/
│   ├── scripts/
│   ├── requirements.txt
│   └── run.py
└── LAUNCH_GUIDE.md       # Это руководство
```

---

## 🎯 **Готовые команды для копирования**

### **Запуск бекенда:**
```bash
cd backend
python start_fast.py
python run.py
```

### **Запуск Flutter:**
```bash
flutter pub get
flutter run -d chrome
```

### **Проверка работы:**
- Бекенд: http://localhost:8000/docs
- Flutter: http://localhost:8080
- API тест: http://localhost:8000/health

---

## 🎉 **Готово!**

Теперь у вас запущен полноценный Telegram Clone с:
- ✅ Безопасным бекендом на FastAPI
- ✅ Flutter приложением
- ✅ SQLite базой данных
- ✅ WebSocket для реального времени
- ✅ Загрузкой файлов
- ✅ Шифрованием данных

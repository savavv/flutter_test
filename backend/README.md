# Telegram Clone Backend

Backend API для Telegram Clone приложения, построенный на FastAPI.

## 🚀 Возможности

- **Аутентификация**: SMS-верификация через телефон с JWT токенами
- **Пользователи**: Управление профилями, поиск контактов
- **Чаты**: Создание приватных, групповых чатов и каналов
- **Сообщения**: Отправка текстовых сообщений, файлов, медиа
- **WebSocket**: Реальное время для сообщений и уведомлений
- **Файлы**: Загрузка и управление медиафайлами
- **🔒 Максимальная безопасность**: 
  - AES-256-GCM шифрование данных
  - Rate limiting и защита от DDoS
  - Security headers (CSP, HSTS, XSS Protection)
  - CSRF защита
  - Аудит безопасности
  - Поддержка SQLite для локального тестирования

## 🛠 Технологии

- **FastAPI** - современный веб-фреймворк для Python
- **SQLAlchemy** - ORM для работы с базой данных
- **PostgreSQL** - основная база данных
- **Redis** - кэширование и сессии
- **WebSocket** - реальное время
- **Alembic** - миграции базы данных
- **Pydantic** - валидация данных

## 📦 Установка

### Требования

- Python 3.9+
- PostgreSQL 12+
- Redis 6+

### Установка зависимостей

```bash
cd backend
pip install -r requirements.txt
```

### Настройка окружения

1. Скопируйте файл конфигурации:
```bash
cp env.example .env
```

2. Отредактируйте `.env` файл с вашими настройками:
```env
DATABASE_URL=postgresql://username:password@localhost:5432/telegram_clone
REDIS_URL=redis://localhost:6379
SECRET_KEY=your-secret-key-here
```

### Настройка базы данных

#### Вариант 1: SQLite (для локальной разработки)
```bash
# Переключиться на SQLite
python scripts/switch_to_sqlite.py sqlite

# Или вручную в .env файле:
DATABASE_TYPE=sqlite
USE_REDIS=false
```

#### Вариант 2: PostgreSQL (для продакшна)
1. Создайте базу данных PostgreSQL:
```sql
CREATE DATABASE telegram_clone;
```

2. Запустите миграции:
```bash
alembic upgrade head
```

3. Или переключитесь на PostgreSQL:
```bash
python scripts/switch_to_sqlite.py postgresql
```

## 🚀 Запуск

### Разработка

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Продакшн

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

## 📚 API Документация

После запуска сервера документация доступна по адресам:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## 🔗 API Endpoints

### Аутентификация
- `POST /api/v1/auth/send-verification` - Отправить SMS код
- `POST /api/v1/auth/verify-code` - Подтвердить код
- `POST /api/v1/auth/refresh-token` - Обновить токен
- `POST /api/v1/auth/logout` - Выход

### Пользователи
- `GET /api/v1/users/me` - Мой профиль
- `PUT /api/v1/users/me` - Обновить профиль
- `GET /api/v1/users/search` - Поиск пользователей
- `GET /api/v1/users/contacts` - Мои контакты
- `GET /api/v1/users/{user_id}` - Профиль пользователя

### Чаты
- `GET /api/v1/chats/` - Мои чаты
- `POST /api/v1/chats/` - Создать чат
- `GET /api/v1/chats/{chat_id}` - Информация о чате
- `PUT /api/v1/chats/{chat_id}` - Обновить чат
- `DELETE /api/v1/chats/{chat_id}` - Удалить чат

### Сообщения
- `GET /api/v1/messages/chat/{chat_id}` - Сообщения чата
- `POST /api/v1/messages/` - Отправить сообщение
- `GET /api/v1/messages/{message_id}` - Получить сообщение
- `PUT /api/v1/messages/{message_id}` - Редактировать сообщение
- `DELETE /api/v1/messages/{message_id}` - Удалить сообщение

### Файлы
- `POST /api/v1/files/upload` - Загрузить файл
- `GET /api/v1/files/{file_type}/{filename}` - Получить файл
- `DELETE /api/v1/files/{file_type}/{filename}` - Удалить файл

### WebSocket
- `WS /api/v1/ws/{token}` - Подключение к WebSocket
- `WS /api/v1/ws/chat/{chat_id}/{token}` - WebSocket для чата

## 🔐 Аутентификация

API использует JWT токены для аутентификации. Включите токен в заголовок:

```
Authorization: Bearer <your-token>
```

## 🛡️ Безопасность

### Шифрование данных
- **AES-256-GCM** для шифрования личных данных
- **PBKDF2** для генерации ключей шифрования
- **bcrypt** для хеширования паролей
- **JWT** токены с истечением срока действия

### Защита от атак
- **Rate Limiting** - защита от DDoS и брутфорса
- **CSRF Protection** - защита от межсайтовых атак
- **XSS Protection** - защита от XSS атак
- **SQL Injection** - защита через ORM
- **Security Headers** - комплексные заголовки безопасности

### Аудит безопасности
- Логирование подозрительной активности
- Отслеживание попыток взлома
- Мониторинг rate limiting
- Анализ паттернов атак

### Конфигурация безопасности
```env
# Включить шифрование
ENCRYPT_PERSONAL_DATA=true
ENCRYPT_MESSAGES=true

# Security Headers
ENABLE_SECURITY_HEADERS=true
ENABLE_CSRF_PROTECTION=true

# Rate Limiting
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=60
```

## 📱 WebSocket

Для подключения к WebSocket используйте токен:

```javascript
const ws = new WebSocket('ws://localhost:8000/api/v1/ws/your-jwt-token');
```

### События WebSocket

- `typing` - индикатор печати
- `new_message` - новое сообщение
- `user_online` - пользователь онлайн
- `user_offline` - пользователь офлайн
- `call` - входящий звонок

## 🗄 Структура базы данных

### Основные таблицы

- **users** - пользователи
- **chats** - чаты
- **chat_participants** - участники чатов
- **messages** - сообщения
- **phone_verifications** - верификация телефонов

## 🧪 Тестирование

```bash
pytest
```

## 📝 Логирование

Логи сохраняются в файл `app.log` и выводятся в консоль.

## 🚀 Деплой

### Docker

```bash
docker build -t telegram-clone-backend .
docker run -p 8000:8000 telegram-clone-backend
```

### Nginx

Пример конфигурации Nginx для проксирования:

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 🤝 Вклад в проект

1. Форкните репозиторий
2. Создайте ветку для новой функции
3. Внесите изменения
4. Создайте Pull Request

## 📄 Лицензия

MIT License

## 🆘 Поддержка

Если у вас есть вопросы или проблемы, создайте Issue в репозитории.

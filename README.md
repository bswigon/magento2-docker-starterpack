# Magento 2 Docker Environment

Kompletne środowisko Docker dla Magento 2 z MySQL, Elasticsearch, Redis i Nginx.

## 📋 Wymagania

- Docker Desktop 20.10+
- Docker Compose 2.0+
- Minimum 4GB RAM dostępnego dla Dockera
- Minimum 10GB wolnego miejsca na dysku

## 🚀 Szybki Start

### 1. Sklonuj lub pobierz projekt

Projekt zawiera wszystkie niezbędne pliki konfiguracyjne.

### 2. Skonfiguruj zmienne środowiskowe

Edytuj plik `.env` i dostosuj wartości według potrzeb:

```bash
# Dane dostępowe do bazy danych
MYSQL_ROOT_PASSWORD=root123
MYSQL_DATABASE=magento2
MYSQL_USER=magento
MYSQL_PASSWORD=magento123

# Dane administratora Magento
MAGENTO_ADMIN_USER=admin
MAGENTO_ADMIN_PASSWORD=Admin123!
MAGENTO_ADMIN_EMAIL=admin@example.com
```

### 3. Uruchom kontenery Docker

```bash
# Zbuduj obrazy Docker
docker-compose build

# Uruchom wszystkie usługi w tle
docker-compose up -d
```

### 4. Zainstaluj Magento

```bash
# Wejdź do kontenera PHP
docker-compose exec php bash

# Uruchom skrypt instalacyjny
bash /var/www/html/scripts/install-magento.sh
```

Instalacja może zająć 10-20 minut w zależności od prędkości internetu i komputera.

### 5. Otwórz Magento w przeglądarce

- **Frontend**: http://localhost
- **Panel Admin**: http://localhost/admin
  - Login: `admin` (lub wartość z `.env`)
  - Hasło: `Admin123!` (lub wartość z `.env`)
- **MailHog** (przechwytywanie emaili): http://localhost:8025

## 🏗️ Architektura

Projekt składa się z następujących kontenerów:

| Kontener | Usługa | Port | Opis |
|----------|--------|------|------|
| `magento2_nginx` | Nginx | 80, 443 | Serwer web |
| `magento2_php` | PHP 8.2-FPM | 9000 | Interpreter PHP z rozszerzeniami |
| `magento2_db` | MySQL 8.0 | 3306 | Baza danych |
| `magento2_elasticsearch` | Elasticsearch 7.17 | 9200 | Wyszukiwarka (wymagana) |
| `magento2_redis` | Redis 7 | 6379 | Cache i sesje |
| `magento2_mailhog` | MailHog | 1025, 8025 | Przechwytywanie emaili |

## 📁 Struktura Projektu

```
magento2/
├── docker-compose.yml          # Główna konfiguracja Docker Compose
├── Dockerfile                  # Obraz PHP z rozszerzeniami Magento
├── docker-entrypoint.sh        # Skrypt startowy kontenera PHP
├── .env                        # Zmienne środowiskowe
├── nginx/
│   ├── default.conf           # Konfiguracja virtual host
│   └── nginx.conf             # Główna konfiguracja Nginx
├── php/
│   ├── php.ini                # Konfiguracja PHP
│   └── php-fpm.conf           # Konfiguracja PHP-FPM
├── mysql/
│   └── my.cnf                 # Konfiguracja MySQL
├── scripts/
│   └── install-magento.sh     # Skrypt instalacji Magento
├── src/                       # Kod źródłowy Magento (generowany)
└── README.md                  # Ten plik
```

## 🔧 Przydatne Komendy

### Zarządzanie kontenerami

```bash
# Uruchom wszystkie kontenery
docker-compose up -d

# Zatrzymaj wszystkie kontenery
docker-compose down

# Zobacz logi wszystkich kontenerów
docker-compose logs -f

# Zobacz logi konkretnego kontenera
docker-compose logs -f php

# Sprawdź status kontenerów
docker-compose ps

# Restart wszystkich kontenerów
docker-compose restart
```

### Praca z Magento CLI

```bash
# Wejdź do kontenera PHP
docker-compose exec php bash

# Czyszczenie cache
docker-compose exec php bin/magento cache:flush

# Reindeksacja
docker-compose exec php bin/magento indexer:reindex

# Tryb developer/production
docker-compose exec php bin/magento deploy:mode:set developer
docker-compose exec php bin/magento deploy:mode:set production

# Deploy statycznych plików
docker-compose exec php bin/magento setup:static-content:deploy -f

# Upgrade bazy danych
docker-compose exec php bin/magento setup:upgrade

# Lista wszystkich modułów
docker-compose exec php bin/magento module:status
```

### Praca z bazą danych

```bash
# Połącz się z MySQL
docker-compose exec db mysql -umagento -pmagento123 magento2

# Backup bazy danych
docker-compose exec db mysqldump -umagento -pmagento123 magento2 > backup.sql

# Restore bazy danych
docker-compose exec -T db mysql -umagento -pmagento123 magento2 < backup.sql
```

### Composer

```bash
# Zainstaluj zależności
docker-compose exec php composer install

# Aktualizuj zależności
docker-compose exec php composer update

# Dodaj nowy pakiet
docker-compose exec php composer require vendor/package
```

## 🐛 Troubleshooting

### Problem: Kontenery nie startują

**Rozwiązanie:**
```bash
# Sprawdź logi
docker-compose logs

# Upewnij się, że porty nie są zajęte
lsof -i :80
lsof -i :3306
lsof -i :9200
```

### Problem: Magento pokazuje błąd 500

**Rozwiązanie:**
```bash
# Sprawdź logi PHP
docker-compose logs php

# Sprawdź uprawnienia
docker-compose exec php chmod -R 777 var/ pub/ generated/

# Wyczyść cache
docker-compose exec php bin/magento cache:flush
```

### Problem: Elasticsearch nie działa

**Rozwiązanie:**
```bash
# Sprawdź status Elasticsearch
curl http://localhost:9200/_cluster/health

# Restart Elasticsearch
docker-compose restart elasticsearch

# Zwiększ pamięć dla Elasticsearch (w docker-compose.yml)
ES_JAVA_OPTS: "-Xms1g -Xmx1g"
```

### Problem: Strona ładuje się bardzo wolno

**Rozwiązanie:**
```bash
# Włącz tryb production
docker-compose exec php bin/magento deploy:mode:set production

# Włącz wszystkie cache
docker-compose exec php bin/magento cache:enable

# Zoptymalizuj Composer autoloader
docker-compose exec php composer dump-autoload -o
```

### Problem: Nie można zalogować się do panelu admin

**Rozwiązanie:**
```bash
# Utwórz nowego użytkownika admin
docker-compose exec php bin/magento admin:user:create \
    --admin-user=newadmin \
    --admin-password=NewAdmin123! \
    --admin-email=newadmin@example.com \
    --admin-firstname=New \
    --admin-lastname=Admin

# Wyłącz 2FA (Two-Factor Authentication)
docker-compose exec php bin/magento module:disable Magento_TwoFactorAuth
docker-compose exec php bin/magento cache:flush
```

## 🔐 Bezpieczeństwo

⚠️ **UWAGA**: Ta konfiguracja jest przeznaczona do **rozwoju i testowania lokalnego**.

Przed wdrożeniem na produkcję:

1. Zmień wszystkie hasła w `.env`
2. Włącz HTTPS
3. Skonfiguruj firewall
4. Włącz tryb production: `bin/magento deploy:mode:set production`
5. Włącz 2FA dla panelu admin
6. Ogranicz dostęp do panelu admin przez IP
7. Regularnie aktualizuj Magento i zależności

## 📚 Dodatkowe Zasoby

- [Oficjalna dokumentacja Magento 2](https://devdocs.magento.com/)
- [Magento DevDocs](https://developer.adobe.com/commerce/docs/)
- [Magento Forums](https://community.magento.com/)
- [Stack Overflow - Magento](https://stackoverflow.com/questions/tagged/magento2)

## 🆘 Pomoc

Jeśli napotkasz problemy:

1. Sprawdź logi: `docker-compose logs -f`
2. Sprawdź status kontenerów: `docker-compose ps`
3. Sprawdź dokumentację Magento
4. Sprawdź czy wszystkie kontenery działają poprawnie

## 📝 Licencja

Ten projekt Docker jest udostępniony jako przykład edukacyjny. Magento 2 ma własną licencję Open Source.

---

**Miłego kodowania! 🚀**

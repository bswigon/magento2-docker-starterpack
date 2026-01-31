#!/bin/bash

# Simplified Magento 2 Installation Script
# This script installs Magento 2 with all dependencies

set -e

echo "=========================================="
echo "Magento 2 Installation Script"
echo "=========================================="

# Load environment variables from docker-compose
MYSQL_HOST=${MYSQL_HOST:-db}
MYSQL_DATABASE=${MYSQL_DATABASE:-magento2}
MYSQL_USER=${MYSQL_USER:-magento}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-magento123}
ELASTICSEARCH_HOST=${ELASTICSEARCH_HOST:-elasticsearch}
ELASTICSEARCH_PORT=${ELASTICSEARCH_PORT:-9200}
REDIS_HOST=${REDIS_HOST:-redis}
MAGENTO_BASE_URL=${MAGENTO_BASE_URL:-http://localhost/}
MAGENTO_ADMIN_FIRSTNAME=${MAGENTO_ADMIN_FIRSTNAME:-Admin}
MAGENTO_ADMIN_LASTNAME=${MAGENTO_ADMIN_LASTNAME:-User}
MAGENTO_ADMIN_EMAIL=${MAGENTO_ADMIN_EMAIL:-admin@example.com}
MAGENTO_ADMIN_USER=${MAGENTO_ADMIN_USER:-admin}
MAGENTO_ADMIN_PASSWORD=${MAGENTO_ADMIN_PASSWORD:-Admin123!}
MAGENTO_BACKEND_FRONTNAME=${MAGENTO_BACKEND_FRONTNAME:-admin}
MAGENTO_LANGUAGE=${MAGENTO_LANGUAGE:-en_US}
MAGENTO_CURRENCY=${MAGENTO_CURRENCY:-USD}
MAGENTO_TIMEZONE=${MAGENTO_TIMEZONE:-Europe/Warsaw}

cd /var/www/html

# Check if Magento is already installed
if [ -f "app/etc/env.php" ]; then
    echo "Magento appears to be already installed."
    echo "If you want to reinstall, please remove app/etc/env.php first."
    exit 0
fi

echo "Step 1: Waiting for MySQL to be ready..."
for i in {1..30}; do
    if mysql -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; then
        echo "MySQL is ready!"
        break
    fi
    echo "Waiting for MySQL... ($i/30)"
    sleep 2
done

echo "Step 2: Waiting for Elasticsearch to be ready..."
for i in {1..30}; do
    if curl -s "http://$ELASTICSEARCH_HOST:$ELASTICSEARCH_PORT/_cluster/health" >/dev/null 2>&1; then
        echo "Elasticsearch is ready!"
        break
    fi
    echo "Waiting for Elasticsearch... ($i/30)"
    sleep 2
done

echo "Step 3: Installing Magento 2 via Composer..."
if [ ! -f "composer.json" ]; then
    echo "Creating Magento project (this may take 10-15 minutes)..."
    composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition:2.4.7 /tmp/magento --no-interaction
    
    # Move files to current directory
    shopt -s dotglob
    mv /tmp/magento/* /var/www/html/
    rmdir /tmp/magento
    
    echo "Magento downloaded successfully!"
else
    echo "Composer.json already exists, running composer install..."
    composer install --no-interaction
fi

echo "Step 4: Setting file permissions..."
chmod -R 777 var/ pub/ generated/ app/etc/ 2>/dev/null || true
chmod u+x bin/magento

echo "Step 5: Installing Magento..."
bin/magento setup:install \
    --base-url="$MAGENTO_BASE_URL" \
    --db-host="$MYSQL_HOST" \
    --db-name="$MYSQL_DATABASE" \
    --db-user="$MYSQL_USER" \
    --db-password="$MYSQL_PASSWORD" \
    --admin-firstname="$MAGENTO_ADMIN_FIRSTNAME" \
    --admin-lastname="$MAGENTO_ADMIN_LASTNAME" \
    --admin-email="$MAGENTO_ADMIN_EMAIL" \
    --admin-user="$MAGENTO_ADMIN_USER" \
    --admin-password="$MAGENTO_ADMIN_PASSWORD" \
    --language="$MAGENTO_LANGUAGE" \
    --currency="$MAGENTO_CURRENCY" \
    --timezone="$MAGENTO_TIMEZONE" \
    --use-rewrites=1 \
    --backend-frontname="$MAGENTO_BACKEND_FRONTNAME" \
    --search-engine=elasticsearch7 \
    --elasticsearch-host="$ELASTICSEARCH_HOST" \
    --elasticsearch-port="$ELASTICSEARCH_PORT" \
    --session-save=redis \
    --session-save-redis-host="$REDIS_HOST" \
    --session-save-redis-port=6379 \
    --session-save-redis-db=0 \
    --cache-backend=redis \
    --cache-backend-redis-server="$REDIS_HOST" \
    --cache-backend-redis-port=6379 \
    --cache-backend-redis-db=1 \
    --page-cache=redis \
    --page-cache-redis-server="$REDIS_HOST" \
    --page-cache-redis-port=6379 \
    --page-cache-redis-db=2

echo "Step 6: Post-installation configuration..."
bin/magento config:set web/unsecure/base_url "$MAGENTO_BASE_URL"
bin/magento config:set web/secure/base_url "$MAGENTO_BASE_URL"

# Disable Two-Factor Authentication for easier testing
bin/magento module:disable Magento_AdminAdobeImsTwoFactorAuth Magento_TwoFactorAuth || true

# Set developer mode
bin/magento deploy:mode:set developer

echo "Step 7: Deploying static content..."
bin/magento setup:static-content:deploy -f en_US

echo "Step 8: Reindexing..."
bin/magento indexer:reindex

echo "Step 9: Clearing cache..."
bin/magento cache:flush

echo "Step 10: Final permissions..."
chmod -R 777 var/ pub/ generated/

echo "=========================================="
echo "✅ Magento 2 Installation Complete!"
echo "=========================================="
echo ""
echo "Frontend URL: $MAGENTO_BASE_URL"
echo "Admin URL: ${MAGENTO_BASE_URL}${MAGENTO_BACKEND_FRONTNAME}"
echo "Admin Username: $MAGENTO_ADMIN_USER"
echo "Admin Password: $MAGENTO_ADMIN_PASSWORD"
echo ""
echo "MailHog (Email Testing): http://localhost:8025"
echo "Elasticsearch: http://localhost:9200"
echo "=========================================="

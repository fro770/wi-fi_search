#!/bin/bash

# ADB Backup метод для извлечения WiFi паролей
# Работает на Android 4-9 без root через ПК

echo "ADB WiFi Password Extractor"
echo "============================"

# Проверка ADB
if ! command -v adb &> /dev/null; then
    echo "Ошибка: ADB не найден!"
    echo "Установите Android SDK Platform Tools"
    exit 1
fi

# Проверка подключения устройства
echo "Поиск устройств ADB..."
DEVICES=$(adb devices | grep -v "List" | grep -c "device")

if [ "$DEVICES" -eq 0 ]; then
    echo "Ошибка: Устройство не найдено!"
    echo "1. Включите отладку по USB"
    echo "2. Подтвердите подключение на телефоне"
    exit 1
fi

echo "Устройство найдено"

# Создание backup
BACKUP_FILE="wifi_backup_$(date +%Y%m%d_%H%M%S).ab"
echo "Создание backup: $BACKUP_FILE"
adb backup -f "$BACKUP_FILE" com.android.providers.settings

if [ $? -eq 0 ]; then
    echo "Backup создан успешно"
    
    # Конвертация backup в tar
    echo "Конвертация backup..."
    java -jar abe.jar unpack "$BACKUP_FILE" "wifi_backup.tar"
    
    if [ $? -eq 0 ]; then
        echo "Извлечение данных..."
        tar -xf wifi_backup.tar
        
        # Поиск файлов WiFi
        find . -name "*wifi*" -type f | while read -r file; do
            echo "Найден файл: $file"
            if grep -q "ssid\|psk" "$file" 2>/dev/null; then
                echo "=== Содержимое $file ==="
                grep -E "ssid|psk" "$file"
            fi
        done
    else
        echo "Ошибка конвертации backup"
        echo "Скачайте abe.jar с: https://github.com/nelenkov/android-backup-extractor"
    fi
else
    echo "Ошибка создания backup"
fi

echo "Готово!"

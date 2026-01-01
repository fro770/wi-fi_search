#!/data/data/com.termux/files/usr/bin/bash

# ==============================================
# Android WiFi Password Extractor for Termux
# Требует ROOT права!
# ==============================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Логотип
echo -e "${BLUE}"
echo "=========================================="
echo "   Android WiFi Password Extractor v2.0"
echo "   Для Termux с ROOT правами"
echo "=========================================="
echo -e "${NC}"

# Проверка root прав
check_root() {
    if [[ $(id -u) -ne 0 ]]; then
        echo -e "${RED}[ОШИБКА] Требуются root права!${NC}"
        echo "Запустите: ${YELLOW}su${NC}"
        echo "Или выполните: ${YELLOW}tsu${NC}"
        exit 1
    fi
    echo -e "${GREEN}[✓] Root права подтверждены${NC}"
}

# Проверка версии Android
check_android_version() {
    if [[ -f /system/build.prop ]]; then
        ANDROID_VERSION=$(grep -E 'ro.build.version.release' /system/build.prop | cut -d= -f2)
        echo -e "${BLUE}[i] Версия Android: ${ANDROID_VERSION}${NC}"
        
        # Проверка на Android 10+
        if [[ $(echo "$ANDROID_VERSION >= 10" | bc -l 2>/dev/null) -eq 1 ]]; then
            echo -e "${YELLOW}[!] Android 10+ обнаружен${NC}"
            echo -e "${YELLOW}[!] Могут быть ограничения доступа${NC}"
        fi
    fi
}

# Основная функция извлечения паролей
extract_wifi_passwords() {
    local WIFI_DIR="/data/misc/wifi"
    local CONFIG_FILE="${WIFI_DIR}/wpa_supplicant.conf"
    local BACKUP_FILE="/sdcard/wifi_backup_$(date +%Y%m%d_%H%M%S).txt"
    
    echo -e "${BLUE}[i] Поиск файлов WiFi конфигурации...${NC}"
    
    # Проверка существования файла
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}[ОШИБКА] Файл конфигурации не найден: $CONFIG_FILE${NC}"
        
        # Поиск альтернативных расположений
        echo -e "${YELLOW}[!] Поиск альтернативных расположений...${NC}"
        find /data -name "*wpa*" -type f 2>/dev/null | head -10
        
        exit 1
    fi
    
    # Создание резервной копии
    echo -e "${BLUE}[i] Создание резервной копии...${NC}"
    cp "$CONFIG_FILE" "$BACKUP_FILE" 2>/dev/null || true
    
    # Извлечение сетей
    echo -e "${GREEN}"
    echo "=========================================="
    echo "        НАЙДЕННЫЕ СЕТИ WiFi"
    echo "=========================================="
    echo -e "${NC}"
    
    # Парсинг файла конфигурации
    awk '
    BEGIN {
        print "📶 =================================="
        print "   СЕТИ WIFI И ПАРОЛИ"
        print "=================================="
        ssid = ""
        psk = ""
        count = 0
    }
    /network={/ {
        ssid = ""
        psk = ""
    }
    /ssid="/ {
        split($0, a, "\"")
        ssid = a[2]
    }
    /psk="/ {
        split($0, a, "\"")
        psk = a[2]
    }
    /}/ {
        if (ssid != "" && psk != "") {
            count++
            printf "%-3s 📶 %-30s\n", count, ssid
            printf "    🔑 %-30s\n", psk
            print "   ----------------------------------"
        }
    }
    END {
        if (count == 0) {
            print "❌ Сети не найдены"
        } else {
            printf "✅ Найдено сетей: %d\n", count
        }
    }
    ' "$CONFIG_FILE"
    
    # Экспорт в файл
    echo -e "${BLUE}[i] Экспорт в файл: $BACKUP_FILE${NC}"
    
    # Генерация QR кодов для каждой сети
    generate_qr_codes "$CONFIG_FILE"
}

# Генерация QR кодов для сетей
generate_qr_codes() {
    local config_file="$1"
    local qr_dir="/sdcard/WiFi_QR_Codes"
    
    echo -e "${BLUE}[i] Генерация QR кодов для сетей...${NC}"
    
    mkdir -p "$qr_dir" 2>/dev/null || true
    
    # Извлечение SSID и паролей для QR кодов
    grep -E 'ssid="|psk="' "$config_file" | \
    awk '
    BEGIN { ssid=""; }
    /ssid="/ {
        split($0, a, "\"");
        ssid=a[2];
    }
    /psk="/ {
        if (ssid != "") {
            split($0, a, "\"");
            psk=a[2];
            printf "WIFI:S:%s;T:WPA;P:%s;;\n", ssid, psk;
            ssid="";
        }
    }
    ' | while read -r qr_data; do
        local ssid=$(echo "$qr_data" | cut -d';' -f1 | cut -d':' -f3)
        local safe_ssid=$(echo "$ssid" | tr -cd '[:alnum:]')
        local qr_file="$qr_dir/${safe_ssid}_$(date +%s).txt"
        
        echo "$qr_data" > "$qr_file"
        echo -e "${GREEN}[✓] QR код создан: $(basename "$qr_file")${NC}"
    done
    
    echo -e "${YELLOW}[!] QR коды сохранены в: $qr_dir${NC}"
    echo -e "${YELLOW}[!] Используйте приложение для сканирования QR кодов${NC}"
}

# Дополнительная информация
show_additional_info() {
    echo -e "${BLUE}"
    echo "=========================================="
    echo "        ДОПОЛНИТЕЛЬНАЯ ИНФОРМАЦИЯ"
    echo "=========================================="
    echo -e "${NC}"
    
    # Информация о текущей сети
    echo -e "${YELLOW}[i] Текущая WiFi сеть:${NC}"
    dumpsys wifi | grep -E "mNetworkInfo|SSID" | head -5 2>/dev/null || \
    echo "Информация недоступна"
    
    # Список сохраненных сетей
    echo -e "${YELLOW}[i] Все сохраненные сети:${NC}"
    grep -E 'ssid="' /data/misc/wifi/wpa_supplicant.conf | \
    sed 's/.*ssid="//' | sed 's/".*//' | sort | uniq | nl
}

# Меню
show_menu() {
    echo -e "${BLUE}"
    echo "=========================================="
    echo "              МЕНЮ"
    echo "=========================================="
    echo -e "${NC}"
    
    echo "1. 📋 Показать пароли WiFi"
    echo "2. 📤 Экспортировать в файл"
    echo "3. 📷 Создать QR коды"
    echo "4. 🔍 Информация о сетях"
    echo "5. 🛡️  Проверить безопасность"
    echo "6. 🚪 Выход"
    
    read -p "Выберите опцию (1-6): " choice
    
    case $choice in
        1) extract_wifi_passwords ;;
        2) 
            extract_wifi_passwords
            echo -e "${GREEN}[✓] Данные экспортированы${NC}"
            ;;
        3) generate_qr_codes "/data/misc/wifi/wpa_supplicant.conf" ;;
        4) show_additional_info ;;
        5)
            echo -e "${YELLOW}[!] Проверка безопасности...${NC}"
            check_security
            ;;
        6) exit 0 ;;
        *) echo -e "${RED}[!] Неверный выбор${NC}" ;;
    esac
}

# Проверка безопасности
check_security() {
    echo -e "${YELLOW}[!] Рекомендации по безопасности:${NC}"
    echo "1. Никогда не делитесь паролями WiFi"
    echo "2. Регулярно меняйте пароли"
    echo "3. Используйте WPA3 если возможно"
    echo "4. Отключайте WPS"
    echo "5. Скрывайте SSID если нужно"
}

# Главная функция
main() {
    check_root
    check_android_version
    
    while true; do
        show_menu
        read -p "Продолжить? (y/n): " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] || break
    done
    
    echo -e "${GREEN}[✓] Завершено!${NC}"
}

# Обработка Ctrl+C
trap 'echo -e "\n${RED}[!] Прервано пользователем${NC}"; exit 1' INT

# Запуск
main

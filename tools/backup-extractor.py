#!/usr/bin/env python3
"""
Инструмент для извлечения WiFi паролей из ADB backup
"""

import tarfile
import re
import sys
import os
from pathlib import Path

def extract_wifi_from_backup(backup_file):
    """Извлечение WiFi данных из backup файла"""
    
    if not os.path.exists(backup_file):
        print(f"Файл не найден: {backup_file}")
        return
    
    try:
        with tarfile.open(backup_file, 'r') as tar:
            # Поиск файлов с WiFi данными
            wifi_patterns = ['wifi', 'Wifi', 'WIFI']
            
            for member in tar.getmembers():
                if any(pattern in member.name for pattern in wifi_patterns):
                    print(f"\nНайден файл: {member.name}")
                    
                    # Извлечение файла
                    f = tar.extractfile(member)
                    if f:
                        content = f.read().decode('utf-8', errors='ignore')
                        
                        # Поиск SSID и паролей
                        ssids = re.findall(r'ssid="([^"]+)"', content)
                        psks = re.findall(r'psk="([^"]+)"', content)
                        
                        if ssids and psks:
                            print("Найдены сети WiFi:")
                            for ssid, psk in zip(ssids, psks):
                                print(f"  SSID: {ssid}")
                                print(f"  Пароль: {psk}")
                                print(f"  QR код: WIFI:S:{ssid};T:WPA;P:{psk};;")
                                print("-" * 40)
    
    except Exception as e:
        print(f"Ошибка: {e}")

def main():
    print("ADB Backup WiFi Extractor")
    print("=" * 40)
    
    if len(sys.argv) < 2:
        print("Использование: python backup-extractor.py <backup_file.ab>")
        return
    
    backup_file = sys.argv[1]
    extract_wifi_from_backup(backup_file)

if __name__ == "__main__":
    main()

# VPS Deployment Automation

Автоматизация развертывания настроенного VPS сервера с Wireguard VPN в Docker и другими важными компонентами безопасности.

## Обзор проекта

Этот проект предоставляет полностью автоматизированное решение для настройки VPS сервера с нуля, включая:

- Создание пользователей и настройку SSH-доступа
- Установку и настройку Docker
- Развертывание Wireguard VPN сервера в Docker контейнере 
- Настройку безопасности (SSH hardening, файрвол)
- Мониторинг через Node Exporter

## Структура проекта

```
.
├── Makefile                  # Команды для запуска различных сценариев
├── ansible.cfg               # Конфигурация Ansible
├── inventory/                # Инвентаризация хостов и групповые переменные
│   ├── hosts.yml            # Определение хостов
│   └── group_vars/          # Переменные групп
│       └── vps.yml          # Переменные для группы vps
├── playbooks/               # Ansible плейбуки
│   ├── main.yml             # Основной плейбук, импортирующий все остальные
│   ├── create_users.yml     # Создание пользователей
│   ├── system_update.yml    # Обновление операционной системы
│   ├── prepare_server.yml   # Подготовка сервера, установка компонентов
│   ├── wireguard.yml        # Установка и настройка Wireguard VPN
│   └── post_install.yml     # Пост-установочные задачи
├── requirements.yml         # Список требуемых Ansible ролей
└── roles/                   # Установленные роли
```

## Предварительные требования

1. Ansible 2.9+ 
2. Debian/Ubuntu VPS с доступом по SSH под пользователем root
3. SSH-ключи для беспарольного доступа

## Используемые роли

В проекте используются следующие внешние роли:

- `geerlingguy.docker` - установка и настройка Docker
- `geerlingguy.security` - базовые настройки безопасности SSH
- `geerlingguy.node_exporter` - установка Prometheus Node Exporter для мониторинга
- `geerlingguy.firewall` - настройка файрвола

## Конфигурация

### Настройка инвентаря

1. Отредактируйте файл `inventory/hosts.yml`:
   ```yaml
   vps:
     hosts:
       vdsina:  # Имя сервера можно изменить
         ansible_host: YOUR_SERVER_IP  # IP-адрес вашего сервера
         ansible_user: "{{ deploy_user }}"
         ansible_ssh_private_key_file: ~/.ssh/your_key  # Путь к вашему SSH-ключу
   ```

2. Настройте переменные в `inventory/group_vars/vps.yml`:
   ```yaml
   # Пользователь для развертывания
   deploy_user: "infra"
   
   # Пользователь Wireguard
   wireguard_user: "wg"
   
   # Список клиентов Wireguard
   wireguard_peers:
     - iphone
     - macbook
     - laptop
   
   # Порт Wireguard (UDP)
   wireguard_port: 51820
   
   # Директория для конфигов Wireguard на сервере
   wireguard_config_dir: /opt/wireguard-server
   
   # Локальная директория для сохранения конфигов
   wireguard_local_dir: ./wireguard_configs
   
   # Внутренняя подсеть Wireguard
   wireguard_internal_subnet: 10.13.13.0
   
   # DNS-серверы для клиентов Wireguard
   wireguard_dns:
     - 1.1.1.1
     - 1.0.0.1
   ```

## Использование

### Подготовка к запуску

1. Установите зависимости:
   ```bash
   make install-roles
   ```

### Полное развертывание

Для полной установки и настройки:

```bash
make all
```

Это последовательно выполнит все плейбуки, включая:
1. Установку ролей
2. Запуск всех плейбуков с основными тегами

### Выборочный запуск компонентов

Вы можете запускать отдельные компоненты:

```bash
# Создание пользователей
make users

# Обновление системы
make update

# Подготовка сервера
make prep

# Установка Wireguard VPN
make wireguard

# Пост-установочные задачи
make post_install

# Запуск всех плейбуков
make main
```

### Запуск с определенными тегами

Для запуска только определенных частей с помощью тегов:

```bash
ansible-playbook -i inventory playbooks/main.yml --tags "users,prepare"
```

## Wireguard VPN

### Конфигурация клиентов

После завершения установки, конфигурационные файлы клиентов Wireguard будут:
1. Созданы на сервере в директории `{{ wireguard_config_dir }}/peer_CLIENT/`
2. Скопированы на локальную машину в директорию `{{ wireguard_local_dir }}`

Для каждого клиента будут доступны:
- Конфигурационный файл (`.conf`)
- QR-код (`.png`) для простого подключения мобильных устройств

### Подключение клиентов

1. **Мобильные устройства:**
   - Отсканируйте QR-код из файла `{{ wireguard_local_dir }}/peer_DEVICE.png`

2. **Компьютеры:**
   - Установите клиент Wireguard
   - Импортируйте конфигурационный файл `{{ wireguard_local_dir }}/peer_DEVICE.conf`

## Безопасность

После развертывания:
- SSH доступ настроен для пользователя `deploy_user` с ключевой аутентификацией
- Настроены базовые правила файрвола
- Настроена защита от брутфорс-атак (fail2ban)

## Устранение неполадок

### Проблемы с запуском Wireguard

При запуске контейнера Wireguard может появиться ошибка:
```
Error starting container: failed to set up container networking: driver failed programming external connectivity
```

Это связано с проблемами инициализации iptables, но обычно не мешает работе контейнера.

### Проблемы с подключением клиентов

1. Убедитесь, что UDP порт `{{ wireguard_port }}` открыт на вашем сервере и файрволе
2. Проверьте правильность IP-адреса сервера в конфигурационных файлах
3. Проверьте статус контейнера: `docker ps -f name=wireguard`
4. Посмотрите логи контейнера: `docker logs wireguard`

## Расширение проекта

Вы можете добавить дополнительные компоненты, отредактировав соответствующие плейбуки или создав новые.

## Лицензия

MIT License 
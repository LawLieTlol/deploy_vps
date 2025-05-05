.PHONY: all install-roles prep help wireguard main post_install clean users

ANSIBLE_PLAYBOOK = ansible-playbook
ANSIBLE_GALAXY = ansible-galaxy
ROLES_FILE = requirements.yml
INVENTORY = inventory
PLAYBOOKS_DIR = playbooks
MAIN_PLAYBOOK = $(PLAYBOOKS_DIR)/main.yml
PREP_TAGS = prepare
WIREGUARD_TAGS = wireguard
POST_INSTALL_TAGS = post_install

help:
	@echo "Доступные команды:"
	@echo "  make install-roles  - Установить Ansible роли из Galaxy"
	@echo "  make users          - Создать пользователей (запускается под root)"
	@echo "  make prep           - Запустить преднастройку сервера"
	@echo "  make wireguard      - Установить и настроить Wireguard в Docker"
	@echo "  make post_install   - Выполнить пост-установочные задачи"
	@echo "  make main           - Запустить все плейбуки (весь процесс установки)"
	@echo "  make all            - Установить роли и запустить все плейбуки"
	@echo "  make clean          - Удалить временные файлы"

install-roles:
	@echo "Установка ролей из Galaxy..."
	$(ANSIBLE_GALAXY) install -r $(ROLES_FILE) -p roles/

users:
	@echo "Запуск преднастройки сервера..."
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) $(MAIN_PLAYBOOK) --tags users

update:
	@echo "Запуск преднастройки сервера..."
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) $(MAIN_PLAYBOOK) --tags system_update

prep:
	@echo "Запуск преднастройки сервера..."
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) $(MAIN_PLAYBOOK) --tags prepare

wireguard:
	@echo "Установка и настройка Wireguard в Docker..."
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) $(MAIN_PLAYBOOK) --tags wireguard

post_install:
	@echo "Выполнение пост-установочных задач..."
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) $(MAIN_PLAYBOOK) --tags post_install

main:
	@echo "Запуск всех плейбуков..."
	$(ANSIBLE_PLAYBOOK) -i $(INVENTORY) $(MAIN_PLAYBOOK) --tags all

all: install-roles main

clean:
	@echo "Очистка временных файлов..."
	rm -rf *.retry

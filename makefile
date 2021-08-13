.PHONY: check-cfg print-cfg cfg clean prepare archiso-profile archiso-iwd archiso-ssh archiso-archinstall archiso usb

PACMAN := sudo pacman -Sy --noconfirm

BUILD_DIR := build
BUILD_ARCHISO_DIR := $(BUILD_DIR)/archiso
BUILD_WORK_DIR := $(BUILD_DIR)/work

DIST_DIR := dist
ISO_VERSION := $(shell date +%Y.%m.%d)
ISO_NAME := archlinux-$(ISO_VERSION)-x86_64.iso

SSID := $(ARCH_INSTALL_SSID)
PASSPHRASE := $(ARCH_INSTALL_PASSPHRASE)
SSH_PUBLIC_KEY := $(ARCH_INSTALL_SSH_PUBLIC_KEY)
USB_DEVICE := $(ARCH_INSTALL_USB_DEVICE)

IWD_DIR := $(BUILD_ARCHISO_DIR)/airootfs/var/lib/iwd
IWD_SSID := $(shell echo -n "$(SSID)" | od -A n -t x1 | sed 's/ *//g' | tr -d '\n')
IWD_FILENAME := =$(IWD_SSID).psk
IWD_FILENAME_COMPLETE := $(IWD_DIR)/$(IWD_FILENAME)

SSH_DIR := $(BUILD_ARCHISO_DIR)/airootfs/root/.ssh

ARCHINSTALL_DIR := $(BUILD_ARCHISO_DIR)/airootfs/root/arch-install
ARCHINSTALL_REPO := https://github.com/jacopotessera/arch-install.git

# CONFIGURATION

MAKEFILE_JUSTNAME := $(firstword $(MAKEFILE_LIST))
MAKEFILE_COMPLETE := $(CURDIR)/$(MAKEFILE_JUSTNAME)

CONFIGURATION_JUSTNAME := $(ARCH_INSTALL_CONFIGURATION)
CONFIGURATION_COMPLETE := $(CURDIR)/$(CONFIGURATION_JUSTNAME)

check-cfg:
ifeq ($(CONFIGURATION_JUSTNAME),)
	@echo "Run 'source configure.{fish,sh}'"
	@exit 1
endif	

print-cfg:
	@echo -e 'ARCH INSTALL - ARCHISO CONFIGURATION:'
	@echo -e '\tMAKEFILE: $(MAKEFILE_COMPLETE)'
	@echo -e '\tCONFIGURATION FILE: $(CONFIGURATION_COMPLETE)'
	@echo -e '\tSSID: $(SSID)'
	@echo -e '\tPASSPHRASE: $(PASSPHRASE)'
	@echo -e '\tSSH_PUBLIC_KEY: $(SSH_PUBLIC_KEY)'
	@echo -e '\tUSB_DEVICE: $(USB_DEVICE)'

cfg: check-cfg print-cfg

# END CONFIGURATION

clean:
	sudo rm -rf $(BUILD_DIR)/

prepare: clean
	$(PACMAN) archiso
	mkdir -p $(BUILD_ARCHISO_DIR)
	mkdir -p $(BUILD_WORK_DIR)
	mkdir -p $(DIST_DIR)

archiso-profile:
	cp -r /usr/share/archiso/configs/releng/* $(BUILD_ARCHISO_DIR)
	echo "make" >> $(BUILD_ARCHISO_DIR)/packages.x86_64

archiso-iwd:
	mkdir -p $(IWD_DIR)
	cp src/iwd.psk.template $(IWD_FILENAME_COMPLETE)
	sed -i 's|$${iwd_passphrase}|$(PASSPHRASE)|' $(IWD_FILENAME_COMPLETE)

archiso-ssh:
	mkdir -p $(SSH_DIR)
	cat $(SSH_PUBLIC_KEY) >> $(SSH_DIR)/authorized_keys

archiso-archinstall:
	mkdir -p $(ARCHINSTALL_DIR)
	git clone $(ARCHINSTALL_REPO) $(ARCHINSTALL_DIR)

archiso: cfg prepare archiso-profile archiso-iwd archiso-ssh archiso-archinstall
	sudo mkarchiso -v -w $(BUILD_WORK_DIR) -o $(DIST_DIR) $(BUILD_ARCHISO_DIR)

usb: cfg archiso
	sudo dd bs=4M if=$(DIST_DIR)/$(ISO_NAME) of=/dev/$(USB_DEVICE) conv=fsync oflag=direct status=progress


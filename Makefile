include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-modem-manager
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_MAINTAINER:=Your Name <email@example.com>
PKG_LICENSE:=GPL-2.0-or-later

LUCI_TITLE:=LuCI support for 4G/5G modules (Quectel/Fibocom)
LUCI_DEPENDS:=+luci-mod-network +luci-lib-nixio +luci-lib-jsonc +kmod-usb-core +kmod-usb-serial +kmod-usb-serial-option +kmod-usb-net +kmod-usb-net-cdc-ncm +kmod-usb-net-qmi-wwan +comgt +comgt-ncm +sms-tool +picocom
LUCI_PKGARCH:=all

define Package/$(PKG_NAME)/install
	$(CP) ./root/* $(1)/
	$(INSTALL_DIR) $(1)/www/luci-static/resources/operator
	$(INSTALL_DATA) ./root/www/luci-static/resources/operator/*.png $(1)/www/luci-static/resources/operator/
endef

include $(TOPDIR)/feeds/luci/luci.mk

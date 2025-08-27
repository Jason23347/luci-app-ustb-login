include $(TOPDIR)/rules.mk

LUCI_TITLE:=USTB Web Login
LUCI_DEPENDS:=+lua +luci-compat +luci-base +luci-lib-nixio
PKG_LICENSE:=GPL-3.0
PKG_VERSION:=1.0.0-rc5
PKG_MAINTAINER:=Shuaicheng Zhu <jason23347@gmail.com>

include $(TOPDIR)/feeds/luci/luci.mk

define Package/luci-app-ustb-login
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=$(LUCI_TITLE)
  DEPENDS:=$(LUCI_DEPENDS)
endef

define Package/luci-app-ustb-login/description
  北科大校园网自动登录插件
endef

# no compilation, just install Lua + config
define Build/Compile
endef

define Package/luci-app-ustb-login/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./root/etc/config/ustb_login $(1)/etc/config/ustb_login

	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./luasrc/controller/ustb_login.lua $(1)/usr/lib/lua/luci/controller/
endef

$(eval $(call BuildPackage,luci-app-ustb-login))

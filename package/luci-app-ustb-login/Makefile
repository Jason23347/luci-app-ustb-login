include $(TOPDIR)/rules.mk

LUCI_TITLE:=USTB Web Login
LUCI_DEPENDS:=+lua +luci-compat +luci-base +luci-lib-nixio
LUCI_PKGARCH:=all
PKG_LICENSE:=GPL-3.0
PKG_VERSION:=1.1.0
PKG_RELEASE:=2
PKG_MAINTAINER:=Shuaicheng Zhu <jason23347@gmail.com>

define Package/luci-app-ustb-login/conffiles
/etc/config/ustb_login
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature

PACKAGE_IDENTIFIER = com.pxx917144686.flex
PACKAGE_NAME = FLEX++
PACKAGE_VERSION = 1.0.0
PACKAGE_ARCHITECTURE = arm64
PACKAGE_REVISION = 1
PACKAGE_SECTION = Tweaks
PACKAGE_DEPENDS = firmware (>= 15.0), mobilesubstrate
PACKAGE_DESCRIPTION = FLEX调试工具

define Package/com.pxx917144686.flex
  Package: com.pxx917144686.flex
  Name: FLEX++
  Version: 1.0.0
  Architecture: arm64
  Author: FLEX Team & pxx917144686修改
  Section: Tweaks
  Depends: firmware (>= 15.0), mobilesubstrate
  Description: FLEX调试工具
endef

# SDK 的 libc++ 最低支持 iOS 13，rootless 越狱要求 15+，9.0 会导致模块构建失败
TARGET = iphone:clang:latest:15.0
ARCHS = arm64

# 名称和类型
LIBRARY_NAME = FLEX++

# 动态库类型 - 兼容各种越狱环境
LIBRARY_TYPE = dynamic

# 直接输出到当前目录
export THEOS_PACKAGE_DIR = $(CURDIR)

# Rootless
export THEOS_PACKAGE_SCHEME = rootless
THEOS_PACKAGE_INSTALL_PREFIX = /var/jb

# 设置路径
$(LIBRARY_NAME)_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

# 包含所有源文件（排除FLEX原版和重复文件）
$(LIBRARY_NAME)_FILES = $(shell find . \( -name '*.m' -o -name '*.mm' -o -name '*.c' \) | \
    grep -v "^./FLEX/" | \
    grep -v "x/retdec/" | \
    grep -v "x/retdec-build/" | \
    grep -v "x/Shared/FLEXKeychain.m" | \
    grep -v "x/Shared/FLEXKeychainQuery.m" | \
    grep -v "x/capstone/")

# Capstone核心文件（只包含ARM/ARM64架构）
CAPSTONE_CORE = $(shell find x/capstone -maxdepth 1 -name "*.c")
CAPSTONE_ARCH = $(shell find x/capstone/arch/AArch64 -name "*.c")
$(LIBRARY_NAME)_FILES += $(CAPSTONE_CORE) $(CAPSTONE_ARCH)

# 必要的框架和库
$(LIBRARY_NAME)_FRAMEWORKS = Foundation UIKit CoreGraphics CoreFoundation Security
$(LIBRARY_NAME)_PRIVATE_FRAMEWORKS =

# 系统库（sqlite3：数据库浏览/解密；z：gzip 解压）
$(LIBRARY_NAME)_LIBRARIES = sqlite3 z

# 链接器标志
$(LIBRARY_NAME)_LDFLAGS += -Wl,-no_warn_inits,-search_paths_first,-headerpad_max_install_names
$(LIBRARY_NAME)_CFLAGS = -fobjc-arc -include flex_fishhook.h \
                 -I. \
                 -Wno-unsupported-availability-guard \
                 -Wno-unused-but-set-variable \
                 -Wno-unguarded-availability-new \
                 -Wno-incompatible-pointer-types \
                 -Wno-deprecated-declarations \
                 -Wno-nullability-completeness \
                 -Wno-arc-retain-cycles \
                 -Wno-objc-missing-property-synthesis \
                 -Wno-unused-variable \
                 -Wno-unused-function \
                 -Wno-objc-protocol-method-implementation \
                 -Wno-implicit-function-declaration \
                 -Wno-nonnull \
                 -Wno-format \
                 -Wno-shift-op-parentheses \
                 -DCAPSTONE_HAS_AARCH64 \
                 -DCAPSTONE_USE_SYS_DYN_MEM \
                 -I./x \
                 -I./x/capstone/include

# 编译兼容性
$(LIBRARY_NAME)_CCFLAGS = -std=c++17 -Wno-unused-function -Wno-objc-missing-property-synthesis
$(LIBRARY_NAME)_OBJCFLAGS = -fobjc-arc

# 兼容性

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/library.mk

# library.mk 不会自动打包注入过滤器，手动带上（缺了它 dylib 不会加载进抖音）
# 注意：THEOS_STAGING_DIR 已含 /var/jb 前缀；必须放在 include 之后，否则会成为默认目标导致裸 make 只跑 stage
internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries$(ECHO_END)
	$(ECHO_NOTHING)cp FLEX++.plist $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/$(ECHO_END)

# 编译完成后把 dylib 拷到项目根目录（最终产物）
after-all::
	$(ECHO_NOTHING)cp $(THEOS_OBJ_DIR)/FLEX++.dylib ./FLEX++.dylib$(ECHO_END)

# theos Makefile — 编译为可安装到越狱机的 .app / .ipa
# 需要：theos（Makefile 工程位于有 theos 的机器，或本工程用 iSH 内搭建的 theos）
TARGET := iphone:clang:latest:7.0
ARCHS = arm64
DEBUG = 0

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = QFMonitor

QFMonitor_FILES = main.m QFAppDelegate.m QFMonitorController.m \
                  QFRowView.m QFPanelView.m QFMetrics.m QFPrefs.m
QFMonitor_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore IOKit
# 越狱机直接装进 /Applications（或放宽用 -undefined dynamic_lookup 让 UIKit 类运行时解析）
QFMonitor_INSTALL_PATH = /Applications
QFMonitor_CODESIGN_FLAGS = -S

include $(THEOS_MAKE_PATH)/application.mk
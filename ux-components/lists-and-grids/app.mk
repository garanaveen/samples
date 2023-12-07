##########################################################################
#
# File: app.mk
#
# (c) 2010-2021 Roku, Inc.  All content herein is protected by U.S.
# copyright and other applicable intellectual property laws and may not be
# copied without the express permission of Roku, Inc., which reserves all
# rights.  Reuse of any of this content for any purpose without the
# permission of Roku, Inc. is strictly prohibited.
#
##########################################################################

#########################################################################
#
# app.mk: common include file for application Makefiles.
#
# The client Makefile:
#
# 1) must set APPNAME to an app ID, typically the app name encoded as
#    a unique identifier suitable for a file/directory name
#    (i.e. alphanumeric, no spaces or punctuation).
#
# 2) may set IMPORTS, to a list of .brs base file names to be used from
#    the common utilities.
#
# 3) may set IMPORTS_VERSION to specify which version of the common utilities
#    that IMPORTS should draw from. E.g., 1.0, 2.0, etc. or dev to the
#    top-of-treee.
#    The default value is 1.0.
#
# Important Notes:
#    To use the "run", "install", "remove", etc. targets that work with a
#    target Roku device, you must do the following:
#
# 1) Enable the Development Application Installer on the target Roku device,
#    using the developer secret key sequence (or otherwise access the
#    Developer Settings secret screen).
#
# 2) Make sure that you have the curl command line executable in your path.
#
# 3) Set the variable ROKU_DEV_TARGET in your environment to the IP
#    address of your Roku box, e.g.
#      export ROKU_DEV_TARGET=192.168.1.1
#
# 4) Set the variable DEVPASSWORD in your environment with the developer
#    password that you have set for your Roku box, e.g.
#      export DEVPASSWORD=mypassword
#    (If you don't set this, you will be prompted for every install command.)
#
# Makefile common usage:
#
# 1) make
#   Assembles and checks the current app.
#   Outputs the .zip file to dist/apps/<APP_NAME>.zip
#
#   On desktop platforms that have the BrightScript tool, the *.brs files
#   are compiled on the desktop and checked for BrightScript compilation
#   errors, which is generally much faster and more convenient then
#   side-loading to the device and checking the telnet port for errors.
#   This check can be disabled by setting APP_CHECK_DISABLED=true in the
#   app's Makefile or in the shell environment.
#
#   The app's manifest is also validated for the well-known keys,
#   for example to verify that any package image files referenced by
#   mm_icon_focus etc. exist and are valid.
#   This check can be disabled by setting APP_CHECK_MANIFEST_DISABLED=true
#   in the app's Makefile or in the shell environment.

# *) make check|check-strict|check-info|check-procmem|disasm|desktop-run
#
#   The check target is done by the default make, but can also be
#   called explicitly.
#
#   The check-strict target is like the check target, but enables additional
#   BrightScript compilation checks.
#
#   The check-info target uses the BrightScript tool to print information
#   about the compilation.  Currently it lists all of the function names
#   produced by the compilation.
#
#   The check-procmem uses the BrightScript tool to print the sizes of
#   bytecode, linedata, and other data structures used for the compilation.
#   If the BrightScript tool matches the target firmware, and the BrightScript
#   engine instrumentation hasn't been broken by someone ;-), this should
#   closely match the memory footprint of the compilation data structures on
#   device.
#
#   The disasm target uses the BrightScript tool to print the disassembly
#   of all compiled *.brs sources.
#
#   The desktop-run uses the BrightScript tool to execute the app in the
#   console. This is intended only for core BrightScript engine testing
#   to run Roku-independent apps like bs-regress and bs-test in the desktop
#   environment.
#
# 2) make clean | make clobber
#   Removes the .zip file (if any) for the current app from
#   dist/apps/<APP_NAME>.zip, and removes the .pkg files for the current app
#   (if any) from dist/packages/<APP_NAME>*.pkg.

# 3) make run
#   Makes the current app, removes any current side-loaded app on the
#   target Roku device, then installs the current app (which runs it).
#
# 4) make install
#   Makes the current app, then side-loads it to the target Roku device.
#   If the installed app changes, it runs it, otherwise it is ignored.
#
# 5) make remove
#   Removes the side-loaded app (if any) from the target Roku device.
#   Note: this does not make or use any of the current app's sources or settings.
#
# 6) make installlib
#   Makes the current app, then side-loads it to the target Roku device as
#   a named library.
#
# 7) make removelib
#   Removes the current app from the side-loaded libraries on the target
#   Roku device, if it is installed.
#
# 8) make removeall
#   Removes the side-loaded app (if any) and all side-loaded libraries (if any)
#   from the target Roku device.
#   Note: this does not make or use any of the current app's sources or settings.
#
# 9) make check-roku-dev-target
#   This target is called automatically from 'make run' or any other target
#   that communicates to a target Roku device, but can also be called
#   explicitly.  It just verifies that the $ROKU_DEV_TARGET can be reached
#   via the network and that it responds as a Roku with developer
#   application installer enabled.
#   Note: this does not make or use any of the current app's sources or settings.
#
# === Makefile packaging support ===
#
# 10) make get-target-key
#   This target queries the target Roku device and reports the keyed
#   developer ID, if any.
#   Note: this does not make or use any of the current app's sources or settings.
#
# 11) make rekey-target
#   This target uses the app's configured key file ($APP_KEY_FILE) package
#   to re-key the target Roku device with the corresponding developer ID.
#
#   The signing password corresponding to the developer must be specified
#   via $APP_KEY_PASS otherwise the script will prompt for the password.
#
# 12) make pkg
#   This target will side-load the current app to the target Roku device,
#   then retrieve the signed pkg file back to dist/packages/<APP_NAME>.pkg.
#
#   The signing password corresponding to the developer must be specified
#   via $APP_KEY_PASS otherwise the script will prompt for the password.
#
#   The target Roku device must already be keyed to the specified developer
#   ID.
#
# === TeamCity build and diagnostics support ===
#
# 1) make app-pkg
#
# 2) make inspect-package
#
# 3) make teamcity

# === Makefile less common usage ===
#
# 1) make art-opt
#
# 2) make art-jpg-opt
#
# 3) make art-png-opt
#
# 4) make tr
#
##########################################################################

##########################################################################
#
# Specifying application files to be packaged:
#
# By default, ZIP_EXCLUDE will exclude well-known source directories and
# files that should typically not be included in the application
# distribution.
#
# If you want to entirely override the default settings, you can put your
# own definition of ZIP_EXCLUDE in your Makefile.
#
# Example:
#   ZIP_EXCLUDE= -x keys\*
# will exclude all files from the keys directory (and only those files).
#
# To exclude using more than one pattern, use additional '-x <pattern>'
# arguments, e.g.
#   ZIP_EXCLUDE= -x \*.pkg -x storeassets\*
#
# If you just need to add additional files to the ZIP_EXCLUDE list, you can
# define ZIP_EXCLUDE_LOCAL in your Makefile.  This pattern will be appended
# to the default ZIP_EXCLUDE pattern.
#
# Example:
#   ZIP_EXCLUDE_LOCAL= -x goldens\*
#
##########################################################################

SHELL=/bin/bash

# improve performance and simplify Makefile debugging by omitting
# default language rules that don't apply to this environment.
MAKEFLAGS += --no-builtin-rules
.SUFFIXES:

# we don't want targets to be made in parallel
.NOTPARALLEL:

##########################################################################

IS_TEAMCITY_BUILD ?=
ifneq ($(TEAMCITY_BUILDCONF_NAME),)
IS_TEAMCITY_BUILD := true
endif

HOST_OS_ID := $(shell test -f /etc/os-release && \
	grep '^ID=.*' /etc/os-release | \
	sed 's|ID=||' | sed 's|"||')
UNAME_S := $(shell uname -s)
UNAME_R := $(shell uname -r)

ifeq ($(DEBUG_MAKE), true)
$(info HOST_OS_ID=$(HOST_OS_ID) UNAME_S=$(UNAME_S) UNAME_R=$(UNAME_R))
endif

HOST_OS := unknown

ifeq ($(UNAME_S),Darwin)
	HOST_OS := macos
else ifeq ($(UNAME_S),Linux)
	ifeq ($(HOST_OS_ID),ubuntu)
		HOST_OS := ubuntu
	else
		HOST_OS := linux
	endif
else ifneq ($(findstring CYGWIN,$(UNAME_S)),)
	HOST_OS := cygwin
endif


# Use native file extensions for executables
ifeq ($(HOST_OS),cygwin)
HOST_EXE_SUFFIX := .exe
else
HOST_EXE_SUFFIX :=
endif

# Use native file extensions for executables
ifeq ($(HOST_OS),cygwin)
MAKE_HOST_PATH = $(shell cygpath -m "$1")
else
MAKE_HOST_PATH = $1
endif

# We want to be able to use escape sequences with echo
ifeq ($(HOST_OS),macos)
ECHO := echo
else
ECHO := echo -e
endif

# get the root directory in absolute form, so that current directory
# can be changed during the make if needed.
APPS_ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

# the current directory is the app root directory
SOURCEDIR := .

# the version of the common files
IMPORTS_VERSION ?= 1.0

DISTREL := $(APPS_ROOT_DIR)/dist
COMMONREL := $(APPS_ROOT_DIR)/common/$(IMPORTS_VERSION)

ZIPREL := $(DISTREL)/apps
PKGREL := $(DISTREL)/packages
CHECK_TMP_DIR := $(DISTREL)/tmp-check
ZIP_TMP_DIR := $(DISTREL)/tmp-zip
PKG_TMP_DIR := $(DISTREL)/tmp-pkg

DATE_TIME := $(shell date +%F-%T)

ifeq ($(APPNAME),)
$(error ERROR: APPNAME is not set.)
endif

# The zip may be specially marked, especially when building other pkg types
APP_MARK_ZIP ?=

APP_ZIP_FILE                  := $(ZIPREL)/$(APPNAME)$(APP_MARK_ZIP).zip
APP_CRAMFS_FILE               := $(ZIPREL)/$(APPNAME).cramfs
APP_SQUASHFS_FILE             := $(ZIPREL)/$(APPNAME).squashfs
APP_SQUASHFS_ARM_FILE         := $(ZIPREL)/$(APPNAME).arm.squashfs
APP_SQUASHFS_MIPS_SOFTFP_FILE := $(ZIPREL)/$(APPNAME).mips_soft.squashfs
APP_SQUASHFS_MIPS_HARDFP_FILE := $(ZIPREL)/$(APPNAME).mips_hard.squashfs
APP_PKG_FILE                  := $(PKGREL)/$(APPNAME)_$(DATE_TIME).pkg
APP_ARM_PKG_FILE              := $(PKGREL)/$(APPNAME)_$(DATE_TIME).arm.pkg
APP_MIPS_SOFTFP_PKG_FILE      := $(PKGREL)/$(APPNAME)_$(DATE_TIME).mips_soft.pkg
APP_MIPS_HARDFP_PKG_FILE      := $(PKGREL)/$(APPNAME)_$(DATE_TIME).mips_hard.pkg

# APP_PKG_TYPE may be zip, cram, or squashfs
# (Note: using the label 'cram' instead of 'cramfs' to match NDK app.mk).
APP_PKG_TYPE ?= zip

# APP_PKG_SQUASHFS_<arch> can be set to true when you're using
# APP_PKG_TYPE = squashfs to specify that multiple squashfs files should be
# generated.
APP_PKG_SQUASHFS_ARM ?= false
APP_PKG_SQUASHFS_MIPS_SOFTFP ?= false
APP_PKG_SQUASHFS_MIPS_HARDFP ?= false

# these are used to add parameters to mksquashfs to exclude files for other
# architectures when using APP_PKG_SQUASHFS_<arch>=true. When building without
# a specified architecture, the MKSQUASHFS_NOARCH_ARGS will be applied if set.
MKSQUASHFS_NOARCH_ARGS ?=
MKSQUASHFS_ARM_ARGS ?=
MKSQUASHFS_MIPS_SOFTFP_ARGS ?=
MKSQUASHFS_MIPS_HARDFP_ARGS ?=

# these variables are only used for the .pkg file version tagging.
APP_NAME := $(APPNAME)
APP_VERSION := $(VERSION)

# non-empty if marked as no-source
APP_IS_NO_SOURCE := $(shell test -f manifest && \
	grep '^no_source=1' manifest)

# either empty or semi-colon separated list of BrightScript conditional constants
APP_BS_CONST_DEFS := $(shell test -f manifest && \
	grep '^bs_const=' manifest | sed "s|bs_const=||")

# non-empty if locale directory exists
APP_HAS_LOCALES := $(shell test -d locale && \
	echo true)

# non-empty if locale directory + *.ts files exist
APP_HAS_LOCALES_TS := $(shell test -d locale && \
	test -d locale/en_US && \
	test -f locale/en_US/translations.ts && \
	echo true)

# non-empty if theme
APP_IS_THEME := $(shell test -f manifest && \
	grep '^theme=' manifest)

# non-empty for SG component library; using '?=' in case exotically preset by Makefile
APP_IS_SG_COMPONENT_LIBRARY ?= $(shell test -f manifest && \
	grep '^sg_component_libs_provided=' manifest)

APP_IS_RSG_GLOBAL_NAMESPACE := $(shell test -f manifest && \
	grep '^rsg_global_namespace=1' manifest)

# non-empty for apps using RAF
APP_USES_RAF_LIBRARY := $(shell test -f manifest && \
	grep '^bs_libs_required=roku_ads_lib' manifest)

# for Roku internal use, locate the default Roku_Ads.brs library stub
RAF_LIB_API_DIR := $(APPS_ROOT_DIR)/roku_ads_lib/dev/libapi

ifneq ($(APP_IS_SG_COMPONENT_LIBRARY),)
APP_SG_COMPONENT_SOURCES := $(shell find $(SOURCEDIR)/components -type f -iname '*.brs')
endif

ifneq ($(APP_IS_SG_COMPONENT_LIBRARY),)
	APPSOURCEDIR := $(SOURCEDIR)/components
else ifneq ($(APP_IS_RSG_GLOBAL_NAMESPACE),)
	APPSOURCEDIR := $(SOURCEDIR)
else
	APPSOURCEDIR := $(SOURCEDIR)/source
endif

# check for support for multiple installed dev libraries
# if MULTIPLE_DEVLIBS is not set to false in the application Makefile,
# it will default to true. Setting it to false reverts to 7.5 and
# earlier to single dev library behavior
ifeq ($(MULTIPLE_DEVLIBS), false)
	INSTALL_LIB_COMMAND = "InstallLib"
	REMOVE_LIB_COMMAND = "DeleteLib"
else
	INSTALL_LIB_COMMAND = "InstallLib_$(APPNAME)"
	REMOVE_LIB_COMMAND = "DeleteLib_$(APPNAME)"
endif

IMPORTFILES := $(foreach f,$(sort $(IMPORTS)),$f.brs)

APP_LIBSTUB_DIR := $(SOURCEDIR)/libstub

# ROKU_NATIVE_DEV must be set in the calling environment to
# the firmware native-build src directory
NATIVE_DIST_DIR := $(ROKU_NATIVE_DEV)/dist
#
NATIVE_DEV_REL  := $(NATIVE_DIST_DIR)/rootfs/Linux86_dev.OBJ/root/nvram/incoming
NATIVE_DEV_PKG  := $(NATIVE_DEV_REL)/dev.zip
NATIVE_PLETHORA := $(NATIVE_DIST_DIR)/application/Linux86_dev.OBJ/root/bin/plethora
NATIVE_TICKLER  := $(NATIVE_PLETHORA) tickle-plugin-installer

APPS_SCRIPTS_DIR  := $(APPS_ROOT_DIR)/tools/scripts

# only Linux host is supported for these tools currently
APPS_TOOLS_DIR    := $(APPS_ROOT_DIR)/tools/$(HOST_OS)/bin

APP_PACKAGE_TOOL  ?= $(APPS_TOOLS_DIR)/app-package$(HOST_EXE_SUFFIX)
MAKE_TR_TOOL      ?= $(APPS_TOOLS_DIR)/maketr2$(HOST_EXE_SUFFIX)
BRIGHTSCRIPT_TOOL ?= $(APPS_TOOLS_DIR)/brightscript$(HOST_EXE_SUFFIX)
MKCRAMFS_TOOL     ?= $(APPS_TOOLS_DIR)/mkcramfs_roku$(HOST_EXE_SUFFIX)
MKSQUASHFS_TOOL   ?= $(APPS_TOOLS_DIR)/mksquashfs_roku$(HOST_EXE_SUFFIX)

MKSQUASHFS_ARGS :=
MKSQUASHFS_ARGS += -force-uid 1000 -force-gid 1000 -no-xattrs
ifneq ($(MKSQUASHFS_VERBOSE),true)
ifneq ($(IS_TEAMCITY_BUILD),true)
MKSQUASHFS_ARGS += -quiet -no-progress
endif
endif

CHECK_MANIFEST_TOOL ?= $(APPS_SCRIPTS_DIR)/check-manifest.pl
CHECK_LOCALES_TOOL  ?= $(APPS_SCRIPTS_DIR)/check-locales.pl
CHECK_THEME_TOOL    ?= $(APPS_SCRIPTS_DIR)/check-theme.pl

# deprecated
LRELEASE_TOOL ?= $(APPS_TOOLS_DIR)/lrelease$(HOST_EXE_SUFFIX)
LRELEASE := LC_ALL=C $(LRELEASE_TOOL)

RQM_TOOL ?= $(APPS_TOOLS_DIR)/roku-qm-tool$(HOST_EXE_SUFFIX)

# if building from a firmware tree, use the BrightScript libraries from there
ifneq ($(wildcard $(APPS_ROOT_DIR)/../3rdParty/brightscript/Scripts/LibCore/.),)
BRIGHTSCRIPT_LIBS_DIR ?= $(APPS_ROOT_DIR)/../3rdParty/brightscript/Scripts/LibCore
endif
# else use the reference libraries from the tools directory.
BRIGHTSCRIPT_LIBS_DIR ?= $(APPS_ROOT_DIR)/tools/brightscript/Scripts/LibCore

APP_MK_TMP_DIR := $(shell mkdir -p /tmp/app-mk && echo "/tmp/app-mk")

APP_KEY_PASS_TMP             := $(APP_MK_TMP_DIR)/app_key_pass
DEVICE_INFO_TMP_FILE         := $(APP_MK_TMP_DIR)/device_info_out
DEV_SERVER_TMP_FILE          := $(APP_MK_TMP_DIR)/dev_server_out
SOFTWARE_VERSION_TMP_FILE    := $(APP_MK_TMP_DIR)/sw_version
INSTALL_LIB_COMMAND_TMP_FILE := $(APP_MK_TMP_DIR)/install_lib_command
REMOVE_LIB_COMMAND_TMP_FILE  := $(APP_MK_TMP_DIR)/remove_lib_command

ifeq ($(APP_PKG_TYPE),cram)
ifeq ($(wildcard $(MKCRAMFS_TOOL)),)
# FIXME TO DO: this shouldn't print out all the time, e.g. when doing 'make clobber',
# instead, it should only print when actually creating the package.
$(info  APP_PKG_TYPE=$(APP_PKG_TYPE) not available on this platform. Forcing APP_PKG_TYPE=zip)
override APP_PKG_TYPE=zip
endif
endif

ifeq ($(APP_PKG_TYPE),squashfs)
ifeq ($(wildcard $(MKSQUASHFS_TOOL)),)
# FIXME TO DO: this shouldn't print out all the time, e.g. when doing 'make clobber'
# instead, it should only print when actually creating the package.
$(info  APP_PKG_TYPE=$(APP_PKG_TYPE) not available on this platform. Forcing APP_PKG_TYPE=zip)
override APP_PKG_TYPE=zip
endif
endif

ifeq ($(APP_PKG_TYPE),zip)
	APP_FILE=$(APP_ZIP_FILE)
else ifeq ($(APP_PKG_TYPE),cram)
	APP_FILE=$(APP_CRAMFS_FILE)
else ifeq ($(APP_PKG_TYPE),squashfs)
ifeq ($(APP_ARCH),)
	APP_FILE=$(APP_SQUASHFS_FILE)
else
	APP_FILE=$(ZIPREL)/$(APPNAME).$(APP_ARCH).squashfs
endif
else
$(error ERROR: APP_PKG_TYPE=$(APP_PKG_TYPE) is invalid. Valid values are: "zip", "cram", or "squashfs")
endif

# The developer password that was set on the player is required for
# plugin_install operations on modern versions of firmware.
# It may be pre-specified in the DEVPASSWORD environment variable on entry,
# otherwise the make will stop and prompt the user to enter it when needed.
ifdef DEVPASSWORD
	USERPASS := rokudev:$(DEVPASSWORD)
else
	USERPASS := rokudev
endif

ifeq ($(HOST_OS),macos)
	# -p = Cause cp to preserve attributes of each source file in the copy
	# -X = Do not copy Extended Attributes (EAs) or resource forks
	# -R = --recursive
	CP_FILE_ARGS = -p -X
	CP_DIR_ARGS = -R -p -X

	SED_IN_PLACE_ARGS = -i ''
else
	# -R = --recursive
	# -l = --link
	# FIXME TO DO: document why the --no-preserve=mode is needed?
	CP_FILE_ARGS = --preserve=ownership,timestamps --no-preserve=mode
	# -l option causes original file losing readonly property in WSL.
	ifneq ($(findstring Microsoft,$(UNAME_R)), )
		CP_DIR_ARGS = -R --preserve=ownership,timestamps
	else
		CP_DIR_ARGS = -R -l --preserve=ownership,timestamps --no-preserve=mode
	endif

	SED_IN_PLACE_ARGS = -i''
endif

# For a quick ping, we want the command to return success as soon as possible,
# and a timeout failure in no more than a second or two.
ifeq ($(HOST_OS),cygwin)
	# This assumes that the Windows ping command is used, not cygwin's.
	QUICK_PING_ARGS = -n 1 -w 1000
else ifeq ($(HOST_OS),macos)
	QUICK_PING_ARGS = -c 1 -t 1
else # Linux
	QUICK_PING_ARGS = -c 1 -w 1
endif

ifndef ZIP_EXCLUDE
	ZIP_EXCLUDE =
	# exclude hidden files (name starting with .)
	ZIP_EXCLUDE += -x .\*
	ZIP_EXCLUDE += -x \*/.\*
	# exclude shell scripts (typically top-level build helpers)
	ZIP_EXCLUDE += -x \*.sh
	# exclude files with name ending with ~
	ZIP_EXCLUDE += -x \*~
	ZIP_EXCLUDE += -x \*.mod
	ZIP_EXCLUDE += -x Makefile
	ZIP_EXCLUDE += -x keys/\*
	ZIP_EXCLUDE += -x libapi/\*
	ZIP_EXCLUDE += -x libstub/\*
	ZIP_EXCLUDE += -x storeassets/\*
	# exclude Mac OS X desktop metadata
	ZIP_EXCLUDE += -x \*__MACOSX\*
	ZIP_EXCLUDE += -x \*.DS_Store
	# exclude pkg/zip, unless asked to keep
	ifndef ZIP_INCLUDE_PKG_AND_ZIP
		ZIP_EXCLUDE += -x \*.pkg
		ZIP_EXCLUDE += -x \*.zip
	endif
endif

ZIP_EXCLUDE_PATTERN = $(ZIP_EXCLUDE)
ZIP_EXCLUDE_PATTERN += $(ZIP_EXCLUDE_LOCAL)

ZIP_ARGS :=

#ifneq ($(APP_VERBOSE_ARCHIVE),true)
#	ZIP_ARGS += -q
#endif

ifeq ($(APP_QUIET_ARCHIVE),true)
	ZIP_ARGS += -q
endif

# -------------------------------------------------------------------------
# Colorized output support.
# If you don't want it, do 'export APP_MK_COLOR=false' in your env.
# -------------------------------------------------------------------------
ifndef APP_MK_COLOR
APP_MK_COLOR := false
ifeq ($(TERM),$(filter $(TERM),xterm xterm-color xterm-256color))
	APP_MK_COLOR := true
endif
endif

COLOR_START  :=
COLOR_INFO   :=
COLOR_PROMPT :=
COLOR_DONE   :=
COLOR_ERR    :=
COLOR_OFF    :=

ifeq ($(APP_MK_COLOR),true)
	# ANSI color escape codes:

	#	\e[0;30m	black
	#	\e[0;31m	red
	#	\e[0;32m	green
	#	\e[0;33m	yellow
	#	\e[0;34m	blue
	#	\e[0;35m	magenta
	#	\e[0;36m	cyan
	#	\e[0;37m	light gray

	#	\e[1;30m	gray
	#	\e[1;31m	light red
	#	\e[1;32m	light green
	#	\e[1;33m	light yellow
	#	\e[1;34m	light blue
	#	\e[1;35m	light purple
	#	\e[1;36m	light cyan
	#	\e[1;37m	white

	COLOR_START  := \033[1;36m
	COLOR_INFO   := \033[1;35m
	COLOR_PROMPT := \033[0;31m
	COLOR_DONE   := \033[1;32m
	COLOR_ERROR  := \033[1;31m
	COLOR_OFF    := \033[0m
endif

APP_COMMON_COPY_QUIET ?=

# -------------------------------------------------------------------------
# $(APPNAME): the default target is to create the zip file for the app.
# This contains the set of files that are to be deployed on a Roku.
# -------------------------------------------------------------------------
.PHONY: $(APPNAME)
$(APPNAME):: manifest \
	app-build-start \
	app-build-remove-old-products \
	generate-app-files \
	app-build-copy-imports \
	app-build-create-zip-staging \
	app-build-clean-imports \
	app-build-update-manifest \
	app-build-create-zip-product \
	app-build-delete-zip-staging \
	app-build-create-more-products \
	app-build-complete
#
# Note: to start, continue copying the imports into the actual source directory
# as a first step, and call the generate-app-files target which the project
# may override to generate additional files into the source directory.
# Then as the second step, copy the source directory to a staging directory
# for further modifications (such as automatically modifying the manifest).
# In the future, it would be nice to change this so that the imports are
# only copied into the staging directory, and don't modify the source directory,
# and likewise make it so that the generate-app-files overrides would only
# work on the staging directory.

# -------------------------------------------------------------------------
# app-build-start
# -------------------------------------------------------------------------
.PHONY: app-build-start
app-build-start:
	@$(ECHO) "$(COLOR_START)**** Building $(APPNAME) ****$(COLOR_OFF)"

# -------------------------------------------------------------------------
# app-build-remove-old-products
# -------------------------------------------------------------------------
.PHONY: app-build-remove-old-products
app-build-remove-old-products:
	@$(ECHO) "  >> removing old application files $(APP_NAME).*"
	@( \
		rm -f $(APP_ZIP_FILE); \
		rm -f $(APP_CRAMFS_FILE); \
		rm -f $(APP_SQUASHFS_FILE); \
		rm -f $(APP_SQUASHFS_ARM_FILE); \
		rm -f $(APP_SQUASHFS_MIPS_SOFTFP_FILE); \
		rm -f $(APP_SQUASHFS_MIPS_HARDFP_FILE); \
	)

# -------------------------------------------------------------------------
# app-build-create-zip-staging
# -------------------------------------------------------------------------
.PHONY: app-build-create-zip-staging
app-build-create-zip-staging:
	@$(ECHO) "  >> copying app sources to staging directory"

	@if [ ! -d $(SOURCEDIR) ]; then \
		$(ECHO) "$(COLOR_ERROR)Source for $(APPNAME) not found at $(SOURCEDIR)$(COLOR_OFF)"; \
		exit 1; \
	fi

	@( \
		rm -rf $(ZIP_TMP_DIR); \
		mkdir -p $(ZIP_TMP_DIR); \
		cp $(CP_DIR_ARGS) $(SOURCEDIR) $(ZIP_TMP_DIR)/; \
	)

#	echo "#############################"
#	ls -al $(ZIP_TMP_DIR)
#	echo "#############################"

# -------------------------------------------------------------------------
# app-build-copy-imports
# -------------------------------------------------------------------------
.PHONY: app-build-copy-imports
app-build-copy-imports:
# FIXME TO DO: only copy to staging directory, not to source directory
# in which case this will move to *after* the source dir copy
	@if [ "$(IMPORTFILES)" ]; then \
		$(ECHO) "  >> copying imports"; \
		rm -rf $(APPSOURCEDIR)/common; \
		mkdir -p $(APPSOURCEDIR)/common; \
		for IMPORTFILE in $(IMPORTFILES); do \
			( \
				if [ "$(APP_COMMON_COPY_QUIET)" != "true" ]; then \
					$(ECHO) "  copying: common/$$IMPORTFILE"; \
				fi; \
				cp $(CP_FILE_ARGS) $(COMMONREL)/$$IMPORTFILE $(APPSOURCEDIR)/common/ || \
					( \
						$(ECHO) "$(COLOR_ERROR)ERROR: Copying $$IMPORTFILE failed.$(COLOR_OFF)"; \
						exit 1 \
					); \
			) || exit 1; \
		done; \
	fi

# -------------------------------------------------------------------------
# app-build-clean-imports
# -------------------------------------------------------------------------
.PHONY: app-build-clean-imports
app-build-clean-imports:
# FIXME TO DO: if only copying to staging directory, no need for this clean-up
	@if [ "$(IMPORTFILES)" ]; then \
		$(ECHO) "  >> deleting imports"; \
		rm -rf $(APPSOURCEDIR)/common; \
	fi

# -------------------------------------------------------------------------
# support for getting the build version number from the TeamCity build
# (for the major.minor.build version that is stored in the manifest).
# local side-loaded build will default to build_version=99999
# -------------------------------------------------------------------------
APP_BUILD_VERSION ?= 99999
ifeq ($(IS_TEAMCITY_BUILD),true)
APP_BUILD_VERSION := $(BUILD_NUMBER)
endif

# -------------------------------------------------------------------------
# Support for getting the build VCS number from the TeamCity build.
# It may be helpful for source tracking if Roku channels choose to include
# this in their manifest file.
# The local side-loaded build will default to default (0).
# -------------------------------------------------------------------------
APP_BUILD_VCS_NUMBER ?= 0
ifeq ($(IS_TEAMCITY_BUILD),true)
APP_BUILD_VCS_NUMBER := $(BUILD_VCS_NUMBER)
endif

# -------------------------------------------------------------------------
# generate-manifest:
# -------------------------------------------------------------------------
.PHONY: app-build-update-manifest
app-build-update-manifest:
	@if grep -q '$${' manifest; then \
		$(ECHO) "  >> updating manifest"; \
		chmod a+w $(ZIP_TMP_DIR)/manifest; \
		sed $(SED_IN_PLACE_ARGS) \
			's|$${APP_BUILD_VERSION}|$(APP_BUILD_VERSION)|' \
			$(ZIP_TMP_DIR)/manifest; \
		sed $(SED_IN_PLACE_ARGS) \
			's|$${APP_BUILD_VCS_NUMBER}|$(APP_BUILD_VCS_NUMBER)|' \
			$(ZIP_TMP_DIR)/manifest; \
	fi

#	@echo "######"; \
#	cat $(ZIP_TMP_DIR)/manifest | grep version; \
#	echo "######"

# -------------------------------------------------------------------------
# app-build-create-zip-product
# -------------------------------------------------------------------------
.PHONY: app-build-create-zip-product
app-build-create-zip-product:
	@$(ECHO) "  >> creating destination directory $(ZIPREL)"
	@if [ ! -d $(ZIPREL) ]; then \
		mkdir -p $(ZIPREL); \
	fi

# FIXME: why is this needed?  when would it ever not be writable,
# if it was created by the mkdir above?
#	@$(ECHO) "  >> setting directory permissions for $(ZIPREL)"
	@if [ ! -w $(ZIPREL) ]; then \
		chmod 755 $(ZIPREL); \
	fi

	@$(ECHO) "  >> creating application zip $(APP_ZIP_FILE)"
	@rm -f $(APP_ZIP_FILE)

# FIXME TO DO: use "find | sort" so that zip file is created in canonical
# format, rather than being dependent on the directory enumeration order

# First, add any .png files, without compression, by using -0.
# FIXME: shouldn't it exclude .jpg too?
# FIXME: if no .png files are found, outputs bogus "zip warning: zip file empty"
# Also, this command has to be first... if we put it *after* the other files,
# zip gives "zip error: Nothing to do!" and errors out :-(
	@cd $(ZIP_TMP_DIR) && \
	zip $(ZIP_ARGS) -0 -r $(APP_ZIP_FILE) . -i \*.png $(ZIP_EXCLUDE_PATTERN)

# Next, add everything but .png files with full compression, by using -9.
	@cd $(ZIP_TMP_DIR) && \
	zip $(ZIP_ARGS) -9 -r $(APP_ZIP_FILE) . -x \*.png $(ZIP_EXCLUDE_PATTERN)

# -------------------------------------------------------------------------
# app-build-delete-zip-staging
# -------------------------------------------------------------------------
.PHONY: app-build-delete-zip-staging
app-build-delete-zip-staging:
#	@$(ECHO) "  >> deleting staging directory"

	@rm -rf $(ZIP_TMP_DIR)

# -------------------------------------------------------------------------
# app-build-create-more-products
# -------------------------------------------------------------------------
.PHONY: app-build-create-more-products
app-build-create-more-products:
ifeq ($(APP_PKG_TYPE),cram)

	@$(ECHO) "  >> creating application cramfs $(APP_CRAMFS_FILE)"

	@rm -rf $(PKG_TMP_DIR); \
	mkdir -p $(PKG_TMP_DIR); \
	unzip -q $(APP_ZIP_FILE) -d $(PKG_TMP_DIR)

	@$(MKCRAMFS_TOOL) $(PKG_TMP_DIR) $(APP_CRAMFS_FILE)

	@rm -rf $(PKG_TMP_DIR)

else ifeq ($(APP_PKG_TYPE),squashfs)

	@$(ECHO) "  >> creating application squashfs $(APP_SQUASHFS_FILE)"

	@rm -rf $(PKG_TMP_DIR); \
	mkdir -p $(PKG_TMP_DIR); \
	unzip -q $(APP_ZIP_FILE) -d $(PKG_TMP_DIR)

	@# Remove write permissions for g(group) and o(other) from all files.
	@# The fs is not writable anyway and the firmware(grsec) will not execute
	@# files if any file or directory in the path is writable by g or o.
	@chmod -R g-w,o-w $(PKG_TMP_DIR)

	@$(MKSQUASHFS_TOOL) $(PKG_TMP_DIR) $(APP_SQUASHFS_FILE) \
		$(MKSQUASHFS_ARGS) \
		$(MKSQUASHFS_NOARCH_ARGS)

ifeq ($(APP_PKG_SQUASHFS_ARM),true)
	@$(ECHO) "  >> creating application ARM squashfs $(APP_SQUASHFS_ARM_FILE)"
	@$(MKSQUASHFS_TOOL) $(PKG_TMP_DIR) $(APP_SQUASHFS_ARM_FILE) \
		$(MKSQUASHFS_ARGS) \
		$(MKSQUASHFS_ARM_ARGS)
endif

ifeq ($(APP_PKG_SQUASHFS_MIPS_SOFTFP),true)
	@$(ECHO) "  >> creating application MIPS squashfs $(APP_SQUASHFS_MIPS_SOFTFP_FILE)"
	@$(MKSQUASHFS_TOOL) $(PKG_TMP_DIR) $(APP_SQUASHFS_MIPS_SOFTFP_FILE) \
		$(MKSQUASHFS_ARGS) \
		$(MKSQUASHFS_MIPS_SOFTFP_ARGS)
endif

ifeq ($(APP_PKG_SQUASHFS_MIPS_HARDFP),true)
	@$(ECHO) "  >> creating application MIPS squashfs $(APP_SQUASHFS_MIPS_HARDFP_FILE)"
	@$(MKSQUASHFS_TOOL) $(PKG_TMP_DIR) $(APP_SQUASHFS_MIPS_HARDFP_FILE) \
		$(MKSQUASHFS_ARGS) \
		$(MKSQUASHFS_MIPS_HARDFP_ARGS)
endif

	@rm -rf $(PKG_TMP_DIR)

endif

# -------------------------------------------------------------------------
# app-build-complete
# -------------------------------------------------------------------------
.PHONY: app-build-complete
app-build-complete:
	@$(ECHO) "$(COLOR_DONE)**** Building $(APPNAME) complete ****$(COLOR_OFF)"

# -------------------------------------------------------------------------
# clean: remove any build output for the app.
# -------------------------------------------------------------------------
.PHONY: clean
clean: clean-generated-app-files app-build-remove-old-products
	@$(ECHO) "$(COLOR_START)**** Cleaning $(APPNAME) ****$(COLOR_OFF)"
# FIXME: we should use a canonical output file name, rather than having
# the date-time stamp in the output file name.
#	rm -f $(APP_PKG_FILE)
	rm -f $(PKGREL)/$(APPNAME)_*.pkg

# -------------------------------------------------------------------------
# clobber: remove any build output for the app.
# -------------------------------------------------------------------------
.PHONY: clobber
clobber: clean

# -------------------------------------------------------------------------
# dist-clean: remove the dist directory for the sandbox.
# -------------------------------------------------------------------------
.PHONY: dist-clean
dist-clean:
	rm -rf $(DISTREL)/*

# -------------------------------------------------------------------------
# generate-app-files: create any generated files
# -------------------------------------------------------------------------
.PHONY: generate-app-files
generate-app-files:
# default rule does nothing, can be overridden by app-specific logic
#	@$(ECHO) "generate-app-files default"

# -------------------------------------------------------------------------
# clean-generated-app-files: remove any generated files
# -------------------------------------------------------------------------
.PHONY: clean-generated-app-files
clean-generated-app-files:
# default rule does nothing, can be overridden by app-specific logic
#	@$(ECHO) "clean-generated-app-files default"

# -------------------------------------------------------------------------
# CHECK_OPTIONS: this is used to specify configurable options, such
# as which version of the BrightScript library sources should be used
# to compile the app.
# -------------------------------------------------------------------------
CHECK_OPTIONS =

# FIXME: need to scan the whole package for now.
ifneq ($(APP_IS_RSG_GLOBAL_NAMESPACE),)
# Comment out for now, until the brightscript checked-in binary is updated.
	CHECK_OPTIONS += -all-source
endif

# add the conditional constant definitions, if set
ifneq ($(APP_BS_CONST_DEFS),)
	CHECK_OPTIONS += -bsconst "$(APP_BS_CONST_DEFS)"
endif

# add the path to the common/LibCore sources, if available
ifneq ($(wildcard $(BRIGHTSCRIPT_LIBS_DIR)/.),)
	CHECK_OPTIONS += -platlib $(call MAKE_HOST_PATH,$(BRIGHTSCRIPT_LIBS_DIR))
endif

# if the app uses BS libraries, it can provide stub libraries to compile with.
ifneq ($(wildcard $(APP_LIBSTUB_DIR)/.),)
	CHECK_OPTIONS += -bslib libstub=$(call MAKE_HOST_PATH,$(realpath $(APP_LIBSTUB_DIR)))
else ifneq ($(APP_USES_RAF_LIBRARY),)
	ifneq ($(wildcard $(RAF_LIB_API_DIR)/.),)
		CHECK_OPTIONS += -bslib roku_ads_lib=$(call MAKE_HOST_PATH,$(RAF_LIB_API_DIR))
	endif
endif

ifneq ($(APP_IS_LIBRARY),)
	# if the app is a BS library, let it find auxiliary internal sources
	CHECK_OPTIONS += -bslib libself=$(call MAKE_HOST_PATH,$(CHECK_TMP_DIR)/libsource)
endif

ifneq ($(APP_IS_LIBRARY),)
	# if the app is a BS library, we only compile the specific .brs file
	CHECK_OPTIONS += $(call MAKE_HOST_PATH,$(CHECK_TMP_DIR)/libsource/$(APP_IS_LIBRARY))
else ifneq ($(APP_IS_SG_COMPONENT_LIBRARY),)
	# if the app is a SG component library, this is a TBD
	# for now, just do a minimal compile check of each .brs file separately
	# which is handled in the check target specially.
else
	# else implicitly check all the .brs files in the source directory
	CHECK_OPTIONS += $(call MAKE_HOST_PATH,$(CHECK_TMP_DIR))
endif

# -------------------------------------------------------------------------
# CHECK_TMP_BEGIN is used to create a temporary directory containing
# a copy of the app archive contents.
# -------------------------------------------------------------------------
define CHECK_TMP_BEGIN
	rm -rf $(CHECK_TMP_DIR)
	mkdir -p $(CHECK_TMP_DIR)
	unzip -q $(APP_ZIP_FILE) -d $(CHECK_TMP_DIR)
endef

# -------------------------------------------------------------------------
# CHECK_TMP_END is used to remove the temporary directory created by
# CHECK_TMP_BEGIN.
# -------------------------------------------------------------------------
define CHECK_TMP_END
	rm -rf $(CHECK_TMP_DIR)
endef

# -------------------------------------------------------------------------
# CHECK_MANIFEST_OPTIONS
# -------------------------------------------------------------------------
CHECK_MANIFEST_OPTIONS :=

# -------------------------------------------------------------------------
# check-manifest: run the check tool on the application manifest and
# any referenced asset files.
# -------------------------------------------------------------------------
.PHONY: check-manifest
check-manifest: $(APPNAME)
ifeq ($(APP_CHECK_MANIFEST_DISABLED),true)
ifeq ($(IS_TEAMCITY_BUILD),true)
	@$(ECHO) "**** Warning: manifest check skipped ****"
endif
else
ifeq ($(wildcard $(CHECK_MANIFEST_TOOL)),)
	@$(ECHO) "**** Note: manifest check not available ****"
else
	@$(ECHO) "$(COLOR_START)**** Checking manifest ****$(COLOR_OFF)"
	@$(CHECK_TMP_BEGIN)
ifeq ($(APP_CHECK_MANIFEST_NOERROR),true)
	-@cd $(CHECK_TMP_DIR) && \
	$(CHECK_MANIFEST_TOOL) $(CHECK_MANIFEST_OPTIONS)
else
	@cd $(CHECK_TMP_DIR) && \
	$(CHECK_MANIFEST_TOOL) $(CHECK_MANIFEST_OPTIONS)
endif
	@$(CHECK_TMP_END)
	@$(ECHO) "$(COLOR_DONE)**** Checking complete ****$(COLOR_OFF)"
endif
endif

# -------------------------------------------------------------------------
# check-locales: run the check tool on the application locales and
# any referenced asset files.
#
# By default, this only checks that files are well-formed and prints
# out the summmary information.
# -------------------------------------------------------------------------
CHECK_LOCALES_OPTIONS ?= -brief -no-checks

.PHONY: check-locales
check-locales:
# Note: going forward we're only supporting .ts files, not .xliff files,
# for Roku-developed channels.
ifneq ($(APP_HAS_LOCALES_TS),)
ifeq ($(APP_CHECK_LOCALES_DISABLED),true)
ifeq ($(IS_TEAMCITY_BUILD),true)
	@$(ECHO) "**** Warning: locales check skipped ****"
endif
else
ifeq ($(wildcard $(CHECK_LOCALES_TOOL)),)
	@$(ECHO) "**** Note: locales check not available ****"
else
	@$(ECHO) "$(COLOR_START)**** Checking locales ****$(COLOR_OFF)"
ifeq ($(APP_CHECK_LOCALES_NOERROR),true)
	-@$(CHECK_LOCALES_TOOL) $(CHECK_LOCALES_OPTIONS)
else
	@$(CHECK_LOCALES_TOOL) $(CHECK_LOCALES_OPTIONS)
endif
	@$(ECHO) "$(COLOR_DONE)**** Checking complete ****$(COLOR_OFF)"
endif
endif
endif

# -------------------------------------------------------------------------
# check: run the desktop BrightScript compiler/check tool on the
# application.
# You can bypass checking on the application by setting
# APP_CHECK_DISABLED=true in the app's Makefile or in the environment.
# -------------------------------------------------------------------------
.PHONY: check
check: $(APPNAME) check-manifest check-locales
#=======================================================
ifeq ($(APP_CHECK_DISABLED),true)
#=======================================================
ifeq ($(IS_TEAMCITY_BUILD),true)
	@$(ECHO) "**** Warning: application check skipped ****"
endif
#=======================================================
else
#=======================================================
ifeq ($(wildcard $(BRIGHTSCRIPT_TOOL)),)
	@$(ECHO) "**** Note: application check not available ****"
else
#-------------------------------------------------------
	@$(ECHO) "$(COLOR_START)**** Checking application ****$(COLOR_OFF)"
	@$(CHECK_TMP_BEGIN)
#-------------------------------------
ifneq ($(APP_IS_SG_COMPONENT_LIBRARY),)
	@if [ "$(APP_SG_COMPONENT_SOURCES)" ]; then \
		for BRS_FILE in $(APP_SG_COMPONENT_SOURCES); do \
			$(ECHO) "$(COLOR_START)**** Checking source $$BRS_FILE ****$(COLOR_OFF)"; \
			set -e; \
			$(BRIGHTSCRIPT_TOOL) check $$BRS_FILE $(CHECK_OPTIONS); \
		done; \
	fi
else ifneq ($(APP_IS_NO_SOURCE),)
else
	@$(BRIGHTSCRIPT_TOOL) check $(CHECK_OPTIONS)
endif
#-------------------------------------
	@$(CHECK_TMP_END)
	@$(ECHO) "$(COLOR_DONE)**** Checking complete ****$(COLOR_OFF)"
#-------------------------------------------------------
endif
#=======================================================
endif
#=======================================================

# -------------------------------------------------------------------------
# check-strict: run the desktop BrightScript compiler/check tool on the
# application using strict mode.
# -------------------------------------------------------------------------
.PHONY: check-strict
check-strict: $(APPNAME)
#-------------------------------------------------------
	@$(ECHO) "$(COLOR_START)**** Checking application (strict) ****$(COLOR_OFF)"
	@$(CHECK_TMP_BEGIN)
#-------------------------------------------------------
ifneq ($(APP_IS_SG_COMPONENT_LIBRARY),)
	@if [ "$(APP_SG_COMPONENT_SOURCES)" ]; then \
		for BRS_FILE in $(APP_SG_COMPONENT_SOURCES); do \
			$(ECHO) "$(COLOR_START)**** Checking source $$BRS_FILE ****$(COLOR_OFF)"; \
			set -e; \
			$(BRIGHTSCRIPT_TOOL) check -strict $$BRS_FILE $(CHECK_OPTIONS); \
		done; \
	fi
else ifneq ($(APP_IS_NO_SOURCE),)
else
	@$(BRIGHTSCRIPT_TOOL) check -strict $(CHECK_OPTIONS)
endif
#-------------------------------------------------------
	@$(CHECK_TMP_END)
	@$(ECHO) "$(COLOR_DONE)**** Checking complete ****$(COLOR_OFF)"
#-------------------------------------------------------

# -------------------------------------------------------------------------
# check-info: run the desktop BrightScript compiler/check tool on the
# application to print out some summary info (currently just function listing).
# -------------------------------------------------------------------------
.PHONY: check-info
check-info: $(APPNAME)
	@$(ECHO) "$(COLOR_START)**** Dumping application info ****$(COLOR_OFF)"
	@$(CHECK_TMP_BEGIN)
	@$(BRIGHTSCRIPT_TOOL) info $(CHECK_OPTIONS)
	@$(CHECK_TMP_END)
	@$(ECHO) "$(COLOR_DONE)**** Checking complete ****$(COLOR_OFF)"

# -------------------------------------------------------------------------
# check-procmem: run the desktop BrightScript compiler/check tool on the
# application to print out some summary info.
# -------------------------------------------------------------------------
.PHONY: check-procmem
check-procmem: $(APPNAME)
	@$(ECHO) "$(COLOR_START)**** Dumping application info ****$(COLOR_OFF)"
	@$(CHECK_TMP_BEGIN)
	@$(BRIGHTSCRIPT_TOOL) procmem $(CHECK_OPTIONS)
	@$(CHECK_TMP_END)
	@$(ECHO) "$(COLOR_DONE)**** Checking complete ****$(COLOR_OFF)"

# -------------------------------------------------------------------------
# disasm: run the desktop BrightScript compiler/check tool on the
# application to print out some summary info (currently just function listing).
# -------------------------------------------------------------------------
.PHONY: disasm
disasm: $(APPNAME)
	@$(ECHO) "$(COLOR_START)**** Dumping application disassembly ****$(COLOR_OFF)"
	@$(CHECK_TMP_BEGIN)
	@$(BRIGHTSCRIPT_TOOL) disasm $(CHECK_OPTIONS)
	@$(CHECK_TMP_END)
	@$(ECHO) "$(COLOR_DONE)**** Dump complete ****$(COLOR_OFF)"

# -------------------------------------------------------------------------
# desktop-run: run using the desktop BrightScript tool.  This only
# works for test apps using intrinsic BrightScript function + components,
# of course.
# -------------------------------------------------------------------------
.PHONY: desktop-run
desktop-run: $(APPNAME)
	@$(ECHO) "$(COLOR_START)**** Running application ****$(COLOR_OFF)"
	@$(CHECK_TMP_BEGIN)
	@$(BRIGHTSCRIPT_TOOL) run $(CHECK_OPTIONS)
	@$(CHECK_TMP_END)
	@$(ECHO) "$(COLOR_DONE)**** Run complete ****$(COLOR_OFF)"

# -------------------------------------------------------------------------
# check-theme: check the theme xml and assets.
# -------------------------------------------------------------------------
.PHONY: check-theme
check-theme: $(APPNAME)
ifneq ($(APP_IS_THEME),)
ifeq ($(APP_CHECK_THEME_DISABLED),true)
else
	@$(ECHO) "$(COLOR_START)**** Checking theme. ****$(COLOR_OFF)"
	@$(CHECK_TMP_BEGIN)
	@-cd $(CHECK_TMP_DIR) && $(CHECK_THEME_TOOL)
	@$(CHECK_TMP_END)
	@$(ECHO) "$(COLOR_DONE)**** Checking complete ****$(COLOR_OFF)"
endif
else
	@$(ECHO) "$(COLOR_DONE)**** app is not theme ****$(COLOR_OFF)"
endif

# -------------------------------------------------------------------------
# SERIAL_NUMBER_FROM_DD is used to extract the Roku device ID
# from the ECP device description XML response.
# -------------------------------------------------------------------------
define SERIAL_NUMBER_FROM_DD
	cat $(DEVICE_INFO_TMP_FILE) | \
		grep -o "<serial-number>.*</serial-number>" | \
		sed "s|<serial-number>||" | \
		sed "s|</serial-number>||"
endef

# -------------------------------------------------------------------------
# SOFTWARE_VERSION_FROM_DD is used to extract the Roku firmware version
# from the ECP device description XML response.
# -------------------------------------------------------------------------
define SOFTWARE_VERSION_FROM_DD
	cat $(DEVICE_INFO_TMP_FILE) | \
		grep -o "<software-version>.*</software-version>" | \
		sed "s|<software-version>||" | \
		sed "s|</software-version>||"
endef

# -------------------------------------------------------------------------
# SOFTWARE_BUILD_FROM_DD is used to extract the Roku firmware build version
# from the ECP device description XML response.
# -------------------------------------------------------------------------
define SOFTWARE_BUILD_FROM_DD
	cat $(DEVICE_INFO_TMP_FILE) | \
		grep -o "<software-build>.*</software-build>" | \
		sed "s|<software-build>||" | \
		sed "s|</software-build>||"
endef

# -------------------------------------------------------------------------
# MODEL_NAME_FROM_DD is used to extract the Roku model name
# from the ECP device description XML response.
# -------------------------------------------------------------------------
define MODEL_NAME_FROM_DD
	cat $(DEVICE_INFO_TMP_FILE) | \
		grep -o "<model-name>.*</model-name>" | \
		sed "s|<model-name>||" | \
		sed "s|</model-name>||"
endef

# -------------------------------------------------------------------------
# FRIENDLY_NAME_FROM_DD is used to extract the Roku user-assigned
# name (if any)  from the ECP device description XML response.
# -------------------------------------------------------------------------
define FRIENDLY_NAME_FROM_DD
	cat $(DEVICE_INFO_TMP_FILE) | \
		grep -o '<user-device-name>.*</user-device-name>' \
		| sed 's|<user-device-name>||' \
		| sed 's|</user-device-name>||' \
		| sed 's|&apos;|'"'"'|g' \
		| sed 's|&gt;|>|g' \
		| sed 's|&lt;|<|g' \
		| sed 's|&quot;|"|g' \
		| sed 's|&amp;|\&|g'
endef

# -------------------------------------------------------------------------
# KEYED_DEVID_FROM_DD is used to extract the developer id that is keyed
# to the Roku (if any) from the ECP device description XML response.
# -------------------------------------------------------------------------
define KEYED_DEVID_FROM_DD
	cat $(DEVICE_INFO_TMP_FILE) | \
		grep -o "<keyed-developer-id>.*</keyed-developer-id>" | \
		sed "s|<keyed-developer-id>||" | \
		sed "s|</keyed-developer-id>||"
endef

# -------------------------------------------------------------------------
# CHECK_ROKU_DEV_TARGET is used to check if ROKU_DEV_TARGET refers a
# Roku device on the network that has an enabled developer web server.
# If the target doesn't exist or doesn't have an enabled web server
# the connection should fail.
# -------------------------------------------------------------------------
define CHECK_ROKU_DEV_TARGET
	rm -f $(DEV_SERVER_TMP_FILE)
	rm -f $(DEVICE_INFO_TMP_FILE)

	if [ -z "$(ROKU_DEV_TARGET)" ]; then \
		$(ECHO) "$(COLOR_ERROR)ERROR: ROKU_DEV_TARGET is not set.$(COLOR_OFF)"; \
		exit 1; \
	fi
	$(ECHO) "$(COLOR_START)Checking dev server at $(ROKU_DEV_TARGET)...$(COLOR_OFF)"

	# first check if the device is on the network via a quick ping
	ping $(QUICK_PING_ARGS) $(ROKU_DEV_TARGET) &> $(DEV_SERVER_TMP_FILE) || \
		( \
			$(ECHO) "$(COLOR_ERROR)ERROR: Device is not responding to ping.$(COLOR_OFF)"; \
			exit 1 \
		)

	# second check ECP, to verify we are talking to a Roku
	rm -f $(DEVICE_INFO_TMP_FILE)
	curl --connect-timeout 2 --silent --output $(DEVICE_INFO_TMP_FILE) \
		http://$(ROKU_DEV_TARGET):8060/query/device-info || \
		( \
			$(ECHO) "$(COLOR_ERROR)ERROR: Device is not responding to ECP...is it a Roku?$(COLOR_OFF)"; \
			exit 1 \
		)

	DEVICE_SOFTWARE_VERSION=`$(SOFTWARE_VERSION_FROM_DD)`; \
	echo "$$DEVICE_SOFTWARE_VERSION" > $(SOFTWARE_VERSION_TMP_FILE)

	# print the device ID to let us know what we are talking to
	DEVICE_MODEL_NAME=`$(MODEL_NAME_FROM_DD)`; \
	DEVICE_SERIAL_NUMBER=`$(SERIAL_NUMBER_FROM_DD)`; \
	DEVICE_FRIENDLY_NAME=`$(FRIENDLY_NAME_FROM_DD)`; \
	DEVICE_SOFTWARE_VERSION=`$(SOFTWARE_VERSION_FROM_DD)`; \
	DEVICE_SOFTWARE_BUILD=`$(SOFTWARE_BUILD_FROM_DD)`; \
	if [ -n "$$DEVICE_FRIENDLY_NAME" ]; then \
		DEVICE_STR="\"$$DEVICE_FRIENDLY_NAME\", "; \
	else \
		DEVICE_STR=""; \
	fi; \
	DEVICE_STR="$$DEVICE_STR\"$$DEVICE_MODEL_NAME\""; \
	DEVICE_STR="$$DEVICE_STR, $$DEVICE_SERIAL_NUMBER"; \
	DEVICE_STR="$$DEVICE_STR, $$DEVICE_SOFTWARE_VERSION $$DEVICE_SOFTWARE_BUILD"; \
	$(ECHO) "$(COLOR_INFO)Connected to $$DEVICE_STR.$(COLOR_OFF)"

	# third check dev web server.
	# Note, it should return 401 Unauthorized since we aren't passing the password.
	rm -f $(DEV_SERVER_TMP_FILE)
	HTTP_STATUS=`curl --connect-timeout 2 --silent --output $(DEV_SERVER_TMP_FILE) \
		http://$(ROKU_DEV_TARGET)` || \
		( \
			$(ECHO) "$(COLOR_ERROR)ERROR: Device server is not responding...$(COLOR_OFF)"; \
			$(ECHO) "$(COLOR_ERROR)is the developer installer enabled?$(COLOR_OFF)"; \
			$(ECHO) "$(COLOR_ERROR)3H 2U R L R L R$(COLOR_OFF)"; \
			exit 1 \
		)

	$(ECHO) "$(COLOR_DONE)Dev server is ready.$(COLOR_OFF)"
endef

# -------------------------------------------------------------------------
# CHECK_ROKU_DEV_PASSWORD is used to let the user know they might want to set
# their DEVPASSWORD environment variable.
# -------------------------------------------------------------------------
define CHECK_ROKU_DEV_PASSWORD
	if [ -z "$(DEVPASSWORD)" ]; then \
		$(ECHO) "Note: DEVPASSWORD is not set."; \
	fi
endef

# -------------------------------------------------------------------------
# CHECK_HTTP_STATUS is used to check that the last curl command
# to the dev web server returned HTTP 200 OK.
# -------------------------------------------------------------------------
define CHECK_HTTP_STATUS
	if [ "$$HTTP_STATUS" != "200" ]; then \
		$(ECHO) "$(COLOR_ERROR)ERROR: Device returned HTTP $$HTTP_STATUS$(COLOR_OFF)"; \
		exit 1; \
	fi
endef

# -------------------------------------------------------------------------
# GET_PLUGIN_PAGE_RESULT_STATUS is used to extract the status message
# (e.g. Success/Failed) from the dev server plugin_* web page response.
# (Note that the plugin_install web page has two fields, whereas the
# plugin_package web page just has one).
# -------------------------------------------------------------------------
define GET_PLUGIN_PAGE_RESULT_STATUS
	if [ -f "$(DEV_SERVER_TMP_FILE)" ]; then \
		cat $(DEV_SERVER_TMP_FILE) | \
			grep -o "<font color=\"red\">.*" | \
			sed "s|<font color=\"red\">||" | \
			sed "s|</font>||"; \
	else \
		echo ""; \
	fi
endef

# -------------------------------------------------------------------------
# CHECK_HTTP_STATUS_AND_PLUGIN_PAGE_RESULT is used to check that the last
# curl command to the dev web server returned HTTP 200 OK.
# The client using this check should have made a dev web server curl command
# that returns an html response file that was directed to
# $DEV_SERVER_TMP_FILE, so that in addition to the HTTP status the
# diagnostic can report the detailed error message as well (if available).
# -------------------------------------------------------------------------
define CHECK_HTTP_STATUS_AND_PLUGIN_PAGE_RESULT
	if [ "$$HTTP_STATUS" != "200" ]; then \
		$(ECHO) "$(COLOR_ERROR)ERROR: Device returned HTTP $$HTTP_STATUS$(COLOR_OFF)"; \
		MSG=`$(GET_PLUGIN_PAGE_RESULT_STATUS)`; \
		if [ ! -z "$$MSG" ]; then \
			$(ECHO) "$(COLOR_ERROR)Result: $$MSG$(COLOR_OFF)"; \
		fi; \
		exit 1; \
	else \
		MSG=`$(GET_PLUGIN_PAGE_RESULT_STATUS)`; \
		$(ECHO) "$(COLOR_DONE)Result: $$MSG$(COLOR_OFF)"; \
	fi
endef

# -------------------------------------------------------------------------
# GET_PLUGIN_PAGE_PACKAGE_LINK is used to extract the installed package
# URL from the dev server plugin_package web page response.
# -------------------------------------------------------------------------
define GET_PLUGIN_PAGE_PACKAGE_LINK
	cat $(DEV_SERVER_TMP_FILE) | \
		grep -o "<a href=\"pkgs//[^\"]*\"" | \
		sed "s|<a href=\"pkgs//||" | \
		sed "s|\"||"
endef

# -------------------------------------------------------------------------
# GET_PLUGIN_PAGE_DEV_ID is used to extract the keyed developer ID
# from the dev server plugin_package web page response.
#
# In 6.x firmware, response text has a line like:
#  <p> Your Dev ID: <font face="Courier">THE_DEVID</font> </p>
#
# In 7.0 firmware, response text has a line like:
#  devDiv.innerHTML = "<label>Your Dev ID: &nbsp;</label> THE_DEVID </label><hr />";
#
# If the box is not keyed, or doesn't have a dev app installed,
# the response doesn't contain html:
#  <meta HTTP-EQUIV="REFRESH" content="0; url=plugin_install">
# -------------------------------------------------------------------------
define GET_PLUGIN_PAGE_DEV_ID
	cat $(DEV_SERVER_TMP_FILE) | \
		grep 'Dev ID' | \
		grep -o -E '[0-9a-f]{40}'
endef

# -------------------------------------------------------------------------
# install: install the app as the dev channel on the Roku target device.
# -------------------------------------------------------------------------
.PHONY: install
install: $(APPNAME) check
ifneq ($(APP_IS_THEME),)
install: check-theme
endif
	@$(CHECK_ROKU_DEV_TARGET)

	@$(ECHO) "$(COLOR_START)Installing $(APPNAME)...$(COLOR_OFF)"
	@rm -f $(DEV_SERVER_TMP_FILE)
	@$(CHECK_ROKU_DEV_PASSWORD)
	@HTTP_STATUS=`curl --user $(USERPASS) --digest --silent --show-error \
		-F "mysubmit=Install" -F "archive=@$(APP_FILE)" \
		--output $(DEV_SERVER_TMP_FILE) \
		--write-out "%{http_code}" \
		http://$(ROKU_DEV_TARGET)/plugin_install`; \
	$(CHECK_HTTP_STATUS_AND_PLUGIN_PAGE_RESULT)

# -------------------------------------------------------------------------
# installlib: install the plugin as the dev component library on the
#             Roku target device.
# -------------------------------------------------------------------------
.PHONY: installlib
installlib: $(APPNAME)
	@$(CHECK_ROKU_DEV_TARGET)

# TODO: select the INSTALL_LIB_COMMAND based on the target's software version
#@$(SETUP_LIB_COMMANDS)
#@INSTALL_LIB_COMMAND=`cat $(INSTALL_LIB_COMMAND_TMP_FILE)`

	@$(ECHO) "$(COLOR_START)Installing Component Library $(APPNAME)...$(COLOR_OFF)"
	@rm -f $(DEV_SERVER_TMP_FILE)
	@$(CHECK_ROKU_DEV_PASSWORD)
	@HTTP_STATUS=`curl --user $(USERPASS) --digest --silent --show-error \
		-F "mysubmit=$(INSTALL_LIB_COMMAND)" -F "archive=@$(APP_FILE)"\
		--output $(DEV_SERVER_TMP_FILE) \
		--write-out "%{http_code}" \
		http://$(ROKU_DEV_TARGET)/plugin_install`; \
	$(CHECK_HTTP_STATUS_AND_PLUGIN_PAGE_RESULT)

# -------------------------------------------------------------------------
# remove: uninstall the dev channel from the Roku target device.
# -------------------------------------------------------------------------
.PHONY: remove
remove:
	@$(CHECK_ROKU_DEV_TARGET)

	@$(ECHO) "$(COLOR_START)Removing dev app...$(COLOR_OFF)"
	@rm -f $(DEV_SERVER_TMP_FILE)
	@$(CHECK_ROKU_DEV_PASSWORD)
	@HTTP_STATUS=`curl --user $(USERPASS) --digest --silent --show-error \
		-F "mysubmit=Delete" -F "archive=" \
		--output $(DEV_SERVER_TMP_FILE) \
		--write-out "%{http_code}" \
		http://$(ROKU_DEV_TARGET)/plugin_install`; \
	$(CHECK_HTTP_STATUS_AND_PLUGIN_PAGE_RESULT)

# -------------------------------------------------------------------------
# removelib: uninstall the dev component lib plugin from the Roku target device.
# -------------------------------------------------------------------------
.PHONY: removelib
removelib:
	@$(CHECK_ROKU_DEV_TARGET)

# TODO: select the REMOVE_LIB_COMMAND based on the target's software version
#@$(SETUP_LIB_COMMANDS)
#@REMOVE_LIB_COMMAND=`cat $(REMOVE_LIB_COMMAND_TMP_FILE)`

	@$(ECHO) "$(COLOR_START)Removing dev library...$(COLOR_OFF)"
	@rm -f $(DEV_SERVER_TMP_FILE)
	@$(CHECK_ROKU_DEV_PASSWORD)
	@HTTP_STATUS=`curl --user $(USERPASS) --digest --silent --show-error \
		-F "mysubmit=$(REMOVE_LIB_COMMAND)" -F "archive=" \
		--output $(DEV_SERVER_TMP_FILE) \
		--write-out "%{http_code}" \
		http://$(ROKU_DEV_TARGET)/plugin_install`; \
	$(CHECK_HTTP_STATUS_AND_PLUGIN_PAGE_RESULT)

# -------------------------------------------------------------------------
# removeall: uninstall the dev channel and all dev lib plugins from the
# Roku target device.
# -------------------------------------------------------------------------
.PHONY: removeall
removeall:
	@$(CHECK_ROKU_DEV_TARGET)

	@$(ECHO) "$(COLOR_START)Removing the dev app and libraries...$(COLOR_OFF)"
	@rm -f $(DEV_SERVER_TMP_FILE)
	@$(CHECK_ROKU_DEV_PASSWORD)
	@HTTP_STATUS=`curl --user $(USERPASS) --digest --silent --show-error \
		-F "mysubmit=DeleteAll" -F "archive=" \
		--output $(DEV_SERVER_TMP_FILE) \
		--write-out "%{http_code}" \
		http://$(ROKU_DEV_TARGET)/plugin_install`; \
	$(CHECK_HTTP_STATUS_AND_PLUGIN_PAGE_RESULT)

# -------------------------------------------------------------------------
# check-roku-dev-target: check the status of the Roku target device.
# -------------------------------------------------------------------------
.PHONY: check-roku-dev-target
check-roku-dev-target:
	@$(CHECK_ROKU_DEV_TARGET)

# -------------------------------------------------------------------------
# run: the install target is 'smart' and doesn't do anything if the package
# didn't change.
# But usually I want to run it even if it didn't change, so force a fresh
# install by doing a remove first.
# Some day we should look at doing the force run via a plugin_install flag,
# but for now just brute force it.
# -------------------------------------------------------------------------
.PHONY: run
run: remove install

# -------------------------------------------------------------------------
# get-target-key: return what developer ID the target Roku is keyed to.
#
# Note: Use ECP query/device-info instead, as that will have the
# keyed-developer-id field set regardless of whether a dev app is installed.
# -------------------------------------------------------------------------
.PHONY: get-target-key
get-target-key:
	@$(CHECK_ROKU_DEV_TARGET)

	@MSG=`$(KEYED_DEVID_FROM_DD)`; \
	if [ -z "$$MSG" ]; then \
		MSG="Roku is not keyed"; \
	else \
		MSG="Roku is keyed to Dev ID $$MSG"; \
	fi; \
	$(ECHO) "$(COLOR_DONE)$$MSG$(COLOR_OFF)"

# -------------------------------------------------------------------------
# rekey-target: key the target Roku with the devid from a .pkg.
# -------------------------------------------------------------------------
.PHONY: rekey-target
rekey-target:
	@$(CHECK_ROKU_DEV_TARGET)

	@if [ -z "$(APP_KEY_FILE)" ]; then \
		$(ECHO) "$(COLOR_ERROR)ERROR: APP_KEY_FILE not defined$(COLOR_OFF)"; \
		exit 1; \
	fi
	@if [ ! -f "$(APP_KEY_FILE)" ]; then \
		$(ECHO) "$(COLOR_ERROR)ERROR: key file not found: $(APP_KEY_FILE)$(COLOR_OFF)"; \
		exit 1; \
	fi

	@if [ -z "$(APP_KEY_PASS)" ]; then \
		read -r -p "Password: " REPLY; \
		echo "$$REPLY" > $(APP_KEY_PASS_TMP); \
	else \
		echo "$(APP_KEY_PASS)" > $(APP_KEY_PASS_TMP); \
	fi

	@rm -f $(DEV_SERVER_TMP_FILE)
	@$(CHECK_ROKU_DEV_PASSWORD)
	@PASSWD=`cat $(APP_KEY_PASS_TMP)`; \
	HTTP_STATUS=`curl --user $(USERPASS) --digest --silent --show-error \
		-F "mysubmit=Rekey" -F "archive=@$(APP_KEY_FILE)" \
		-F "passwd=$$PASSWD" \
		--output $(DEV_SERVER_TMP_FILE) \
		--write-out "%{http_code}" \
		http://$(ROKU_DEV_TARGET)/plugin_inspect`; \
	$(CHECK_HTTP_STATUS_AND_PLUGIN_PAGE_RESULT)

# -------------------------------------------------------------------------
# pkg: use to create a pkg file from the application sources.
#
# Usage:
# The application name should be specified via $APPNAME.
# The application version should be specified via $VERSION.
# The developer's signing password (from genkey) should be passed via
# $APP_KEY_PASS, or via stdin, otherwise the script will prompt for it.
# -------------------------------------------------------------------------
.PHONY: pkg
pkg: install
	@$(ECHO) "$(COLOR_START)**** Creating package ****$(COLOR_OFF)"

	@$(ECHO) "  >> creating destination directory $(PKGREL)"
	@if [ ! -d $(PKGREL) ]; then \
		mkdir -p $(PKGREL); \
	fi

	@$(ECHO) "  >> setting directory permissions for $(PKGREL)"
	@if [ ! -w $(PKGREL) ]; then \
		chmod 755 $(PKGREL); \
	fi

	@$(CHECK_ROKU_DEV_TARGET)

	@$(ECHO) "Packaging $(APP_NAME)/$(APP_VERSION) to $(APP_PKG_FILE)"

	@if [ -z "$(APP_KEY_PASS)" ]; then \
		read -r -p "Password: " REPLY; \
		echo "$$REPLY" > $(APP_KEY_PASS_TMP); \
	else \
		echo "$(APP_KEY_PASS)" > $(APP_KEY_PASS_TMP); \
	fi

	@rm -f $(DEV_SERVER_TMP_FILE)
	@$(CHECK_ROKU_DEV_PASSWORD)
	@PASSWD=`cat $(APP_KEY_PASS_TMP)`; \
	PKG_TIME=`expr \`date +%s\` \* 1000`; \
	HTTP_STATUS=`curl --user $(USERPASS) --digest --silent --show-error \
		-F "mysubmit=Package" -F "app_name=$(APP_NAME)/$(APP_VERSION)" \
		-F "passwd=$$PASSWD" -F "pkg_time=$$PKG_TIME" \
		--output $(DEV_SERVER_TMP_FILE) \
		--write-out "%{http_code}" \
		http://$(ROKU_DEV_TARGET)/plugin_package`; \
	$(CHECK_HTTP_STATUS)

	@MSG=`$(GET_PLUGIN_PAGE_RESULT_STATUS)`; \
	case "$$MSG" in \
		*Success*) \
			;; \
		*)	$(ECHO) "$(COLOR_ERROR)Result: $$MSG$(COLOR_OFF)"; \
			exit 1 \
			;; \
	esac

	@$(CHECK_ROKU_DEV_PASSWORD)
	@PKG_LINK=`$(GET_PLUGIN_PAGE_PACKAGE_LINK)`; \
	HTTP_STATUS=`curl --user $(USERPASS) --digest --silent --show-error \
		--output $(APP_PKG_FILE) \
		--write-out "%{http_code}" \
		http://$(ROKU_DEV_TARGET)/pkgs/$$PKG_LINK`; \
	$(CHECK_HTTP_STATUS)

	@$(ECHO) "$(COLOR_DONE)**** Package $(APPNAME) complete ****$(COLOR_OFF)"

# -------------------------------------------------------------------------
# app-pkg: use to create a pkg file from the application sources.
# Similar to the pkg target, but does not require a player to do the signing.
# Instead it requires the developer key file and signing password to be
# specified, which are then passed to the app-package desktop tool to create
# the package file.
#
# Usage:
# The application name should be specified via $APPNAME.
# The application version should be specified via $VERSION.
# $APP_PKG_TYPE may be zip (the default), cram (for cramfs), or squashfs.
# The developer's key file (.pkg file) should be specified via $APP_KEY_FILE.
# The developer's signing password (from genkey) should be passed via
# $APP_KEY_PASS, or via stdin, otherwise the script will prompt for it.
#
# If building a squashfs-based package, this supports packaging multiple
# versions for different CPU architectures if the various
# APP_PKG_SQUASHFS_<arch> flags are set to true.
# -------------------------------------------------------------------------
.PHONY: app-pkg
app-pkg: $(APPNAME) check
	@$(ECHO) "$(COLOR_START)**** Creating package ****$(COLOR_OFF)"

ifneq ($(APP_PKG_TYPE),$(filter $(APP_PKG_TYPE),zip cram squashfs))
	$(ECHO) "$(COLOR_ERROR)ERROR: invalid APP_PKG_TYPE $(APP_PKG_TYPE) $(COLOR_OFF)"; \
	exit 1
endif

	@$(ECHO) "  >> creating destination directory $(PKGREL)"
	@mkdir -p $(PKGREL) && chmod 755 $(PKGREL)

	@if [ -z "$(APP_KEY_FILE)" ]; then \
		$(ECHO) "$(COLOR_ERROR)ERROR: APP_KEY_FILE not defined$(COLOR_OFF)"; \
		exit 1; \
	fi
	@if [ ! -f "$(APP_KEY_FILE)" ]; then \
		$(ECHO) "$(COLOR_ERROR)ERROR: key file not found: $(APP_KEY_FILE)$(COLOR_OFF)"; \
		exit 1; \
	fi

	@if [ -z "$(APP_KEY_PASS)" ]; then \
		read -r -p "Password: " REPLY; \
		echo "$$REPLY" > $(APP_KEY_PASS_TMP); \
	else \
		echo "$(APP_KEY_PASS)" > $(APP_KEY_PASS_TMP); \
	fi

	@$(ECHO) "Packaging $(APP_NAME)/$(APP_VERSION) to $(APP_PKG_FILE)"

	@if [ -z "$(APP_VERSION)" ]; then \
		$(ECHO) "WARNING: VERSION is not set."; \
	fi

	@PASSWD=`cat $(APP_KEY_PASS_TMP)`; \
	$(APP_PACKAGE_TOOL) package $(APP_FILE) \
		-n $(APP_NAME)/$(APP_VERSION) \
		-k $(APP_KEY_FILE) \
		-p "$$PASSWD" \
		-o $(APP_PKG_FILE)

ifeq ($(APP_PKG_SQUASHFS_ARM),true)
	@$(ECHO) "Packaging $(APP_NAME)/$(APP_VERSION) to $(APP_ARM_PKG_FILE)"
	@PASSWD=`cat $(APP_KEY_PASS_TMP)`; \
	$(APP_PACKAGE_TOOL) package $(APP_SQUASHFS_ARM_FILE) \
		-n $(APP_NAME)/$(APP_VERSION) \
		-k $(APP_KEY_FILE) \
		-p "$$PASSWD" \
		-o $(APP_ARM_PKG_FILE)
endif
ifeq ($(APP_PKG_SQUASHFS_MIPS_SOFTFP),true)
	@$(ECHO) "Packaging $(APP_NAME)/$(APP_VERSION) to $(APP_MIPS_SOFTFP_PKG_FILE)"
	@PASSWD=`cat $(APP_KEY_PASS_TMP)`; \
	$(APP_PACKAGE_TOOL) package $(APP_SQUASHFS_MIPS_SOFTFP_FILE) \
		-n $(APP_NAME)/$(APP_VERSION) \
		-k $(APP_KEY_FILE) \
		-p "$$PASSWD" \
		-o $(APP_MIPS_SOFTFP_PKG_FILE)
endif
ifeq ($(APP_PKG_SQUASHFS_MIPS_HARDFP),true)
	@$(ECHO) "Packaging $(APP_NAME)/$(APP_VERSION) to $(APP_MIPS_HARDFP_PKG_FILE)"
	@PASSWD=`cat $(APP_KEY_PASS_TMP)`; \
	$(APP_PACKAGE_TOOL) package $(APP_SQUASHFS_MIPS_HARDFP_FILE) \
		-n $(APP_NAME)/$(APP_VERSION) \
		-k $(APP_KEY_FILE) \
		-p "$$PASSWD" \
		-o $(APP_MIPS_HARDFP_PKG_FILE)
endif

	@rm $(APP_KEY_PASS_TMP)

	@$(ECHO) "$(COLOR_DONE)**** Package $(APPNAME) complete ****$(COLOR_OFF)"

# -------------------------------------------------------------------------
# teamcity: used to build .zip and .pkg file on TeamCity.
# See app-pkg target for info on options for specifying the signing password.
# -------------------------------------------------------------------------
ARTIFACT_DIR=$(CURDIR)/tmp/artifacts/
.PHONY: teamcity
teamcity: app-pkg
ifeq ($(IS_TEAMCITY_BUILD),true)
	@$(ECHO) "Adding TeamCity artifacts..."

#	sudo rm -rf /tmp/artifacts
	mkdir -p $(ARTIFACT_DIR)

	cp $(APP_ZIP_FILE) $(ARTIFACT_DIR)$(APP_NAME)$(APP_MARK_ZIP)-$(APP_VERSION).zip
	@$(ECHO) "##teamcity[publishArtifacts '$(ARTIFACT_DIR)$(APP_NAME)$(APP_MARK_ZIP)-$(APP_VERSION).zip']"

	cp $(APP_PKG_FILE) $(ARTIFACT_DIR)$(APP_NAME)-$(APP_VERSION).pkg
	@$(ECHO) "##teamcity[publishArtifacts '$(ARTIFACT_DIR)$(APP_NAME)-$(APP_VERSION).pkg']"

ifeq ($(APP_PKG_TYPE),cram)
	cp $(APP_CRAMFS_FILE) $(ARTIFACT_DIR)$(APP_NAME)-$(APP_VERSION).cramfs
	@$(ECHO) "##teamcity[publishArtifacts '$(ARTIFACT_DIR)$(APP_NAME)-$(APP_VERSION).cramfs']"
else ifeq ($(APP_PKG_TYPE),squashfs)
	cp $(APP_SQUASHFS_FILE) $(ARTIFACT_DIR)$(APP_NAME)-$(APP_VERSION).squashfs
	@$(ECHO) "##teamcity[publishArtifacts '$(ARTIFACT_DIR)$(APP_NAME)-$(APP_VERSION).squashfs']"
ifeq ($(APP_PKG_SQUASHFS_ARM),true)
	cp $(APP_SQUASHFS_ARM_FILE) $(ARTIFACT_DIR)$(APP_NAME)-$(APP_VERSION).arm.squashfs
	@$(ECHO) "##teamcity[publishArtifacts '$(ARTIFACT_DIR)$(APP_NAME)-$(APP_VERSION).arm.squashfs']"
	cp $(APP_ARM_PKG_FILE) $(ARTIFACT_DIR)$(APP_NAME)-$(APP_VERSION).arm.pkg
	@$(ECHO) "##teamcity[publishArtifacts '$(ARTIFACT_DIR)$(APP_NAME)-$(APP_VERSION).arm.pkg']"
endif
ifeq ($(APP_PKG_SQUASHFS_MIPS_SOFTFP),true)
	cp $(APP_SQUASHFS_MIPS_SOFTFP_FILE) $(ARTIFACT_DIR)$(APP_NAME)-$(APP_VERSION).mips_soft.squashfs
	@$(ECHO) "##teamcity[publishArtifacts '$(ARTIFACT_DIR)$(APP_NAME)-$(APP_VERSION).mips_soft.squashfs']"
	cp $(APP_MIPS_SOFTFP_PKG_FILE) $(ARTIFACT_DIR)$(APP_NAME)-$(APP_VERSION).mips_soft.pkg
	@$(ECHO) "##teamcity[publishArtifacts '$(ARTIFACT_DIR)$(APP_NAME)-$(APP_VERSION).mips_soft.pkg']"
endif
ifeq ($(APP_PKG_SQUASHFS_MIPS_HARDFP),true)
	cp $(APP_SQUASHFS_MIPS_HARDFP_FILE) $(ARTIFACT_DIR)$(APP_NAME)-$(APP_VERSION).mips_hard.squashfs
	@$(ECHO) "##teamcity[publishArtifacts '$(ARTIFACT_DIR)$(APP_NAME)-$(APP_VERSION).mips_hard.squashfs']"
	cp $(APP_MIPS_HARDFP_PKG_FILE) $(ARTIFACT_DIR)$(APP_NAME)-$(APP_VERSION).mips_hard.pkg
	@$(ECHO) "##teamcity[publishArtifacts '$(ARTIFACT_DIR)$(APP_NAME)-$(APP_VERSION).mips_hard.pkg']"
endif
endif

	@$(ECHO) "TeamCity artifacts complete."
else
	@$(ECHO) "Not running on TeamCity, skipping artifacts."
endif

# -------------------------------------------------------------------------
# inspect-package: generic utility to inspect a specified .pkg file,
# using the app-package utility.  When run it will prompt for the .pkg file
# to be inspected, unless the PKG variable is already set.
# Then, it will prompt for the developer signing password matching the .pkg
# file.  (If an IB.bin file is found, that will automatically be used for
# decryption in which case the password does not need to be specified).
# The default inspect command is used which just prints the metadata from
# the .pkg file such as the package name/version and developer ID.
# -------------------------------------------------------------------------
PKG_PATH_TMP     := $(APP_MK_TMP_DIR)/pkg_path
APP_PKG_OPTS_TMP := $(APP_MK_TMP_DIR)/app_pkg_opts

.PHONY: inspect-package
inspect-package:
	@if [ -z "$(PKG)" ]; then \
		read -r -p "Pkg file to inspect: " REPLY; \
		echo "$$REPLY" > $(PKG_PATH_TMP); \
	else \
		echo "$(PKG)" > $(PKG_PATH_TMP); \
	fi

	@PKG_PATH=`cat $(PKG_PATH_TMP)`; \
	if [ ! -f "$$PKG_PATH" ]; then \
		$(ECHO) "$(COLOR_ERROR)ERROR: key file not found: $$PKG_PATH$(COLOR_OFF)"; \
		exit 1; \
	fi

	@if [ -f "/tmp/IB.bin" ]; then \
		echo "-i /tmp/IB.bin" > $(APP_PKG_OPTS_TMP); \
		$(ECHO) "Using IB.bin as master password."; \
	else \
		read -r -p "Password: " REPLY; \
		echo "-p $$REPLY" > $(APP_PKG_OPTS_TMP); \
	fi

	@PKG_PATH=`cat $(PKG_PATH_TMP)`; \
	$(ECHO) "$(APP_PACKAGE_TOOL) inspect $$PKG_PATH ..."

	@PKG_PATH=`cat $(PKG_PATH_TMP)`; \
	APP_PKG_OPTS=`cat $(APP_PKG_OPTS_TMP)`; \
	$(APP_PACKAGE_TOOL) inspect "$$PKG_PATH" $$APP_PKG_OPTS

	@rm $(PKG_PATH_TMP)
	@rm $(APP_PKG_OPTS_TMP)

##########################################################################

# -------------------------------------------------------------------------
# CHECK_NATIVE_TARGET is used to check if the Roku simulator is
# configured.
# -------------------------------------------------------------------------
define CHECK_NATIVE_TARGET
	if [ -z "$(ROKU_NATIVE_DEV)" ]; then \
		$(ECHO) "$(COLOR_ERROR)ERROR: ROKU_NATIVE_DEV not defined$(COLOR_OFF)"; \
		exit 1; \
	fi
	if [ ! -d "$(ROKU_NATIVE_DEV)" ]; then \
		$(ECHO) "$(COLOR_ERROR)ERROR: native dev dir not found: $(ROKU_NATIVE_DEV)$(COLOR_OFF)"; \
		exit 1; \
	fi
	if [ ! -d "$(NATIVE_DIST_DIR)" ]; then \
		$(ECHO) "$(COLOR_ERROR)ERROR: native build dir not found: $(NATIVE_DIST_DIR)$(COLOR_OFF)"; \
		exit 1; \
	fi
endef

# -------------------------------------------------------------------------
# install-native: install the app as the dev channel on the Roku simulator.
# -------------------------------------------------------------------------
.PHONY: install-native
install-native: $(APPNAME) check
	@$(CHECK_NATIVE_TARGET)
	@$(ECHO) "$(COLOR_START)Installing $(APPNAME) to native.$(COLOR_OFF)"
	@if [ ! -d "$(NATIVE_DEV_REL)" ]; then \
		mkdir "$(NATIVE_DEV_REL)"; \
	fi
	@$(ECHO) "Source is $(APP_ZIP_FILE)"
	@$(ECHO) "Target is $(NATIVE_DEV_PKG)"
	@cp $(APP_ZIP_FILE) $(NATIVE_DEV_PKG)
	@$(NATIVE_TICKLER)

# -------------------------------------------------------------------------
# remove-native: uninstall the dev channel from the Roku simulator.
# -------------------------------------------------------------------------
.PHONY: remove-native
remove-native:
	@$(CHECK_NATIVE_TARGET)
	@$(ECHO) "$(COLOR_START)Removing $(APPNAME) from native.$(COLOR_OFF)"
	@rm $(NATIVE_DEV_PKG)
	@$(NATIVE_TICKLER)

##########################################################################

TRIM_SOURCE_TMP_FILE := $(APP_MK_TMP_DIR)/trim_source_tmp

TRIM_SOURCE_VERBOSE ?= false

# -------------------------------------------------------------------------
# trim-source: remove trailing whitespace from any writable source
# text files (*.brs, *.xml)
#
# Implemented as trimming to a temp file, then comparing against the
# original file and only touching the source file if it needs trimming.
# So each pass of running should only list changed files, i.e. if
# run twice in a row the second run should be a no-op.
# Note, we check that a file is writable before modifying it, and just
# warn if it is not writable. 
# Note that apparently sed -i ignores the writable permission and will
# modify the file data regardless! 
# -------------------------------------------------------------------------
.PHONY: trim-source
trim-source:
	@$(ECHO) "Checking files..."
	@( \
		SRC_FILES=`\find . -type f \( -name '*.brs' -o -name '*.xml' \) \
			| sort`; \
		TRIM_EXPR='s/[[:blank:]]*$$//'; \
		for F in $$SRC_FILES; do \
			sed $$TRIM_EXPR "$$F" > $(TRIM_SOURCE_TMP_FILE); \
			if ! cmp -s "$$F" $(TRIM_SOURCE_TMP_FILE); then \
				if [ -w "$$F" ]; then \
					$(ECHO) "Trimming: $$F..."; \
					sed $(SED_IN_PLACE_ARGS) $$TRIM_EXPR "$$F"; \
				else \
					$(ECHO) "Read-only file needs trimming: $$F"; \
				fi; \
			else \
				if [ "$(TRIM_SOURCE_VERBOSE)" = "true" ]; then \
					$(ECHO) "OK: $$F"; \
				fi; \
			fi; \
			rm $(TRIM_SOURCE_TMP_FILE); \
		done; \
	)
	@$(ECHO) "Done."

.PHONY: trim-source-verbose
trim-source-verbose: TRIM_SOURCE_VERBOSE=true
trim-source-verbose: trim-source

##########################################################################

# -------------------------------------------------------------------------
# art-jpg-opt: compress any jpg files in the source tree.
# Used by the art-opt target.
# -------------------------------------------------------------------------
APPS_JPG_ART ?= `\find . -name "*.jpg"`

.PHONY: art-jpg-opt
art-jpg-opt:
ifneq ($(P4CLIENT),)
	@$(ECHO) "Checking out jpg files..."
	@p4 edit $(APPS_JPG_ART)
endif
	@for i in $(APPS_JPG_ART); \
	do \
		TMPJ=`mktemp` || return 1; \
		$(ECHO) "Optimizing $$i"; \
		jpegtran -copy none -optimize -outfile $$TMPJ $$i && mv -f $$TMPJ $$i; \
	done
ifneq ($(P4CLIENT),)
	@$(ECHO) "Reverting unchanged jpg files..."
	@p4 revert -a $(APPS_JPG_ART)
endif
	@$(ECHO) "Done."

# -------------------------------------------------------------------------
# art-png-opt: compress any png files in the source tree.
# Used by the art-opt target.
# -------------------------------------------------------------------------
APPS_PNG_ART ?= `\find . -name "*.png"`

.PHONY: art-png-opt
art-png-opt:
ifneq ($(P4CLIENT),)
	@$(ECHO) "Checking out png files..."
	@p4 edit $(APPS_PNG_ART)
endif
	@for i in $(APPS_PNG_ART); \
	do \
		$(ECHO) "Optimizing $$i"; \
		optipng -strip all -quiet $$i; \
	done
ifneq ($(P4CLIENT),)
	@$(ECHO) "Reverting unchanged png files..."
	@p4 revert -a $(APPS_PNG_ART)
endif
	@$(ECHO) "Done."

# -------------------------------------------------------------------------
# art-opt: compress any png and jpg files in the source tree using
# lossless compression options.
# This assumes a Perforce client/workspace is configured.
# Modified files are opened for edit in the default changelist.
# -------------------------------------------------------------------------
.PHONY: art-opt
art-opt: art-png-opt art-jpg-opt

##########################################################################

# -------------------------------------------------------------------------
# tr: this target is used to update translation files for an application
#
# Preconditions: 'locale' subdirectory must be present
# Also there must be a locale subdirectory for each desired locale to be output,
# e.g. en_US, fr_CA, es_ES, de_DE, pt_BR, ...
#
# MAKE_TR_OPTIONS may be set to in the external environment,
# if needed.
# -------------------------------------------------------------------------
MAKE_TR_OPTIONS ?=

ROKU_LOCALES := en_US fr_CA es_ES de_DE pt_BR
APP_LOCALES ?= $(ROKU_LOCALES)

.PHONY: tr
tr:
	@if [ ! -d locale ]; then \
		$(ECHO) "Creating locale directory"; \
		mkdir locale; \
	fi
	@if [ ! -d locale/en_US ]; then \
		$(ECHO) "Creating locale/en_US directory"; \
		mkdir locale/en_US; \
	fi
	@for LOCALE in $(APP_LOCALES); \
	do \
		if [ ! -d locale/$$LOCALE ]; then \
			$(ECHO) "Creating locale/$$LOCALE directory"; \
			mkdir locale/$$LOCALE; \
		fi \
	done
ifneq ($(P4CLIENT),)
	@$(ECHO) "P4 editing any translation files..."
	@-p4 edit locale/.../translations.ts > /dev/null 2>&1
endif
	@$(ECHO) "========================================"
	@$(ECHO) "Generating/updating translation files..."
	@$(MAKE_TR_TOOL) $(MAKE_TR_OPTIONS) .
	@$(ECHO) "========================================"
ifneq ($(P4CLIENT),)
	@$(ECHO) "P4 adding any new files..."
	@-p4 add locale/*/translations.ts > /dev/null 2>&1
	@$(ECHO) "P4 reverting unchanged files..."
	@-p4 revert -a locale/.../translations.ts > /dev/null 2>&1
	@$(ECHO) "P4 listing opened files..."
	@-p4 opened -c default
endif

##########################################################################


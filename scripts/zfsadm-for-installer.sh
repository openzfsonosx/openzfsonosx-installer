#!/usr/bin/env bash
# zfsadm, originated by ilovezfs, licensed under GPLv3
# 
# Suggested workflows:
# 1) Run zfsadm with no options, in order to fetch and build ZFS.
# 2) Then, you may do one of these:
#	2a) Run 'zfsadm -k' to manually load the resulting suite, and use
#	    'sudo ./cmd.sh zfs ...', 'sudo ./cmd.sh zpool ...', etc.
#	2b) Install the resulting suite using 'sudo make install' in each of
#	    their respective directories: ~/Developer/spl and ~/Developer/zfs.
#	    Most notably, this targets '/System/Library/Extensions' and
#	    '/usr/local/sbin'. Then you	may add /usr/local/sbin to your PATH,
#	    and invoke the binaries directly, 'zpool ...', 'zfs ...', etc.

set -e

export DSCL=dscl
export LOGNAME_CMD=logname
export CUT=cut

#defaults:
export HOME_DIR="$($DSCL . -read /Users/"$($LOGNAME_CMD)" NFSHomeDirectory |\
    $CUT -d ' ' -f2)"
export DEV_DIR="$HOME_DIR"/Developer
export INSTALL_DIR=/System/Library/Extensions
export OWNER="$($LOGNAME_CMD)"
export BRANCH="master"
export SPL_BRANCH="default"
export ZFS_BRANCH="default"
export TARGET_OS_X_VERSION="native"
export PULL="on"
export SPL_REPOSITORY_URL="https://github.com/openzfsonosx/spl"
export ZFS_REPOSITORY_URL="https://github.com/openzfsonosx/zfs"

export ML_SPL_DIFF="$PWD"/spl-108.diff
export MAV_SPL_DIFF="$PWD"/spl-109.diff
export ML_ZFS_DIFF="$PWD"/zfs-108.diff
export MAV_ZFS_DIFF="$PWD"/zfs-109.diff

export BASH_PATH=bash
export CAT=cat
export CHOWN=chown
export ECHO=echo
export GIT=git
export GREP=grep
export ID=id
export KEXTLOAD=kextload
export KEXTSTAT=kextstat
export KEXTUNLOAD=kextunload
export MAKE=make
export MKDIR=mkdir
export PRINTF=printf
export RM=rm
export RMDIR=rmdir

if [ -e /usr/local/bin/rsync ]
then
export RSYNC="/usr/local/bin/rsync"
export RSYNC_OPTIONS="-rltDcAX --fileflags --delete --itemize-changes"
else
export RSYNC="/usr/bin/rsync"
export RSYNC_OPTIONS="-rltDcE --delete --itemize-changes"
fi

export RUBY=ruby
export SUDO=sudo
if [[ $($ID -u) -ne 0 ]]
then
set -e
	$SUDO "$0" "$@"
	exit 0
fi
set -e

OPTS=$($RUBY - "$@" <<'EndOfRuby'
require 'getoptlong'

devdir=ENV['DEV_DIR']
installdir=ENV['INSTALL_DIR']
owner=ENV['OWNER']
branch=ENV['BRANCH']
splbranch=ENV['SPL_BRANCH']
zfsbranch=ENV['ZFS_BRANCH']
targetosxversion=ENV['TARGET_OS_X_VERSION']
pull=ENV['PULL']

longopts = GetoptLong.new(
	[ '--dev-dir',		'-d',	GetoptLong::REQUIRED_ARGUMENT ],
	[ '--install-dir',	'-i',	GetoptLong::REQUIRED_ARGUMENT ],
	[ '--owner',		'-o',	GetoptLong::REQUIRED_ARGUMENT ],
	[ '--branch',		'-b',	GetoptLong::OPTIONAL_ARGUMENT],
	[ '--spl-branch',	'-s',	GetoptLong::OPTIONAL_ARGUMENT ],
	[ '--zfs-branch',	'-z',	GetoptLong::OPTIONAL_ARGUMENT ],
	[ '--load',		'-l',	GetoptLong::NO_ARGUMENT ],
	[ '--unload',		'-u',	GetoptLong::NO_ARGUMENT ],
	[ '--kexts-only',	'-k',	GetoptLong::NO_ARGUMENT ],
	[ '--configure',	'-c',	GetoptLong::NO_ARGUMENT ],
	[ '--make',		'-m',	GetoptLong::NO_ARGUMENT ],
	[ '--target',		'-t',	GetoptLong::REQUIRED_ARGUMENT ],
	[ '--pull',		'-p',	GetoptLong::REQUIRED_ARGUMENT ],
	[ '--dry-run',		'-n',	GetoptLong::NO_ARGUMENT ],
	[ '--help',		'-h',	GetoptLong::NO_ARGUMENT ]
)

simpleopts={}
begin
longopts.each do |opt, arg|
	arg = arg.to_s.strip
	arg = (arg.length == 0) ? nil : arg
	case opt
	when '--dev-dir'
		devdir = arg
	when '--install-dir'
		installdir = arg
	when '--owner'
		owner = arg
	when '--branch'
		simpleopts[:b] = 1
		branch = arg ? arg : branch
	when '--spl-branch'
		simpleopts[:s] = 1
		splbranch = arg ? arg : splbranch
	when '--zfs-branch'
		simpleopts[:z] = 1
		zfsbranch = arg ? arg : zfsbranch
	when '--load'
		simpleopts[:l] = 1
	when '--unload'
		simpleopts[:u] = 1
	when '--kexts-only'
		simpleopts[:k] = 1
	when '--configure'
		simpleopts[:c] = 1
	when '--make'
		simpleopts[:m] = 1
	when '--target'
		simpleopts[:t] = 1
		targetosxversion = arg
	when '--pull'
		simpleopts[:p] = 1
		pull = arg
	when '--dry-run'
		simpleopts[:n] = 1
	when '--help'
		#RDoc::usage
		simpleopts[:h] = 1
	end
end
rescue => err
	simpleopts[:e]=1
end
simpleoptsstr = simpleopts.keys.map{ |i| i.to_s }.join

puts "-" + simpleoptsstr + \
    " " + devdir + \
    " " + installdir + \
    " " + owner + \
    " " + branch + \
    " " + splbranch + \
    " " + zfsbranch + \
    " " + targetosxversion + \
    " " + pull
EndOfRuby
)

($ECHO set -- "$OPTS" ; $CAT <<'EndOfBash'
set -e
# DEBUG_
# $ECHO "arg0 ${0}"
# $ECHO "arg1 ${1}"
# $ECHO "arg2 ${2}"
# $ECHO "arg3 ${3}"
# $ECHO "arg4 ${4}"
# $ECHO "arg5 ${5}"
# $ECHO "arg6 ${6}"
# $ECHO "arg7 ${7}"
# $ECHO "arg8 ${8}"
# $ECHO "arg9 ${9}"
# $ECHO "arg10 ${10}"
# _DEBUG

DEV_DIR="$2"
INSTALL_DIR="$3"
OWNER="$4"
BRANCH="$5"
SPL_BRANCH="$6"
ZFS_BRANCH="$7"
TARGET_OS_X_VERSION="$8"
PULL="$9"
SHOULD_CLEAN="yes"

SPL_REPOSITORY_DIR="$DEV_DIR"/spl
ZFS_REPOSITORY_DIR="$DEV_DIR"/zfs

do_rsync() {
	"$SUDO" "$RSYNC" $RSYNC_OPTIONS "$1" "$2"
}

ncpu=$(/usr/sbin/sysctl -n hw.ncpu)
tcpu=$((ncpu / 2 + 1))
[[ ${tcpu} -gt 8 ]] && tcpu=8
JOBS=$tcpu

if [ x"${INSTALL_DIR:0:1}" = x"-" ]
then
	$ECHO "Install directory path cannot start with \"-\""
	exit 22
elif [ x"$INSTALL_DIR" = x"/" ]
then
	$ECHO "Install directory path cannot be \"/\""
	exit 22
fi

if [ x"$SPL_BRANCH" = x"default" ]
then
	SPL_BRANCH="$BRANCH"
fi

if [ x"$ZFS_BRANCH" = x"default" ]
then
	ZFS_BRANCH="$BRANCH"
fi

XCODE=/Applications/Xcode.app
XCODE_SDKS=$XCODE/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs
XCODE_ML_SDK="$XCODE_SDKS/MacOSX10.8.sdk"
XCODE_MAV_SDK="$XCODE_SDKS/MacOSX10.9.sdk"
XCODE_YOS_SDK="$XCODE_SDKS/MacOSX10.10.sdk"
KERNEL_FRAMEWORK_PATH=/System/Library/Frameworks/Kernel.framework
ML_HEADERS=$XCODE_ML_SDK$KERNEL_FRAMEWORK_PATH
MAV_HEADERS=$XCODE_MAV_SDK$KERNEL_FRAMEWORK_PATH
YOS_HEADERS=$XCODE_YOS_SDK$KERNEL_FRAMEWORK_PATH

SPL_CONFIGURE_ARRAY=(CC=clang)
SPL_CONFIGURE_ARRAY+=(CXX=clang++)
SPL_CONFIGURE_ARRAY+=(--prefix=/usr)
SPL_CONFIGURE_ARRAY+=(--sysconfdir=/etc)
SPL_CONFIGURE_ARRAY+=(${INSTALL_DIR:+--with-kernel-modprefix="$INSTALL_DIR"})
ZFS_CONFIGURE_ARRAY=(CC=clang)
ZFS_CONFIGURE_ARRAY+=(CXX=clang++)
ZFS_CONFIGURE_ARRAY+=(--prefix=/usr)
ZFS_CONFIGURE_ARRAY+=(--sysconfdir=/etc)
ZFS_CONFIGURE_ARRAY+=(${SPL_REPOSITORY_DIR:+--with-spl="$SPL_REPOSITORY_DIR"})
ZFS_CONFIGURE_ARRAY+=(${INSTALL_DIR:+--with-kernel-modprefix="$INSTALL_DIR"})

CFLAGS_ARRAY=(-g)
CFLAGS_ARRAY+=(-Wno-tautological-constant-out-of-range-compare)

if [ x"$TARGET_OS_X_VERSION" = x"10.8" ]
then
	CFLAGS_ARRAY+=(-mmacosx-version-min=10.8)
	SPL_CONFIGURE_ARRAY+=\
(${ML_HEADERS:+--with-kernel-headers="$ML_HEADERS"})
	ZFS_CONFIGURE_ARRAY+=\
(${ML_HEADERS:+--with-kernelsrc="$ML_HEADERS"})
elif [ x"$TARGET_OS_X_VERSION" = x"10.9" ]
then
	CFLAGS_ARRAY+=(-mmacosx-version-min=10.9)
	SPL_CONFIGURE_ARRAY+=\
(${MAV_HEADERS:+--with-kernel-headers="$MAV_HEADERS"})
	ZFS_CONFIGURE_ARRAY+=\
(${MAV_HEADERS:+--with-kernelsrc="$MAV_HEADERS"})
elif [ x"$TARGET_OS_X_VERSION" = x"10.10" ]
then
	CFLAGS_ARRAY+=(-mmacosx-version-min=10.10)
	SPL_CONFIGURE_ARRAY+=\
(${YOS_HEADERS:+--with-kernel-headers="$YOS_HEADERS"})
	ZFS_CONFIGURE_ARRAY+=\
(${YOS_HEADERS:+--with-kernelsrc="$YOS_HEADERS"})
elif [ x"$TARGET_OS_X_VERSION" != x"native" ]
then
	$ECHO "target should be '10.8', '10.9', '10.10', or 'native'"
	exit 22
fi

if [ x"$PULL" != x"on" -a x"$PULL" != x"off" ]
then
	$ECHO "pull must be either 'on' or 'off'"
	exit 22
fi

if [ -d "$SPL_REPOSITORY_DIR" ]
then
	set +e
	CURRENT_SPL_BRANCH="$($GIT --git-dir="$SPL_REPOSITORY_DIR"/.git rev-parse\
	    --abbrev-ref HEAD)"
	set -e
fi

if [ -d "$ZFS_REPOSITORY_DIR" ]
then
	set +e
	CURRENT_ZFS_BRANCH="$($GIT --git-dir="$ZFS_REPOSITORY_DIR"/.git rev-parse\
	    --abbrev-ref HEAD)"
	set -e
fi

if [ x"$CURRENT_SPL_BRANCH" != x"$SPL_BRANCH" ]
then
	SPL_BRANCH_MATCHES_CURRENT_SPL_BRANCH="no"
else
	SPL_BRANCH_MATCHES_CURRENT_SPL_BRANCH="yes"
fi

if [ x"$CURRENT_ZFS_BRANCH" != x"$ZFS_BRANCH" ]
then
	ZFS_BRANCH_MATCHES_CURRENT_ZFS_BRANCH="no"
else
	ZFS_BRANCH_MATCHES_CURRENT_ZFS_BRANCH="yes"
fi

SHOULD_SWITCH_BRANCH="no"
SHOULD_SWITCH_SPL_BRANCH="no"
SHOULD_SWITCH_ZFS_BRANCH="no"
SHOULD_LOAD="no"
SHOULD_UNLOAD="no"
SHOULD_CONFIGURE="yes"
SHOULD_MAKE="yes"
MUST_SKIP_CONFIGURE_AND_MAKE="no"
DRY_RUN="no"
ONE_OF_CONFIGURE_AND_MAKE_SPECIFIED="no"
BOTH_CONFIGURE_AND_MAKE_SPECIFIED="no"
DISPLAY_HELP="no"
RUBY_OPTION_PARSING_ERROR="no"
SHOULD_INSTALL="no"

while getopts "bszlukcmtpnhe" opt
do
	case $opt
	in
		b)
			#$ECHO "-b was triggered!" >&2
			if [ "$SPL_BRANCH_MATCHES_CURRENT_SPL_BRANCH" = "no" ]
			then
				SHOULD_SWITCH_SPL_BRANCH="yes"
			fi
			if [ "$ZFS_BRANCH_MATCHES_CURRENT_ZFS_BRANCH" = "no" ]
			then
				SHOULD_SWITCH_ZFS_BRANCH="yes"
			fi
			;;
		s)
			#$ECHO "-s was triggered!" >&2
			if [ "$SPL_BRANCH_MATCHES_CURRENT_SPL_BRANCH" = "no" ]
			then
				SHOULD_SWITCH_SPL_BRANCH="yes"
			fi
			;;
		z)
			#$ECHO "-z was triggered!" >&2
			if [ "$ZFS_BRANCH_MATCHES_CURRENT_ZFS_BRANCH" = "no" ]
			then
				SHOULD_SWITCH_ZFS_BRANCH="yes"
			fi
			;;
		l)
			#$ECHO "-l was triggered!" >&2
			SHOULD_INSTALL="yes"
			SHOULD_LOAD="yes"
			;;
		u)
			#$ECHO "-u was triggered!" >&2
			SHOULD_UNLOAD="yes"
			SHOULD_LOAD="no"
			SHOULD_CONFIGURE="no"
			SHOULD_MAKE="no"
			;;
		k)
			#$ECHO "-k was triggered!" >&2
			MUST_SKIP_CONFIGURE_AND_MAKE="yes"
			SHOULD_INSTALL="yes"
			SHOULD_LOAD="yes"
			;;
		c)
			#$ECHO "-c was triggered!" >&2
			SHOULD_CONFIGURE="yes"
			SHOULD_MAKE="no"
			if [ "$ONE_OF_CONFIGURE_AND_MAKE_SPECIFIED" = "yes" ]
			then
				BOTH_CONFIGURE_AND_MAKE_SPECIFIED="yes"
			fi
			ONE_OF_CONFIGURE_AND_MAKE_SPECIFIED="yes"
			;;
		m)
			#$ECHO "-m was triggered!" >&2
			SHOULD_MAKE="yes"
			SHOULD_CONFIGURE="no"
			if [ "$ONE_OF_CONFIGURE_AND_MAKE_SPECIFIED" = "yes" ]
			then
				BOTH_CONFIGURE_AND_MAKE_SPECIFIED="yes"
			fi
			ONE_OF_CONFIGURE_AND_MAKE_SPECIFIED="yes"
			;;
		t)
			#$ECHO "-t was triggered!" >&2
			;;
		p)
			#$ECHO "-p was triggered!" >&2
			;;
		n)
			#$ECHO "-n was triggered!" >&2
			DRY_RUN="yes"
			;;
		h)
			#$ECHO "-h was triggered!" >&2
			DISPLAY_HELP="yes"
			;;
		e)
			#$ECHO "-e was triggered!" >&2
			RUBY_OPTION_PARSING_ERROR="yes"
			;;
		\?)
			$ECHO "Invalid option: -$OPTARG" >&2
			;;
	esac
done

if [ "$BOTH_CONFIGURE_AND_MAKE_SPECIFIED" = "yes" ]
then
	SHOULD_MAKE="yes"
	SHOULD_CONFIGURE="yes"
fi

if [ "$MUST_SKIP_CONFIGURE_AND_MAKE" = "yes" ]
then
	SHOULD_MAKE="no"
	SHOULD_CONFIGURE="no"
fi

if [ "$SHOULD_LOAD" = "yes" ]
then
	SHOULD_UNLOAD="yes"
	SHOULD_INSTALL="yes"
fi

if [ "$SHOULD_CONFIGURE" = "no" ]
then
	SHOULD_CLEAN="no"
fi

SK="$INSTALL_DIR"/spl.kext
ZK="$INSTALL_DIR"/zfs.kext
SPL_KEXT_RELPATH=module/spl/spl.kext
ZFS_KEXT_RELPATH=module/zfs/zfs.kext

if [ "$SHOULD_SWITCH_SPL_BRANCH" = "no" ]
then
	SPL_BRANCH_CHANGE_STATUS="no change"
else
	SPL_BRANCH_CHANGE_STATUS="changing spl branch to $SPL_BRANCH"
fi

if [ "$SHOULD_SWITCH_ZFS_BRANCH" = "no" ]
then
	ZFS_BRANCH_CHANGE_STATUS="no change"
else
	ZFS_BRANCH_CHANGE_STATUS="changing zfs branch to $ZFS_BRANCH"
fi

if [ "$SHOULD_SWITCH_SPL_BRANCH" = "yes"\
    -a "$SHOULD_SWITCH_ZFS_BRANCH" = "yes" ]
then
	BRANCH_CHANGE_STATUS="changing spl and zfs branches"
elif [ "$SHOULD_SWITCH_SPL_BRANCH" = "yes" ]
then
	BRANCH_CHANGE_STATUS="changing spl branch"
elif [ "$SHOULD_SWITCH_ZFS_BRANCH" = "yes" ]
then
	BRANCH_CHANGE_STATUS="changing zfs branch"

else
	BRANCH_CHANGE_STATUS="no change"
fi

$PRINTF "Configuration:\n"
$PRINTF "       dev dir = %s\n" "$DEV_DIR"
$PRINTF "   install dir = %s\n" "$INSTALL_DIR"
$PRINTF "  source owner = %s\n" "$OWNER"
$PRINTF " branch status = %s\n" "$BRANCH_CHANGE_STATUS"
$PRINTF "    spl branch = %s\n" "$SPL_BRANCH_CHANGE_STATUS"
$PRINTF "    zfs branch = %s\n" "$ZFS_BRANCH_CHANGE_STATUS"
$PRINTF "    load kexts = %s\n" "$SHOULD_LOAD"
$PRINTF "  unload kexts = %s\n" "$SHOULD_UNLOAD"
$PRINTF "    kexts only = %s\n" "$MUST_SKIP_CONFIGURE_AND_MAKE"
$PRINTF " run configure = %s\n" "$SHOULD_CONFIGURE"
$PRINTF "      run make = %s\n" "$SHOULD_MAKE"
$PRINTF " install kexts = %s\n" "$SHOULD_INSTALL"
$PRINTF "       spl dir = %s\n" "$SPL_REPOSITORY_DIR"
$PRINTF "       zfs dir = %s\n" "$ZFS_REPOSITORY_DIR"
$PRINTF "  spl kext dir = %s\n" "$SK"
$PRINTF "  zfs kext dir = %s\n" "$ZK"
$PRINTF "   install dir = %s\n" "$INSTALL_DIR"
$PRINTF "target version = %s\n" "$TARGET_OS_X_VERSION"
$PRINTF "          pull = %s\n" "$PULL"
$PRINTF "\n"

if [ "$RUBY_OPTION_PARSING_ERROR" = "yes" ]
then
	$ECHO "Error parsing your options. Perhaps try --help."
	exit 22
fi

if [ "$DISPLAY_HELP" = "yes" ]
then
	$PRINTF " %s\t\t%s\n" "Short options:" "Long options:"
	$PRINTF "\t%s\t\t\t%s\n" '-d' '--dev-dir=[~/Developer]'
	$PRINTF "\t%s\t\t\t%s\n" '-i' '--install-dir=[~/Library/Extensions]'
	$PRINTF "\t%s\t\t\t%s\n" '-o' '--owner=[$USER]'
	$PRINTF "\t%s\t\t\t%s\n" '-b' '--branch=[no change]'
	$PRINTF "\t%s\t\t\t%s\n" '-s' '--spl-branch=[no change]'
	$PRINTF "\t%s\t\t\t%s\n" '-z' '--zfs-branch=[no change]'
	$PRINTF "\t%s\t\t\t%s\n" '-l' '--load'
	$PRINTF "\t%s\t\t\t%s\n" '-u' '--unload'
	$PRINTF "\t%s\t\t\t%s\n" '-k' '--kexts-only'
	$PRINTF "\t%s\t\t\t%s\n" '-c' '--configure'
	$PRINTF "\t%s\t\t\t%s\n" '-m' '--make'
	$PRINTF "\t%s\t\t\t%s\n" '-t' '--target=[native]'
	$PRINTF "\t%s\t\t\t%s\n" '-p' '--pull=[on]'
	$PRINTF "\t%s\t\t\t%s\n" '-n' '--dry-run'
	$PRINTF "\t%s\t\t\t%s\n" '-h' '--help'
	exit 0
fi

if [ "$DRY_RUN" = "yes" ]
then
	$ECHO "Dry run. Exiting."
	exit 0
fi

if [ "$SHOULD_UNLOAD" = "yes" ]
then
	if [ $($KEXTSTAT -b net.lundman.zfs | wc -l) -gt 1 ]
	then
		$PRINTF "\nUnloading zfs.kext..."
		$SUDO $KEXTUNLOAD -b net.lundman.zfs
	fi
	if [ $($KEXTSTAT -b net.lundman.spl | wc -l) -gt 1 ]
	then
		$PRINTF "\nUnloading spl.kext..."
		$SUDO $KEXTUNLOAD -b net.lundman.spl
	fi
	set +e
	$SUDO $KEXTSTAT | $GREP lundman
	set -e
fi

if [ "$SHOULD_CONFIGURE" = "no"\
    -a "$SHOULD_MAKE" = "no"\
    -a "$SHOULD_LOAD" = "no" ]
then
	exit 0
fi

if [ "$SHOULD_CONFIGURE" = "yes"\
    -o "$SHOULD_MAKE" = "yes" ]
then
	if [ ! -d "$DEV_DIR" ]
	then
		$SUDO $MKDIR -p "$DEV_DIR"
		$SUDO $CHOWN "$OWNER":staff "$DEV_DIR"
	fi
	if [ ! -d "$SPL_REPOSITORY_DIR" ]
	then
		$SUDO $MKDIR -p "$SPL_REPOSITORY_DIR"
		cd "$SPL_REPOSITORY_DIR"/..
		$SUDO $RMDIR "$SPL_REPOSITORY_DIR"
		$SUDO $GIT clone "$SPL_REPOSITORY_URL" "$SPL_REPOSITORY_DIR"
		cd "$SPL_REPOSITORY_DIR"
		cd ..
		$SUDO $CHOWN -R "$OWNER":staff "$SPL_REPOSITORY_DIR"
	else
		$SUDO $CHOWN -R "$OWNER":staff "$SPL_REPOSITORY_DIR"
		cd "$SPL_REPOSITORY_DIR"
	fi
	if [ ! -d "$ZFS_REPOSITORY_DIR" ]
	then
		$SUDO $MKDIR -p "$ZFS_REPOSITORY_DIR"
		cd "$ZFS_REPOSITORY_DIR"/..
		$SUDO $RMDIR "$ZFS_REPOSITORY_DIR"
		$SUDO $GIT clone "$ZFS_REPOSITORY_URL" "$ZFS_REPOSITORY_DIR"
		cd "$ZFS_REPOSITORY_DIR"
		cd ..
		$SUDO $CHOWN -R "$OWNER":staff "$ZFS_REPOSITORY_DIR"
	else
		$SUDO $CHOWN -R "$OWNER":staff "$ZFS_REPOSITORY_DIR"
		cd "$ZFS_REPOSITORY_DIR"
	fi
fi

SWITCHED_SPL_BRANCH="no"
if [ "$SHOULD_SWITCH_SPL_BRANCH" = "yes" ]
then

	CURRENT_SPL_BRANCH="$($GIT --git-dir="$DEV_DIR"/spl/.git rev-parse\
	    --abbrev-ref HEAD)"

	SPL_BRANCH_MATCHES="no"

	if [ x"$CURRENT_SPL_BRANCH" = x"$SPL_BRANCH" ]
	then
		SPL_BRANCH_MATCHES="yes"
		$ECHO "spl branch already matches."
	else
		$ECHO "spl branch does not match."
	fi
	if [ "$SPL_BRANCH_MATCHES" = "no" ]
	then
		cd "$SPL_REPOSITORY_DIR"
		$ECHO "Trying to switch spl branch ..."
		if [ x"$SHOULD_CLEAN" = x"yes" ]
		then
			$GIT reset --hard @{u}
			$GIT clean -fdqx
		fi
		$SUDO -u "$OWNER" $GIT checkout "$SPL_BRANCH"
		if [ $? -eq 0 ]
		then
			SWITCHED_SPL_BRANCH="yes"
			$ECHO "Switched spl branch."
		else
			$ECHO "Did not switch spl branch."
		fi
	fi
fi

SWITCHED_ZFS_BRANCH="no"
if [ "$SHOULD_SWITCH_ZFS_BRANCH" = "yes" ]
then

	CURRENT_ZFS_BRANCH="$($GIT --git-dir="$DEV_DIR"/zfs/.git rev-parse\
	    --abbrev-ref HEAD)"

	ZFS_BRANCH_MATCHES="no"

	if [ x"$CURRENT_ZFS_BRANCH" = x"$ZFS_BRANCH" ]
	then
		ZFS_BRANCH_MATCHES="yes"
		$ECHO "zfs branch already matches."
	else
		$ECHO "zfs branch does not match."
	fi
	if [ "$ZFS_BRANCH_MATCHES" = "no" ]
	then
		cd "$ZFS_REPOSITORY_DIR"
		$ECHO "Trying to switch zfs branch ..."
		if [ x"$SHOULD_CLEAN" = x"yes" ]
		then
			$GIT reset --hard @{u}
			$GIT clean -fdqx
		fi
		$SUDO -u "$OWNER" $GIT checkout "$ZFS_BRANCH"
		if [ $? -eq 0 ]
		then
			SWITCHED_ZFS_BRANCH="yes"
			$ECHO "Switched zfs branch."
		else
			$ECHO "Did not switch zfs branch."
		fi
	fi
fi

if [ x"$SHOULD_CLEAN" = x"yes" ]
then
	cd "$SPL_REPOSITORY_DIR"
	$GIT reset --hard @{u}
	$GIT clean -fdqx
	if [ x"$PULL" = x"on" ]
	then
		$SUDO -u "$OWNER" $GIT pull
	fi
	cd "$ZFS_REPOSITORY_DIR"
	$GIT reset --hard @{u}
	$GIT clean -fdqx
	if [ x"$PULL" = x"on" ]
	then
		$SUDO -u "$OWNER" $GIT pull
	fi
else
	if [ x"$PULL" = x"on" ]
	then
		cd "$SPL_REPOSITORY_DIR"
		$SUDO -u "$OWNER" $GIT pull
		cd "$ZFS_REPOSITORY_DIR"
		$SUDO -u "$OWNER" $GIT pull
	fi
fi

if [ "$SHOULD_CONFIGURE" = "yes" ]
then
	CFLAGS_STRING=${CFLAGS_ARRAY[*]}
	cd "$SPL_REPOSITORY_DIR"
	if [ x"$TARGET_OS_X_VERSION" = x"10.8" ]
	then
		[ -e "${ML_SPL_DIFF}" ] && $GIT apply "${ML_SPL_DIFF}"
	else
		[ -e "${MAV_SPL_DIFF}" ] && $GIT apply "${MAV_SPL_DIFF}"
	fi
	$SUDO -u "$OWNER" $BASH_PATH "$SPL_REPOSITORY_DIR"/autogen.sh
	$SUDO -u "$OWNER" $BASH_PATH "$SPL_REPOSITORY_DIR"/configure\
	    ${CFLAGS_STRING:+CFLAGS="$CFLAGS_STRING"}\
	    ${SPL_CONFIGURE_ARRAY[@]}
	cd "$ZFS_REPOSITORY_DIR"
	if [ x"$TARGET_OS_X_VERSION" = x"10.8" ]
	then
		[ -e "${ML_ZFS_DIFF}" ] && $GIT apply "${ML_ZFS_DIFF}"
	else
		[ -e "${MAV_ZFS_DIFF}" ] && $GIT apply "${MAV_ZFS_DIFF}"
	fi
	$SUDO -u "$OWNER" $BASH_PATH "$ZFS_REPOSITORY_DIR"/autogen.sh
	$SUDO -u "$OWNER" $BASH_PATH "$ZFS_REPOSITORY_DIR"/configure\
	    ${CFLAGS_STRING:+CFLAGS="$CFLAGS_STRING"}\
	    ${ZFS_CONFIGURE_ARRAY[@]}
fi

if [ "$SHOULD_MAKE" = "yes" ]
then
	cd "$SPL_REPOSITORY_DIR"
	$SUDO -u "$OWNER" $MAKE -j"$JOBS"
	cd "$ZFS_REPOSITORY_DIR"
	$SUDO -u "$OWNER" $MAKE -j"$JOBS"
fi

if [ "$SHOULD_CONFIGURE" = "no" ]
then
	$PRINTF "\nDid not run configure.\n"
fi

if [ "$SHOULD_MAKE" = "no" ]
then
	$PRINTF "\nDid not run make.\n"
fi

if [ "$SHOULD_INSTALL" = "yes" ]
then
	$SUDO $MKDIR -p "$SK"
	$SUDO $MKDIR -p "$ZK"
	do_rsync "$SPL_REPOSITORY_DIR"/"$SPL_KEXT_RELPATH"/ "$SK"/
	do_rsync "$ZFS_REPOSITORY_DIR"/"$ZFS_KEXT_RELPATH"/ "$ZK"/
	$SUDO $CHOWN -R root:wheel "$SK"
	$SUDO $CHOWN -R root:wheel "$ZK"
fi

if [ "$SHOULD_LOAD" = "yes" ]
then
	$PRINTF "\nLoading spl.kext...\n"
	$SUDO $KEXTLOAD "$SK"
	$PRINTF "\nLoading zfs.kext...\n\n"
	$SUDO $KEXTLOAD -d "$SK" "$ZK"
	set +e
	$SUDO $KEXTSTAT | $GREP lundman
	set -e
else
	$PRINTF "\nIf you want to load the kernel extensions, "
	$PRINTF "you must specify '-l' or '-k'\n\n"
fi

EndOfBash
) | $BASH_PATH

exit 0

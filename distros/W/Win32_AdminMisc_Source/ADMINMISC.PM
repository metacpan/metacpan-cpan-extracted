package Win32::AdminMisc;

#
#AdminMisc.pm
#   By Dave Roth <rothd@roth.net>
#   Courtesy of Roth Consulting
#   http://www.roth.net/consult
#   Some code borrowed from Win32::NetAdmin by ActiveState Inc.

require Exporter;
require DynaLoader;

$Package = "Win32::AdminMisc";
 
die "The $Package module works only on Windows NT" if (!Win32::IsWinNT() );

@ISA= qw( Exporter DynaLoader );
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
    LOGON32_LOGON_INTERACTIVE
    LOGON32_LOGON_BATCH
    LOGON32_LOGON_SERVICE
    LOGON32_LOGON_NETWORK

    FILTER_TEMP_DUPLICATE_ACCOUNT
    FILTER_NORMAL_ACCOUNT
    FILTER_INTERDOMAIN_TRUST_ACCOUNT
    FILTER_WORKSTATION_TRUST_ACCOUNT
    FILTER_SERVER_TRUST_ACCOUNT
    UF_TEMP_DUPLICATE_ACCOUNT
    UF_NORMAL_ACCOUNT
    UF_INTERDOMAIN_TRUST_ACCOUNT
    UF_WORKSTATION_TRUST_ACCOUNT
    UF_SERVER_TRUST_ACCOUNT
    UF_MACHINE_ACCOUNT_MASK
    UF_ACCOUNT_TYPE_MASK
    UF_DONT_EXPIRE_PASSWD
    UF_SETTABLE_BITS
    UF_SCRIPT
    UF_ACCOUNTDISABLE
    UF_HOMEDIR_REQUIRED
    UF_LOCKOUT
    UF_PASSWD_NOTREQD
    UF_PASSWD_CANT_CHANGE
    USE_FORCE
    USE_LOTS_OF_FORCE
    USE_NOFORCE
    USER_PRIV_MASK
    USER_PRIV_GUEST
    USER_PRIV_USER
    USER_PRIV_ADMIN

    USER_NAME
    USER_PASSWORD
    USER_PASSWORD_AGE
    USER_PRIV
    USER_HOME_DIR
    USER_COMMENT
    USER_SCRIPT_PATH
    USER_AUTH_FLAGS
    USER_FULL_NAME
    USER_COMMENT
    USER_PARMS
    USER_WORKSTATIONS
    USER_LAST_LOGON
    USER_LAST_LOGOFF
    USER_ACCT_EXPIRES
    USER_MAX_STORAGE
    USER_UNITS_PER_WEEK
    USER_LOGON_HOURS
    USER_BAD_PW_COUNT
    USER_NUM_LOGONS
    USER_LOGON_SERVER
    USER_COUNTRY_CODE
    USER_CODE_PAGE
    USER_USER_ID
    USER_PRIMARY_GROUP_ID
    USER_PROFILE
    USER_HOME_DIR
    USER_HOME_DIR_DRIVE
    USER_PASSWORD_EXPIRED

    DRIVE_REMOVABLE
    DRIVE_FIXED
    DRIVE_REMOTE
    DRIVE_CDROM
    DRIVE_RAMDISK


    EWX_LOGOFF
    EWX_FORCE
    EWX_POWEROFF
    EWX_REBOOT
    EWX_SHUTDOWN

    STARTF_USESHOWWINDOW
    STARTF_USEPOSITION
    STARTF_USESIZE
    STARTF_USECOUNTCHARS
    STARTF_USEFILLATTRIBUTE
    STARTF_FORCEONFEEDBACK
    STARTF_FORCEOFFFEEDBACK
    STARTF_USESTDHANDLES

    CREATE_DEFAULT_ERROR_MODE
    CREATE_NEW_CONSOLE
    CREATE_NEW_PROCESS_GROUP
    CREATE_SEPARATE_WOW_VDM
    CREATE_SUSPENDED
    CREATE_UNICODE_ENVIRONMENT
    DEBUG_PROCESS
    DEBUG_ONLY_THIS_PROCESS
    DETACHED_PROCESS;

    HIGH_PRIORITY_CLASS
    IDLE_PRIORITY_CLASS
    NORMAL_PRIORITY_CLASS
    REALTIME_PRIORITY_CLASS

    SW_HIDE
    SW_MAXIMIZE
    SW_MINIMIZE
    SW_RESTORE
    SW_SHOW
    SW_SHOWDEFAULT
    SW_SHOWMAXIMIZED
    SW_SHOWMINIMIZED
    SW_SHOWMINNOACTIVE
    SW_SHOWNA
    SW_SHOWNOACTIVATE
    SW_SHOWNORMAL

    STD_INPUT_HANDLE
    STD_OUTPUT_HANDLE
    STD_ERROR_HANDLE

    FOREGROUND_RED
    FOREGROUND_BLUE
    FOREGROUND_GREEN
    FOREGROUND_INTENSITY
    BACKGROUND_RED
    BACKGROUND_BLUE
    BACKGROUND_GREEN
    BACKGROUND_INTENSITY

    MONDAY
    TUESDAY
    WEDNESDAY
    THURSDAY
    FRIDAY
    SATURDAY
    SUNDAY
    JOB_ADD_CURRENT_DATE
    JOB_RUN_PERIODICALLY
    JOB_EXEC_ERROR
    JOB_RUNS_TODAY
    JOB_NONINTERACTIVE

    ENV_SYSTEM
    ENV_USER

    GROUP_TYPE_ALL
    GROUP_TYPE_LOCAL
    GROUP_TYPE_GLOBAL
);



sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    local($constname);
    ($constname = $AUTOLOAD) =~ s/.*:://;
    #reset $! to zero to reset any current errors.
    $!=0;
    $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
        if ($! =~ /Invalid/) {
            $AutoLoader::AUTOLOAD = $AUTOLOAD;
            goto &AutoLoader::AUTOLOAD;
        }else{
            ($file,$line) = caller[2..3];
            die "Your vendor has not defined $Package macro $constname, used in $file at line $line.";
        }
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap $Package;

$Version = eval( $Package . "::GetVersion();" );

# Preloaded methods go here.

# Autoload methods go after __END__, and are processed by the autosplit program.

1;
__END__











package # hide from PAUSE
        Win32::Process;
use strict;
use warnings;

{
    no strict;
    $VERSION = "0.01";
    @ISA = qw(Exporter);
    @EXPORT = qw(
        CREATE_DEFAULT_ERROR_MODE
        CREATE_NEW_CONSOLE
        CREATE_NEW_PROCESS_GROUP
        CREATE_NO_WINDOW
        CREATE_SEPARATE_WOW_VDM
        CREATE_SUSPENDED
        CREATE_UNICODE_ENVIRONMENT
        DEBUG_ONLY_THIS_PROCESS
        DEBUG_PROCESS
        DETACHED_PROCESS
        HIGH_PRIORITY_CLASS
        IDLE_PRIORITY_CLASS
        INFINITE
        NORMAL_PRIORITY_CLASS
        REALTIME_PRIORITY_CLASS
        THREAD_PRIORITY_ABOVE_NORMAL
        THREAD_PRIORITY_BELOW_NORMAL
        THREAD_PRIORITY_ERROR_RETURN
        THREAD_PRIORITY_HIGHEST
        THREAD_PRIORITY_IDLE
        THREAD_PRIORITY_LOWEST
        THREAD_PRIORITY_NORMAL
        THREAD_PRIORITY_TIME_CRITICAL
    );

    @EXPORT_OK = qw(
        STILL_ACTIVE
    );
}

*get_Win32_IPC_HANDLE = \&get_process_handle;


# 
# Create()
# ------
sub Create {
    my ($obj_r, $appname, $cmdline, $iflags, $cflags, $curdir) = @_;
    # XXX
}


# 
# Open()
# ----
sub Open {
    my ($obj_r, $pid, $iflags) = @_;
    # XXX
}


# 
# KillProcess()
# -----------
sub KillProcess {
    my ($pid, $exitcode) = @_;
    # XXX
}


# 
# Suspend()
# -------
sub Suspend {
    my ($obj) = @_;
    # XXX
}


# 
# Resume()
# ------
sub Resume {
    my ($obj) = @_;
    # XXX
}


# 
# Kill()
# ----
sub Kill {
    my ($obj, $exitcode) = @_;
    # XXX
}


# 
# GetPriorityClass()
# ----------------
sub GetPriorityClass {
    my ($obj, $class) = @_;
    # XXX
}


# 
# SetPriorityClass()
# ----------------
sub SetPriorityClass {
    my ($obj, $class) = @_;
    # XXX
}


# 
# GetProcessAffinityMask()
# ----------------------
sub GetProcessAffinityMask {
    my ($obj, $procmask, $systmask) = @_;
    # XXX
}


# 
# SetProcessAffinityMask()
# ----------------------
sub SetProcessAffinityMask {
    my ($obj, $procmask) = @_;
    # XXX
}


# 
# GetExitCode()
# -----------
sub GetExitCode {
    my ($obj, $exitcode) = @_;
    # XXX
}


# 
# Wait()
# ----
sub Wait {
    my ($obj, $timeout) = @_;
    # XXX
}


# 
# GetProcessID()
# ------------
sub GetProcessID {
    my ($obj) = @_;
    # XXX
    return 0
}


# 
# GetCurrentProcessID()
# -------------------
sub GetCurrentProcessID {
    return $$
}


1

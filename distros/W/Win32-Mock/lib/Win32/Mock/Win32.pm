package # hide from PAUSE
        Win32;
use strict;
use warnings;
use Config;
use Exporter ();
use File::Spec;
use File::Spec::Functions;

{
    no strict;
    $VERSION = '0.01';
    @ISA = qw|Exporter|;

    @EXPORT = qw(
        NULL
        WIN31_CLASS
        OWNER_SECURITY_INFORMATION
        GROUP_SECURITY_INFORMATION
        DACL_SECURITY_INFORMATION
        SACL_SECURITY_INFORMATION
        MB_ICONHAND
        MB_ICONQUESTION
        MB_ICONEXCLAMATION
        MB_ICONASTERISK
        MB_ICONWARNING
        MB_ICONERROR
        MB_ICONINFORMATION
        MB_ICONSTOP
    );
    @EXPORT_OK = qw(
        GetOSName
        SW_HIDE
        SW_SHOWNORMAL
        SW_SHOWMINIMIZED
        SW_SHOWMAXIMIZED
        SW_SHOWNOACTIVATE

        CSIDL_DESKTOP
        CSIDL_PROGRAMS
        CSIDL_PERSONAL
        CSIDL_FAVORITES
        CSIDL_STARTUP
        CSIDL_RECENT
        CSIDL_SENDTO
        CSIDL_STARTMENU
        CSIDL_MYMUSIC
        CSIDL_MYVIDEO
        CSIDL_DESKTOPDIRECTORY
        CSIDL_NETHOOD
        CSIDL_FONTS
        CSIDL_TEMPLATES
        CSIDL_COMMON_STARTMENU
        CSIDL_COMMON_PROGRAMS
        CSIDL_COMMON_STARTUP
        CSIDL_COMMON_DESKTOPDIRECTORY
        CSIDL_APPDATA
        CSIDL_PRINTHOOD
        CSIDL_LOCAL_APPDATA
        CSIDL_COMMON_FAVORITES
        CSIDL_INTERNET_CACHE
        CSIDL_COOKIES
        CSIDL_HISTORY
        CSIDL_COMMON_APPDATA
        CSIDL_WINDOWS
        CSIDL_SYSTEM
        CSIDL_PROGRAM_FILES
        CSIDL_MYPICTURES
        CSIDL_PROFILE
        CSIDL_PROGRAM_FILES_COMMON
        CSIDL_COMMON_TEMPLATES
        CSIDL_COMMON_DOCUMENTS
        CSIDL_COMMON_ADMINTOOLS
        CSIDL_ADMINTOOLS
        CSIDL_COMMON_MUSIC
        CSIDL_COMMON_PICTURES
        CSIDL_COMMON_VIDEO
        CSIDL_RESOURCES
        CSIDL_RESOURCES_LOCALIZED
        CSIDL_CDBURN_AREA
    );
}

# mock up the environment
$ENV{WINDIR} = catdir(rootdir(), "opt", "Win32");
$ENV{SYSTEMROOT} = catdir($ENV{WINDIR}, "System");
$ENV{PROCESSOR_ARCHITECTURE} = $Config{archname};

# constants, copied from Win32.pm
sub NULL                        { 0 }
sub WIN31_CLASS                 { &NULL }

sub OWNER_SECURITY_INFORMATION  { 0x00000001 }
sub GROUP_SECURITY_INFORMATION  { 0x00000002 }
sub DACL_SECURITY_INFORMATION   { 0x00000004 }
sub SACL_SECURITY_INFORMATION   { 0x00000008 }

sub MB_ICONHAND                 { 0x00000010 }
sub MB_ICONQUESTION             { 0x00000020 }
sub MB_ICONEXCLAMATION          { 0x00000030 }
sub MB_ICONASTERISK             { 0x00000040 }
sub MB_ICONWARNING              { 0x00000030 }
sub MB_ICONERROR                { 0x00000010 }
sub MB_ICONINFORMATION          { 0x00000040 }
sub MB_ICONSTOP                 { 0x00000010 }

sub SW_HIDE           ()        { 0 }
sub SW_SHOWNORMAL     ()        { 1 }
sub SW_SHOWMINIMIZED  ()        { 2 }
sub SW_SHOWMAXIMIZED  ()        { 3 }
sub SW_SHOWNOACTIVATE ()        { 4 }

sub CSIDL_DESKTOP              ()       { 0x0000 }     # <desktop>
sub CSIDL_PROGRAMS             ()       { 0x0002 }     # Start Menu\Programs
sub CSIDL_PERSONAL             ()       { 0x0005 }     # "My Documents" folder
sub CSIDL_FAVORITES            ()       { 0x0006 }     # <user name>\Favorites
sub CSIDL_STARTUP              ()       { 0x0007 }     # Start Menu\Programs\Startup
sub CSIDL_RECENT               ()       { 0x0008 }     # <user name>\Recent
sub CSIDL_SENDTO               ()       { 0x0009 }     # <user name>\SendTo
sub CSIDL_STARTMENU            ()       { 0x000B }     # <user name>\Start Menu
sub CSIDL_MYMUSIC              ()       { 0x000D }     # "My Music" folder
sub CSIDL_MYVIDEO              ()       { 0x000E }     # "My Videos" folder
sub CSIDL_DESKTOPDIRECTORY     ()       { 0x0010 }     # <user name>\Desktop
sub CSIDL_NETHOOD              ()       { 0x0013 }     # <user name>\nethood
sub CSIDL_FONTS                ()       { 0x0014 }     # windows\fonts
sub CSIDL_TEMPLATES            ()       { 0x0015 }
sub CSIDL_COMMON_STARTMENU     ()       { 0x0016 }     # All Users\Start Menu
sub CSIDL_COMMON_PROGRAMS      ()       { 0x0017 }     # All Users\Start Menu\Programs
sub CSIDL_COMMON_STARTUP       ()       { 0x0018 }     # All Users\Startup
sub CSIDL_COMMON_DESKTOPDIRECTORY ()    { 0x0019 }     # All Users\Desktop
sub CSIDL_APPDATA              ()       { 0x001A }     # Application Data, new for NT4
sub CSIDL_PRINTHOOD            ()       { 0x001B }     # <user name>\PrintHood
sub CSIDL_LOCAL_APPDATA        ()       { 0x001C }     # non roaming, user\Local Settings\Application Data
sub CSIDL_COMMON_FAVORITES     ()       { 0x001F }
sub CSIDL_INTERNET_CACHE       ()       { 0x0020 }
sub CSIDL_COOKIES              ()       { 0x0021 }
sub CSIDL_HISTORY              ()       { 0x0022 }
sub CSIDL_COMMON_APPDATA       ()       { 0x0023 }     # All Users\Application Data
sub CSIDL_WINDOWS              ()       { 0x0024 }     # GetWindowsDirectory()
sub CSIDL_SYSTEM               ()       { 0x0025 }     # GetSystemDirectory()
sub CSIDL_PROGRAM_FILES        ()       { 0x0026 }     # C:\Program Files
sub CSIDL_MYPICTURES           ()       { 0x0027 }     # "My Pictures", new for Win2K
sub CSIDL_PROFILE              ()       { 0x0028 }     # USERPROFILE
sub CSIDL_PROGRAM_FILES_COMMON ()       { 0x002B }     # C:\Program Files\Common
sub CSIDL_COMMON_TEMPLATES     ()       { 0x002D }     # All Users\Templates
sub CSIDL_COMMON_DOCUMENTS     ()       { 0x002E }     # All Users\Documents
sub CSIDL_COMMON_ADMINTOOLS    ()       { 0x002F }     # All Users\Start Menu\Programs\Administrative Tools
sub CSIDL_ADMINTOOLS           ()       { 0x0030 }     # <user name>\Start Menu\Programs\Administrative Tools
sub CSIDL_COMMON_MUSIC         ()       { 0x0035 }     # All Users\My Music
sub CSIDL_COMMON_PICTURES      ()       { 0x0036 }     # All Users\My Pictures
sub CSIDL_COMMON_VIDEO         ()       { 0x0037 }     # All Users\My Video
sub CSIDL_RESOURCES            ()       { 0x0038 }     # %windir%\Resources\, For theme and other windows resources.
sub CSIDL_RESOURCES_LOCALIZED  ()       { 0x0039 }     # %windir%\Resources\<LangID>, for theme and other windows specific resources.
sub CSIDL_CDBURN_AREA          ()       { 0x003B }     # <user name>\Local Settings\Application Data\Microsoft\CD Burning



# 
# AbortSystemShutdown()
# -------------------
sub AbortSystemShutdown {
    # XXX: not implemented
}


# 
# BuildNumber()
# -----------
sub BuildNumber {
    return $Config{PERL_VERSION} * 100 + $Config{PERL_SUBVERSION} * 10 + $Config{PERL_REVISION}
}


# 
# CopyFile()
# --------
sub CopyFile {
    require File::Copy;
    File::Copy::copy($_[0], $_[1]);
}


# 
# CreateDirectory()
# ---------------
sub CreateDirectory {
    require File::Path;
    my $r = eval { File::Path::mkpath($_[0]) };
    $^E = $!;
    return $r
}


# 
# CreateFile()
# ----------
sub CreateFile {
    my ($file) = @_;
    return 0 if -f $file;
    require ExtUtils::Command;
    eval { local @ARGV = ($file); ExtUtils::Command::touch() };
    $^E = $!;
    return -f $file
}


# 
# DomainName()
# ----------
sub DomainName {
    return "WORKGROUP"  # that's the actual value on many hosts anyway ;)
                        # but if really needed we can try to grep smb.conf
}


# 
# ExpandEnvironmentStrings()
# ------------------------
sub ExpandEnvironmentStrings {
    my ($string) = @_;
    $string =~ s/%([^%]*)%/$ENV{$1} || "%$1%"/eg;   # copied from Win32.pm doc
    return $string
}


# 
# FormatMessage()
# -------------
sub FormatMessage {
    require POSIX;
    return POSIX::strerror($_[0])
}


# 
# FsType()
# ------
sub FsType {
    my $fstype = "RandomFS";

    if (wantarray) {
        require Cwd;
        require POSIX;
        my $cwd = Cwd::cwd();

        my $flags = 0;
        my $is_case_tolerant = eval { File::Spec->case_tolerant() } ? 1 : 0;
        $flags |= $is_case_tolerant;

        my $maxcomplen = POSIX::pathconf($cwd, &POSIX::_PC_NAME_MAX);

        return ($fstype, $flags, $maxcomplen)
    }
    else {
        return $fstype
    }
}


# 
# FreeLibrary()
# -----------
sub FreeLibrary {
    require DynaLoader;
    DynaLoader::dl_unload_file($_[0]);
}


# 
# GetANSIPathName()
# ---------------
sub GetANSIPathName {
    return $_[0]
}


# 
# GetArchName()
# -----------
sub GetArchName {
    return $Config{archname}
}


# 
# GetChipName()
# -----------
sub GetChipName {
    require POSIX;
    return "" . (POSIX::uname())[4]
}


# 
# GetCwd()
# ------
sub GetCwd {
    require Cwd;
    return Cwd::cwd()
}


# 
# GetCurrentThreadId()
# ------------------
sub GetCurrentThreadId {
    return -$$
}


# 
# GetFileVersion()
# --------------
sub GetFileVersion {
    if ($_[0] eq $^X) {
        my @version = map {int} $] =~ /^([0-9]+)\.([0-9]{3})([0-9]+)$/;
        push @version, Win32::BuildNumber();
        return wantarray ? @version : join ".", @version
    }
    return wantarray ? (0,0,0,0) : "0.0.0.0"
}


# 
# GetFolderPath()
# -------------
sub GetFolderPath {
    my ($folder, $create) = @_;
    eval "use File::HomeDir";

    my $path = '';
    my $home = eval { File::HomeDir->my_home } || (getpwuid($>))[7];

    # TODO CSIDL_DESKTOP
    # TODO CSIDL_PROGRAMS

    $folder == &CSIDL_PERSONAL
        and $path = eval { File::HomeDir->my_documents } || catdir($home, "Documents");

    # TODO CSIDL_FAVORITES
    # TODO CSIDL_STARTUP
    # TODO CSIDL_RECENT
    # TODO CSIDL_SENDTO
    # TODO CSIDL_STARTMENU

    $folder == &CSIDL_MYMUSIC
        and $path = eval { File::HomeDir->my_music } || catdir($home, "Music");

    $folder == &CSIDL_MYVIDEO
        and $path = eval { File::HomeDir->my_videos } || catdir($home, "Movies");

    $folder == &CSIDL_DESKTOPDIRECTORY
        and $path = eval { File::HomeDir->my_desktop } || catdir($home, "Desktop");

    # TODO CSIDL_NETHOOD
    # TODO CSIDL_FONTS
    # TODO CSIDL_TEMPLATES
    # TODO CSIDL_COMMON_STARTMENU
    # TODO CSIDL_COMMON_PROGRAMS
    # TODO CSIDL_COMMON_STARTUP
    # TODO CSIDL_COMMON_DESKTOPDIRECTORY
    # TODO CSIDL_APPDATA
    # TODO CSIDL_PRINTHOOD
    # TODO CSIDL_LOCAL_APPDATA
    # TODO CSIDL_COMMON_FAVORITES
    # TODO CSIDL_INTERNET_CACHE
    # TODO CSIDL_COOKIES
    # TODO CSIDL_HISTORY
    # TODO CSIDL_COMMON_APPDATA

    $folder == &CSIDL_WINDOWS and $path = $ENV{WINDIR};
    $folder == &CSIDL_SYSTEM  and $path = $ENV{SYSTEMROOT};

    # TODO CSIDL_PROGRAM_FILES

    $folder == &CSIDL_MYPICTURES
        and $path = eval { File::HomeDir->my_pictures } || catdir($home, "Pictures");

    $folder == &CSIDL_PROFILE and $path = $home;

    # TODO CSIDL_PROGRAM_FILES_COMMON
    # TODO CSIDL_COMMON_TEMPLATES
    # TODO CSIDL_COMMON_DOCUMENTS
    # TODO CSIDL_COMMON_ADMINTOOLS
    # TODO CSIDL_ADMINTOOLS
    # TODO CSIDL_COMMON_MUSIC
    # TODO CSIDL_COMMON_PICTURES
    # TODO CSIDL_COMMON_VIDEO
    # TODO CSIDL_RESOURCES
    # TODO CSIDL_RESOURCES_LOCALIZED
    # TODO CSIDL_CDBURN_AREA

    $path ||= $home;
    mkpath $path if $create;
    return $path
}


# 
# GetFullPathName()
# ---------------
sub GetFullPathName {
    require Cwd;
    my $fullpath = Cwd::abs_path($_[0]);

    if (wantarray) {
        require File::Basename;
        my ($name, $path) = File::Basename::fileparse($fullpath);
        return ($path, $name)
    }
    else {
        return $fullpath
    }
}


# 
# GetLastError()
# ------------
sub GetLastError {
    return defined $^E ? 0+$^E : 0+$!
}


# 
# GetLongPathName()
# ---------------
sub GetLongPathName {
    if (wantarray) {
        require File::Basename;
        my ($name, $path) = File::Basename::fileparse($_[0]);
        return ($path, $name)
    }
    else {
        return $_[0]
    }
}


# 
# GetNextAvailDrive()
# -----------------
sub GetNextAvailDrive {
    return "Z"  # not sure what this function should return
}


# 
# GetOSName()
# ---------
sub GetOSName {
    my ($name, $major, $minor, $build, $id) = GetOSVersion();
    my $osname = "$name-$major.$minor";
    my $desc   = "$name $major.$minor " . GetArchName();
    return wantarray ? ($osname, $desc) : $osname
}


# 
# GetOSVersion()
# ------------
sub GetOSVersion {
    my ($name, $major, $minor, $build, $id);

    require POSIX;
    my @uname = POSIX::uname();
    $name = $uname[0];
    ($major, $minor) = $uname[2] =~ /^([0-9]+)\.([0-9]+)/;
    $id = 2;

    return ($name, $major, $minor, $build, $id)
}


# 
# GetShortPathName()
# ----------------
sub GetShortPathName {
    if (wantarray) {
        require File::Basename;
        my ($name, $path) = File::Basename::fileparse($_[0]);
        return ($path, $name)
    }
    else {
        return $_[0]
    }
}


# 
# GetProcAddress()
# --------------
sub GetProcAddress {
    require DynaLoader;
    return DynaLoader::dl_find_symbol($_[0], $_[1])
}


# 
# GetTickCount()
# ------------
sub GetTickCount {
    return time()
}


# 
# GuidGen()
# -------
sub GuidGen {
    my $guid = "";

    if (eval "use Data::GUID; 1") {
        $guid = "{" . eval { Data::GUID->new } ."}"
    }
    elsif (eval "use Win32::Guidgen; 1") {
        $guid = eval { Win32::Guidgen::create() }
    }
    else {
        $guid = sprintf "{%08X-%04X-%04X-%04X-%06X%06X}" => 
                map { rand( hex("F"x$_) ) } 8, 4, 4, 4, 6,6
    }

    return $guid
}


# 
# InitiateSystemShutdown()
# ----------------------
sub InitiateSystemShutdown {
    # XXX: nahhh...
}


# 
# IsAdminUser()
# -----------
sub IsAdminUser {
    return $< == 0 ? 1 : 0
}


# 
# IsWinNT()
# -------
sub IsWinNT {
    return 1
}


# 
# IsWin95()
# -------
sub IsWin95 {
    return 0
}


# 
# LoadLibrary()
# -----------
sub LoadLibrary {
    DynaLoader::dl_load_file($_[0])
}


# 
# LoginName()
# ---------
sub LoginName {
    return "" . (getpwuid($<))[0]
}


# 
# LookupAccountName()
# -----------------
sub LookupAccountName {
    my ($system, $account, $domain, $sid, $sidtype) = @_;
    # XXX: not implement, don't know what this is
    return 
}


# 
# LookupAccountSID()
# ----------------
sub LookupAccountSID {
    my ($system, $account, $domain, $sid, $sidtype) = @_;
    # XXX: not implement, don't know what this is
    return 
}


# 
# MsgBox()
# ------
sub MsgBox {
    my ($message, $flags, $title) = @_;
    $title ||= "Perl";
    warn "[!!] $title\: $message\n";    # XXX: maybe we could use Gtk ot Wx?
    return 0
}


# 
# NodeName()
# --------
sub NodeName {
    require POSIX;
    return "" . (POSIX::uname())[1]
}


# 
# OutputDebugString()
# -----------------
sub OutputDebugString {
    print STDERR "[debug] ", @_, $/
}


# 
# RegisterServer()
# --------------
sub RegisterServer {
    # XXX: not implemented
    return 0
}


# 
# SetChildShowWindow()
# ------------------
sub SetChildShowWindow {
    # XXX: not implemented
    return 0
}


# 
# SetCwd()
# ------
sub SetCwd {
    return chdir $_[0]
}


# 
# SetLastError()
# ------------
sub SetLastError {
    $^E = $! = $_[0] 
}


# 
# Sleep()
# -----
sub Sleep {
    if (eval "use Time::HiRes; 1") {
        usleep($_[0] * 1000)
    }
    else {
        sleep($_[0] / 1000)
    }
}


# 
# Spawn()
# -----
sub Spawn {
    my ($comand, $args, $pid_r) = @_;
    return 
}


# 
# UnregisterServer()
# ----------------
sub UnregisterServer {
    # XXX: not implemented
    return 
}


1

__END__

=head1 NAME

Win32 - Mocked Win32 functions

=head1 SYNOPSIS

    use Win32::Mock;
    use Win32;

=head1 DESCRIPTION

This module is a mock/emulation of C<Win32>. 
See the documentation of the real module for more details. 

=head1 SEE ALSO

L<Win32>

L<Win32::Mock>

=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni E<lt>sebastien@aperghis.netE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 SE<eacute>bastien Aperghis-Tramoni, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

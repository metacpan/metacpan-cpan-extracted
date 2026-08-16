#
#  This file is part of WebDyne.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#
package WebDyne::Install::Apache::Constant;


#  Pragma
#
use strict qw(vars);
use vars qw($VERSION @ISA %Constant);
use warnings;
no warnings qw(uninitialized);


#  Does the heavy liftying of importing into caller namespace
#
require WebDyne::Constant;
@ISA=qw(WebDyne::Constant);



#  External modules
#
use File::Find;
use File::Spec;
use IO::File;
use Cwd qw(realpath);
use Env::Path;
use WebDyne::Util;
use Data::Dumper;


#  Constants for our Constants module. PATH is only used as last resort
#
use constant PATH => [qw(
        /sbin /bin /usr/sbin /usr/bin /usr/local/sbin /usr/local/bin /opt/sbin /opt/bin)
];


#  Need to null out some Fcntl functions under Win32
#
#use Fcntl;
#sub Fcntl::O_NONBLOCK { 0 }
#sub Fcntl::O_NOCTTY { 0 }


#  Local constants
#
our $Httpd_Bin=&httpd_bin();
our $Apachectl_Bin=&apachectl_bin();
our $Httpd_Config_hr=&httpd_config();
our $Apxs_Bin=&apxs_bin();
our $Apxs_Config_hr=&apxs_config($Apxs_Bin);
my $ServerRoot;


#  Version information
#
$VERSION='3.014';


#------------------------------------------------------------------------------

#  Name of user httpd runs under
#
my ($apache_uname, $apache_gname, $apache_uid, $apache_gid);
my @apache_uname=$ENV{'APACHE_UNAME'} ||
    qw(apache apache2 www wwwrun httpd httpd2 www-data webservd);
foreach my $name (@apache_uname) {
    unless ($apache_uid || $^O=~/MSWin[32|64]/) {
        if ($apache_uid=getpwnam($name)) {$apache_uname=$name; last}
    }
}
my @apache_gname=$ENV{'APACHE_GNAME'} ||
    qw(apache apache2 www wwwrun httpd httpd2 www-data webservd);
foreach my $name (@apache_gname) {
    unless ($apache_gid || $^O=~/MSWin[32|64]/) {
        if ($apache_gid=getgrnam($name)) {$apache_gname=$name; last}
    }
}
debug("apache_uid: $apache_uid, apache_gid: $apache_gid");


#  Check we have something for Apache uname etc.
#
unless ($apache_uid || $^O=~/MSWin[32|64]/) {
    warn('unable to determine Apache uname - please supply via APACHE_UNAME environment variable')
}
unless ($apache_gid || $^O=~/MSWin[32|64]/) {
    warn('unable to determine Apache gname - please supply via APACHE_GNAME environment variable')
}


#  Get mod_perl file and modules library location
#
my $dir_apache_modules=&dir_apache_modules();
my $file_mod_perl_lib=&file_mod_perl_lib($dir_apache_modules);


#  Is mod_perl2/1 installed
#
my $mp2_installed=&mp2_installed();


#  Real deal
#
%Constant=(


    #  Mod_perl1/2 installed
    #
    MP2_INSTALLED => $mp2_installed,


    #  Binary
    #
    HTTPD_BIN => $Httpd_Bin,
    APACHECTL_BIN => $Apachectl_Bin,
    APXS_BIN => $Apxs_Bin,


    #  Config file templates and final names, delimiter if inserted into master httpd.conf
    #
    FILE_WEBDYNE_CONF_TEMPLATE => 'webdyne.conf.inc',
    FILE_WEBDYNE_CONF          => 'webdyne.conf',
    FILE_WEBDYNE_CONF_PL_TEMPLATE       => 'webdyne_conf.pl.inc',
    FILE_WEBDYNE_CONF_PL       => 'webdyne_conf.pl',
    FILE_APACHE_CONF_TEMPLATE  => 'apache.conf.inc',
    FILE_APACHE_CONF_DELIM     => '#*WebDyne*',
    FILE_MOD_PERL_1_99_COMPAT  => 'webdyne-mod_perl-1_99-compat.pl',


    #  Get apache directory name
    #
    DIR_APACHE_CONF    => &dir_apache_conf(),
    DIR_APACHE_MODULES => $dir_apache_modules,


    #  Mod_perl library name
    #
    FILE_MOD_PERL_LIB => $file_mod_perl_lib,


    #  Need apache uid and gid, as some dirs will be chowned to this
    #  at install time
    #
    APACHE_UNAME => $apache_uname,
    APACHE_GNAME => $apache_gname,
    APACHE_UID   => $apache_uid,
    APACHE_GID   => $apache_gid,


    #  SELinux context for cache directory
    #
    SELINUX_CONTEXT_HTTPD => 'httpd_sys_content_t',
    SELINUX_CONTEXT_LIB   => 'lib_t',
    SELINUX_ENABLED_BIN   => &find_bin('selinuxenabled'),
    SELINUX_CHCON_BIN     => &find_bin('chcon'),
    SELINUX_SEMANAGE_BIN  => &find_bin('semanage'),


    #  Perl shared lib files that need to be checked for SELinux context
    #
    SELINUX_SO_CHECK => {

        IO             => 'IO/IO.so',
        'Digest::MD5'  => 'Digest/MD5/MD5.so',
        Fcntl          => 'Fcntl/Fcntl.so',
        'Time::HiRes'  => 'Time/HiRes/HiRes.so',
        Storable       => 'Storable/Storable.so',
        'File::Glob'   => 'File/Glob/Glob.so',
        Opcode         => 'Opcode/Opcode.so',
        'Data::Dumper' => 'Dumper/Dumper.so'

    },


    #  Server config
    #
    %{$Apxs_Config_hr || {}},
    %{$Httpd_Config_hr},


);


#  Get absolute binary file location
#
sub httpd_bin {


    #  If in Win32 need to get location of Apache from reg. Not much error checking
    #  because not fatal if reg key not found etc.
    #
    debug();
    my ($path, @name_bin);
    if ($^O=~/MSWin[32|64]/) {

        #  Windows
        #
        debug("detected MS Win: $^O");
        require Win32::TieRegistry;
        my $reg_ix=tie(
            my %reg, 'Win32::TieRegistry', 'HKEY_LOCAL_MACHINE\Software\Apache Group\Apache'
        );
        my $version=(sort {$b cmp $a} keys %reg)[0];
        unless ($version) {
            $reg_ix=tie(
                %reg, 'Win32::TieRegistry', 'HKEY_LOCAL_MACHINE\Software\Apache Software Foundation\Apache'
            );
            $version=(sort {$b cmp $a} keys %reg)[0];
        }
        debug("registry says version: $version");
        $path=($ServerRoot=$reg{$version}->{'ServerRoot'});    #||
                                                               # last resorts. blech
                                                               #'C:\Apache;C:\Apache~1;C:\Apache2;C:\Apache2.2;C:\Progra~1\Apache;C:\Progra~1\Apache2;C:\Progra~1\Apache~1;'.
                                                               #'D:\Apache;D:\Apache~1;D:\Apache2;D:\Apache2.2;D:\Progra~1\Apache;D:\Progra~1\Apache2;D:\Progra~1\Apache~1;'.
                                                               #'E:\Apache;E:\Apache~1;E:\Apache2;E:\Apache2.2;E:\Progra~1\Apache;E:\Progra~1\Apache2;E:\Progra~1\Apache~1;';

        #  Some Apache distro's use '/bin/' after ServerRoot
        #
        if ($path) {$path=join(Env::Path->PathSeparator, File::Spec->catdir($path, 'bin'))}

        #  Various names for Apache under Windows
        #
        @name_bin=qw(Apache.exe Apache2.exe httpd.exe httpd2.exe);
    }
    else {

        #  Add some hard coded paths as last resort options, will work if su'd to root
        #  without getting root's path
        #
        $path=join(Env::Path->PathSeparator, $ENV{'PATH'}, @{+PATH});
        @name_bin=qw(httpd httpd2 httpd2.2 httpd2.4 apache apache2 apache2.2 apache2.4);
    }
    debug("apache final search path: '$path'");
    debug('apache names %s', Dumper(\@name_bin));


    #  Find the httpd bin file
    #
    my $httpd_bin;
    unless ($httpd_bin=$ENV{'HTTPD_BIN'}) {

        my @dir=grep {-d $_} split(Env::Path->PathSeparator, $path);
        my %dir=map  {$_ => 1} @dir;
        DIR: foreach my $dir (@dir) {
            next unless delete $dir{$dir};
            next unless -d $dir;
            debug("searching dir: $dir");
            foreach my $name_bin (@name_bin) {
                if (-f File::Spec->catfile($dir, $name_bin)) {
                    $httpd_bin=File::Spec->catfile($dir, $name_bin);
                    last DIR;
                }
            }
        }
    }
    debug("httpd_bin returning: $httpd_bin");


    #  Warn if unable to find
    #
    unless (-f $httpd_bin) {
        warn('unable to find/determine Apache binary location - please supply via HTTPD_BIN environment variable');
    }


    #  Return
    #
    return File::Spec->canonpath($httpd_bin);

}


sub find_bin {

    my $bin=shift();
    my $path=join(Env::Path->PathSeparator, $ENV{'PATH'}, @{+PATH});
    debug("find_bin $bin, path: $path");
    my $fn;
    unless ($fn=$ENV{"${bin}_BIN"}) {
        my @dir=grep {-d $_} split(Env::Path->PathSeparator, $path);
        my %dir=map  {$_ => 1} @dir;
        foreach my $dir (@dir) {
            next unless delete $dir{$dir};
            next unless -d $dir;
            debug("searching dir: $dir");
            if (-f File::Spec->catfile($dir, $bin)) {
                $fn=File::Spec->catfile($dir, $bin); last;
            }
        }
    }


    #  Return
    #
    debug("find_bin returning: $fn");
    return $fn ? File::Spec->canonpath($fn) : undef;

}


sub find_first_bin {

    my ($env_ar, $name_ar)=@_;
    foreach my $env (@{$env_ar || []}) {
        next unless $ENV{$env};
        return File::Spec->canonpath($ENV{$env}) if -f $ENV{$env};
    }
    my $path=join(Env::Path->PathSeparator, $ENV{'PATH'}, @{+PATH});
    my @dir=grep {-d $_} split(Env::Path->PathSeparator, $path);
    my %dir=map  {$_ => 1} @dir;
    foreach my $dir (@dir) {
        next unless delete $dir{$dir};
        foreach my $name (@{$name_ar || []}) {
            my $fn=File::Spec->catfile($dir, $name);
            return File::Spec->canonpath($fn) if -f $fn;
        }
    }
    return;

}


sub command_output {

    my ($bin, @arg)=@_;
    return unless $bin && -f $bin;
    my @out;
    open(my $stderr_save, '>&', \*STDERR);
    open(STDERR, '>', File::Spec->devnull());
    if (open(my $fh, '-|', $bin, @arg)) {
        @out=<$fh>;
        close($fh);
    }
    open(STDERR, '>&', $stderr_save) if $stderr_save;
    return @out;

}


sub apachectl_bin {

    my $apachectl_bin=find_first_bin(
        [qw(APACHECTL_BIN APACHECTL APACHE2CTL)],
        [qw(apachectl apache2ctl)]
    );
    debug("apachectl_bin returning: $apachectl_bin");
    return $apachectl_bin;

}


sub apxs_bin {

    my $apxs_bin=find_first_bin(
        [qw(APXS_BIN APXS APACHE_TEST_APXS)],
        [qw(apxs apxs2 apxs2.4)]
    );
    debug("apxs_bin returning: $apxs_bin");
    return $apxs_bin;

}


sub apxs_config {

    my $apxs_bin=shift() || return {};
    my %config;
    foreach my $key (qw(LIBEXECDIR SYSCONFDIR HTTPD_ROOT SERVER_CONFIG_FILE)) {
        my @out=command_output($apxs_bin, '-q', $key);
        next unless @out;
        chomp(my $value=$out[0]);
        next unless defined($value) && length($value);
        $config{"APXS_$key"}=$value;
    }
    debug('apxs_config: %s', Dumper(\%config));
    return \%config;

}


sub httpd_config {


    #  Return if neither httpd nor apachectl was found.
    #
    debug();
    return unless $Httpd_Bin || $Apachectl_Bin;


    #  Need to get httpd config as series of key/val pairs
    #
    my %config;
    my $devnull=File::Spec->devnull();
    my @httpd_config=command_output($Httpd_Bin, '-V');
    @httpd_config=command_output($Apachectl_Bin, '-V') unless @httpd_config;
    debug('httpd_config: %s', Dumper(\@httpd_config));


    #  Go through
    #
    foreach my $httpd_config (@httpd_config) {

        if ($httpd_config=~/Apache\/(\d+\.\d+)/) {
            $config{'HTTPD_VER'}=$1;
            next;
        }
        next unless ($httpd_config=~/\s*\-D\s*(.*)/);
        my ($key, $value)=split(/\=/, $1);
        $key=~s/\s+.*$//g;
        $value ||= '';
        $value=~s/^\"//;
        $value=~s/\"$//;
        $key=~/^HTTPD/       || ($key="HTTPD_${key}");
        $config{$key}=$value || 1;

    }


    #  In windows HTTPD_ROOT does not always match actual installed root path,
    #  so override if possible
    #
    my $httpd_dn=($config{'HTTPD_ROOT'}=$ServerRoot || $config{'HTTPD_ROOT'});


    #  Last resort - if does not exist use apache bin location as ref for
    #  HTTPD_ROOT
    #
    unless (-d $httpd_dn) {
        debug('using last resort to find httpd_dn');
        $config{'HTTPD_ROOT'}=do {
            my $dn=File::Spec->catdir(
                (File::Spec->splitpath($Httpd_Bin))[1],
                File::Spec->updir());
            (-d $dn) && ($dn=realpath($dn));
            $dn;
        };
    }
    debug('httpd_dn set to: %s', $config{'HTTPD_ROOT'});


    #  And return the config
    #
    return \%config;

}


sub dir_apache_conf {


    #  Get Apache config dir, ensure is absolute
    #
    debug();
    my $apache_conf_dn;
    unless ($apache_conf_dn=$ENV{'DIR_APACHE_CONF'}) {

        if (my $sysconf_dn=$Apxs_Config_hr->{'APXS_SYSCONFDIR'}) {
            $apache_conf_dn=$sysconf_dn;
        }
        else {
            $apache_conf_dn=$Httpd_Config_hr->{'HTTPD_SERVER_CONFIG_FILE'};
        }
        my $apache_conf_fn=(File::Spec->splitpath($apache_conf_dn))[2];
        $apache_conf_dn=~s/\Q$apache_conf_fn\E$// if $apache_conf_fn=~/\.conf$/;

        #$apache_conf_dn=(File::Spec->splitpath(
        #    $Httpd_Config_hr->{'HTTPD_SERVER_CONFIG_FILE'}))[1];
        debug("apache_conf_fn initital value: $apache_conf_dn");
        unless ($apache_conf_dn=~/^\//) {

            debug("apache_conf_dn path appears relative - prepending HTTPD_ROOT");
            $apache_conf_dn=File::Spec->catdir(
                $Httpd_Config_hr->{'HTTPD_ROOT'}, $apache_conf_dn
            );

        }
        else {
            debug('apache_conf_dn appears fully qualified - leaving intact');
        }


        #  Prefer distro include directories when available. Debian-style
        #  systems keep the source file in conf-available and enable it through
        #  conf-enabled; Fedora/RHEL-style systems commonly include conf.d.
        #
        my @include_dn=(
            [ 'conf.d' ],
            [ File::Spec->catdir(File::Spec->updir(), 'conf.d') ],
            [ 'conf-available', 'conf-enabled' ],
            [ File::Spec->catdir(File::Spec->updir(), 'conf-available'), File::Spec->catdir(File::Spec->updir(), 'conf-enabled') ],
        );
        foreach my $dn_ar (@include_dn) {
            my ($dn, $enabled_dn)=@{$dn_ar};
            debug("looking for conf.d path: $dn");
            my $test_dn=File::Spec->canonpath(
                File::Spec->catdir($apache_conf_dn, $dn));
            debug("testing: $test_dn");
            if (-d $test_dn) {
                if ($enabled_dn) {
                    my $test_enabled_dn=File::Spec->canonpath(
                        File::Spec->catdir($apache_conf_dn, $enabled_dn));
                    $Httpd_Config_hr->{'DIR_APACHE_CONF_ENABLED'}=realpath($test_enabled_dn)
                        if -d $test_enabled_dn;
                }
                $apache_conf_dn=realpath($test_dn);
                debug("found, setting apache_conf_dn: $apache_conf_dn");
                $Httpd_Config_hr->{'HTTPD_SERVER_CONFIG_SKIP'}=1;
                last;
            }
            else {
                debug('not found');
            }
        }
    }
    else {
        debug('setting apache_conf_dn from %ENV');
    }
    debug("apache_conf_dn set to: $apache_conf_dn");


    #  Warn if not found
    #
    unless (-d $apache_conf_dn) {
        warn('unable to find/determine Apache conf directory - please supply via DIR_APACHE_CONF environment variable');
    }


    #  Return it
    #
    return $apache_conf_dn;

}


sub dir_apache_modules {


    #  Get Apache config dir, ensure is absolute
    #
    debug();
    my @dn=(
        $Apxs_Config_hr->{'APXS_LIBEXECDIR'},
        File::Spec->catdir(
            $Httpd_Config_hr->{'HTTPD_ROOT'}, 'modules'
        ),
        File::Spec->catdir(
            $Httpd_Config_hr->{'HTTPD_ROOT'}, 'libexec'
        ),

        # last resorts, blech
        '/usr/lib/apache2/modules',
        '/usr/lib/apache2.2/modules',
        '/usr/lib/httpd/modules',
        '/usr/lib/apache2',
        '/usr/lib/apache2.2',
        '/usr/local/lib',
        '/usr/local/lib64',
        '/usr/lib',
        '/usr/lib64'
    );


    #  Check for modules
    #
    my $apache_modules_dn;
    unless ($apache_modules_dn=$ENV{'DIR_APACHE_MODULES'}) {
        foreach my $dn (@dn) {
            debug("looking for path: $dn");
            if (-d $dn) {
                $apache_modules_dn=$dn;
                debug("found, setting apache_modules_dn to: $dn");
                last;
            }
        }
        $apache_modules_dn ||= 'modules';
    }
    else {
        debug('setting apache_modules_dn from %ENV');
    }
    debug("apache_modules_dn set to: $apache_modules_dn");


    #  Warn if not found. Update - don't do this anymore, just warn later if mod_perl lib not found, which
    #  used this routine to find potential module storage dir.
    #
    #unless (-d $apache_modules_dn) {
    #warn('unable to find/determine Apache modules directory - please supply via DIR_APACHE_MODULES environment variable');
    #}


    #  Return it
    #
    return $apache_modules_dn;

}


sub file_mod_perl_lib {


    #  Get the name of the mod_perl library
    #
    my $dn=shift();
    debug("looking for mod_perl dn: $dn");
    my $mod_perl_cn;
    unless ($mod_perl_cn=$ENV{'FILE_MOD_PERL_LIB'}) {
        foreach my $fn (qw(libperl mod_perl mod_perl2 mod_perl2.2 mod_perl-2 mod_perl-2.2)) {
            foreach my $ext (qw(so dll)) {
                my $cn=File::Spec->catfile($dn, "$fn.$ext");
                debug("looking for cn: $cn");
                if (-f $cn) {
                    $mod_perl_cn=$cn;
                    last;
                }
                else {
                    debug('not found');
                }
            }
            last if $mod_perl_cn;
        }
    }
    else {
        debug("setting mod_perl_cn from %ENV")
    }
    debug("mod_perl_cn set to: $mod_perl_cn");


    unless (-f $mod_perl_cn) {
        warn('unable to find/determine mod_perl library - please supply via FILE_MOD_PERL_LIB environment variable');
    }
    return $mod_perl_cn;

}


sub mp2_installed {

    local $SIG{__DIE__};
    eval {require Apache2};
    eval {require mod_perl};
    eval {require mod_perl2};
    eval {undef} if $@;
    my $mp2_installed;
    if (($mod_perl::VERSION || $mod_perl2::VERSION || $ENV{MOD_PERL_API_VERSION}) >= 1.99) {
        $mp2_installed=1;
    }
    elsif (($mod_perl::VERSION || $mod_perl2::VERSION || $ENV{MOD_PERL_API_VERSION}) >= 1) {
        $mp2_installed=0
    }
    elsif ($file_mod_perl_lib) {

        # Last resort - mod_perl libary exists, but we couldn't load
        #
        $mp2_installed=0;
        my $version=qx($Httpd_Bin -v);
        if ($version=~/(\d+)\.(\d+)/) {
            $version=$1 . $2;
            if ($version >= 2) {
                $mp2_installed=1;
            }
        }
    }
    debug("mp2_installed: $mp2_installed");

    return $mp2_installed;

}


#  Done
#
1;
__END__

=begin markdown

# WebDyne::Install::Apache::Constant #

# NAME #

WebDyne::Install::Apache::Constant - Apache-install discovery and template constants for WebDyne

# SYNOPSIS #

```perl
use WebDyne::Install::Apache::Constant;
```

# DESCRIPTION #

`WebDyne::Install::Apache::Constant` discovers Apache-related paths and defaults used by the Apache installer. It resolves the Apache binary, configuration directories, module directories, mod_perl library path, Apache runtime user/group, SELinux helpers, and template filenames used by `WebDyne::Install::Apache`.

# CONSTANTS #

Commonly used constants include:

* **MP2_INSTALLED**

    Boolean indicating whether mod_perl 2 appears to be installed.

* **HTTPD_BIN**

    Resolved path to the Apache `httpd` binary.

* **APACHECTL_BIN**

    Resolved path to `apachectl` or `apache2ctl`, used as a fallback source for Apache `-V` configuration output.

* **APXS_BIN**

    Resolved path to `apxs`, `apxs2`, or `apxs2.4`, used to query Apache development installation paths when available.

* **DIR_APACHE_CONF**

    Resolved Apache configuration directory.

* **DIR_APACHE_CONF_ENABLED**

    Resolved Debian-style enabled configuration directory when `conf-available` and `conf-enabled` are detected.

* **DIR_APACHE_MODULES**

    Resolved Apache modules directory.

* **FILE_MOD_PERL_LIB**

    Resolved mod_perl shared library path.

* **APACHE_UNAME / APACHE_GNAME**

    Detected Apache user and group names.

* **APACHE_UID / APACHE_GID**

    Detected Apache user and group numeric identifiers.

* **FILE_WEBDYNE_CONF_TEMPLATE / FILE_WEBDYNE_CONF**

    Input template filename and rendered Apache config filename.

* **FILE_WEBDYNE_CONF_PL_TEMPLATE / FILE_WEBDYNE_CONF_PL**

    Input template filename and rendered WebDyne Perl config filename.

* **SELINUX_CONTEXT_HTTPD / SELINUX_CONTEXT_LIB**

    SELinux context names used during installation checks and setup.

* **SELINUX_ENABLED_BIN / SELINUX_CHCON_BIN / SELINUX_SEMANAGE_BIN**

    Discovered helper binaries used for SELinux detection and context changes.

# METHODS #

This module also exposes helper routines used internally by the installer:

* **httpd_bin()**

    Locate the Apache executable.

* **apachectl_bin()**

    Locate the Apache control executable.

* **apxs_bin() / apxs_config()**

    Locate APXS and query Apache development installation paths.

* **httpd_config()**

    Inspect Apache configuration and derive path details.

* **dir_apache_conf()**

    Resolve the Apache configuration directory.

* **dir_apache_modules()**

    Resolve the Apache modules directory.

* **file_mod_perl_lib()**

    Locate the mod_perl shared library.

* **mp2_installed()**

    Determine whether mod_perl 2 support is available.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>


=end markdown


=head1 WebDyne::Install::Apache::Constant


=head1 NAME

WebDyne::Install::Apache::Constant - Apache-install discovery and template constants for WebDyne


=head1 SYNOPSIS


 use WebDyne::Install::Apache::Constant;

=head1 DESCRIPTION

C<WebDyne::Install::Apache::Constant> discovers Apache-related paths and defaults used by the Apache installer. It resolves the Apache binary, configuration directories, module directories, mod_perl library path, Apache runtime user/group, SELinux helpers, and template filenames used by C<WebDyne::Install::Apache>.


=head1 CONSTANTS

Commonly used constants include:

=over

=item *

B<MP2_INSTALLED>

Boolean indicating whether mod_perl 2 appears to be installed.



=item *

B<HTTPD_BIN>

Resolved path to the Apache C<httpd> binary.



=item *

B<APACHECTL_BIN>

Resolved path to C<apachectl> or C<apache2ctl>, used as a fallback source for Apache C<-V> configuration output.



=item *

B<APXS_BIN>

Resolved path to C<apxs>, C<apxs2>, or C<apxs2.4>, used to query Apache development installation paths when available.



=item *

B<DIR_APACHE_CONF>

Resolved Apache configuration directory.



=item *

B<DIR_APACHE_CONF_ENABLED>

Resolved Debian-style enabled configuration directory when C<conf-available> and C<conf-enabled> are detected.



=item *

B<DIR_APACHE_MODULES>

Resolved Apache modules directory.



=item *

B<FILE_MOD_PERL_LIB>

Resolved mod_perl shared library path.



=item *

B<APACHE_UNAME / APACHE_GNAME>

Detected Apache user and group names.



=item *

B<APACHE_UID / APACHE_GID>

Detected Apache user and group numeric identifiers.



=item *

B<FILE_WEBDYNE_CONF_TEMPLATE / FILE_WEBDYNE_CONF>

Input template filename and rendered Apache config filename.



=item *

B<FILE_WEBDYNE_CONF_PL_TEMPLATE / FILE_WEBDYNE_CONF_PL>

Input template filename and rendered WebDyne Perl config filename.



=item *

B<SELINUX_CONTEXT_HTTPD / SELINUX_CONTEXT_LIB>

SELinux context names used during installation checks and setup.



=item *

B<SELINUX_ENABLED_BIN / SELINUX_CHCON_BIN / SELINUX_SEMANAGE_BIN>

Discovered helper binaries used for SELinux detection and context changes.



=back


=head1 METHODS

This module also exposes helper routines used internally by the installer:

=over

=item *

B<httpd_bin()>

Locate the Apache executable.



=item *

B<apachectl_bin()>

Locate the Apache control executable.



=item *

B<apxs_bin() / apxs_config()>

Locate APXS and query Apache development installation paths.



=item *

B<httpd_config()>

Inspect Apache configuration and derive path details.



=item *

B<dir_apache_conf()>

Resolve the Apache configuration directory.



=item *

B<dir_apache_modules()>

Resolve the Apache modules directory.



=item *

B<file_mod_perl_lib()>

Locate the mod_perl shared library.



=item *

B<mp2_installed()>

Determine whether mod_perl 2 support is available.



=back


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer L<mailto:andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

L<http://dev.perl.org/licenses/>

=cut

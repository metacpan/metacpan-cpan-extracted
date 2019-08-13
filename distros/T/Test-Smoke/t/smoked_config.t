#! /usr/bin/perl -w
use strict;

use File::Spec;
my $findbin;
use File::Basename;
BEGIN { $findbin = dirname $0; }
use lib $findbin;
use TestLib;
use File::Temp 'tempdir';

use Test::More tests => 38;
BEGIN { use_ok( 'Test::Smoke::Util', 'get_smoked_Config' ) }

# make it work for all
require POSIX;
my( $osname, undef, $osvers, undef, $arch ) = map lc $_ => POSIX::uname();
my $version = '5.9.0';
my $config_sh = <<"!END!";
osname='$osname'
osvers='$osvers'
archname='$arch'
cf_email='abeltje\@cpan.org'
version='$version'
!END!

my $tmpdir = tempdir(CLEANUP => ($ENV{SMOKE_DEBUG} ? 0 : 1));

my( $Config_heavy, $Config_pm, $Config_sh, $patchlevel_h );
SKIP: {
    my $cfg_nm = 'Config_heavy.pl';
    my $to_skip = 5;
    my $libpath = File::Spec->catdir( $tmpdir, 'lib' );
    -d $libpath or mkpath( $libpath )  or
        skip "Can't create '$libpath': $!", $to_skip;
    $Config_heavy = File::Spec->catfile( $libpath, $cfg_nm );

    local *CONFIGPM;
    open CONFIGPM, "> $Config_heavy" or
        skip "Can't create '$Config_heavy': $!", $to_skip;

    print CONFIGPM <<EOCONFIG;
package Config;

# blah blah
local \*_ = \\my \$a;
\$_ = \<\<'!END!';
$config_sh
!END!

# more stuff
1;
EOCONFIG
    close CONFIGPM or skip "Error '$Config_heavy': $!", $to_skip;

    my %Config = get_smoked_Config( $tmpdir,
                                    qw( archname cf_email version
                                        osname osvers ));

    ok( -e $Config_heavy, "Config from: $Config_heavy" );
    is( $Config{archname}, $arch, "Architecture $arch" );
    is( $Config{cf_email}, 'abeltje@cpan.org', 'cf_email' );
    is( $Config{osname}, $osname, "OS name: $osname" );
    is( $Config{osvers}, $osvers, "OS version: $osvers" );
    is( $Config{version}, $version, "Perl version: $version" );

    1 while unlink $Config_heavy;
}

SKIP: {
    my $to_skip = 5;
    my $libpath = File::Spec->catdir( $tmpdir, 'lib' );
    -d $libpath or mkpath( $libpath )  or
        skip "Can't create '$libpath': $!", $to_skip;
    $Config_pm = File::Spec->catfile( $libpath, 'Config.pm' );

    local *CONFIGPM;
    open CONFIGPM, "> $Config_pm" or
        skip "Can't create '$Config_pm': $!", $to_skip;

    print CONFIGPM <<EOCONFIG;
package Config;

# blah blah
my \$config_sh = \<\<'!END!';
$config_sh
!END!

# more stuff
1;
EOCONFIG
    close CONFIGPM or skip "Error '$Config_pm': $!", $to_skip;

    my %Config = get_smoked_Config( $tmpdir,
                                    qw( archname cf_email version
                                        osname osvers ));

    ok( -e $Config_pm, "Config from: $Config_pm" );
    is( $Config{archname}, $arch, "Architecture $arch" );
    is( $Config{cf_email}, 'abeltje@cpan.org', 'cf_email' );
    is( $Config{osname}, $osname, "OS name: $osname" );
    is( $Config{osvers}, $osvers, "OS version: $osvers" );
    is( $Config{version}, $version, "Perl version: $version" );

    1 while unlink $Config_pm;
}

SKIP: { # get info from config.sh
    my $to_skip = 5;
    my $libpath = File::Spec->catdir( $tmpdir );
    $Config_sh = File::Spec->catfile( $libpath, 'config.sh' );

    local *CONFIGSH;
    open CONFIGSH, "> $Config_sh" or
        skip "Can't create '$Config_sh': $!", $to_skip;

    print CONFIGSH <<EOCONFIG;
#!/bin/sh
#
# This file is produced by $0
#

# Package name      : perl 5
# Configuration time: @{[ scalar localtime ]}


$config_sh
EOCONFIG
    close CONFIGSH or skip "Error '$Config_sh': $!", $to_skip;

    my %Config = get_smoked_Config( $tmpdir,
                                    qw( archname cf_email version
                                        osname osvers ));

    ok( -e $Config_sh, "Config from: $Config_sh" );
    is( $Config{archname}, $arch, "Architecture $arch" );
    is( $Config{cf_email}, 'abeltje@cpan.org', 'cf_email' );
    is( $Config{osname}, $osname, "OS name: $osname" );
    is( $Config{osvers}, $osvers, "OS version: $osvers" );
    is( $Config{version}, $version, "Perl version: $version" );

    1 while unlink $Config_sh;
}

{
    my %Config = get_smoked_Config( $tmpdir,
                                    qw( archname cf_email version
                                        osname osvers ));

    my $no_files = 1;
    $no_files &&= ! -e $_ for grep defined $_
        => ( $Config_heavy, $Config_pm, $Config_sh );
    ok( $no_files, "Config from: fallback" );
    is( $Config{archname}, $arch, "Architecture $arch" );
    is( $Config{osname}, $osname, "OS name: $osname" );
    is( $Config{osvers}, $osvers, "OS version: $osvers" );
    is( $Config{version}, '5.?.?', "Perl version: $Config{version}" );
}

$patchlevel_h = File::Spec->catfile( $tmpdir, 'patchlevel.h' );
SKIP: {
    my $to_skip = 4;

    local *PL_H;
    open PL_H, "> $patchlevel_h" or
        skip "Can't create '$Config_pm': $!", $to_skip;

    print PL_H <<EOPL;
#ifndef __PATCHLEVEL_H_INCLUDED__
#define PATCHLEVEL 5
#undef SUBVERSION     /* OS/390 has a SUBVERSION in a system header */
#define SUBVERSION 4
EOPL

    close PL_H or skip "Error '$patchlevel_h': $!", $to_skip;

    my %Config = get_smoked_Config( $tmpdir,
                                    qw( archname cf_email version
                                        osname osvers ));
    is( $Config{archname}, $arch, "Architecture $arch" );
    is( $Config{osname}, $osname, "OS name: $osname" );
    is( $Config{osvers}, $osvers, "OS version: $osvers" );
    is( $Config{version}, '5.00504', "Perl version: $Config{version}" );

    1 while unlink $patchlevel_h;
}

SKIP: {
    my $to_skip = 4;

    local *PL_H;
    open PL_H, "> $patchlevel_h" or
        skip "Can't create '$Config_pm': $!", $to_skip;

    print PL_H <<EOPL;
/*    patchlevel.h
 *
 *    Copyright (C) 1993, 1995, 1996, 1997, 1998, 1999,
 *    2000, 2001, 2002, 2003, 2004, by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

#ifndef __PATCHLEVEL_H_INCLUDED__

/* do not adjust the whitespace! Configure expects the numbers to be
 * exactly on the third column */

#define PERL_REVISION	5		/* age */
#define PERL_VERSION	8		/* epoch */
#define PERL_SUBVERSION	6		/* generation */

EOPL

    close PL_H or skip "Error '$patchlevel_h': $!", $to_skip;

    my %Config = get_smoked_Config( $tmpdir,
                                    qw( archname cf_email version
                                        osname osvers ));
    is( $Config{archname}, $arch, "Architecture $arch" );
    is( $Config{osname}, $osname, "OS name: $osname" );
    is( $Config{osvers}, $osvers, "OS version: $osvers" );
    is( $Config{version}, '5.8.6', "Perl version: $Config{version}" );

    1 while unlink $patchlevel_h;
}

SKIP: {
    my $to_skip = 5;

    local *CONFIGPM;
    open CONFIGPM, "> $Config_pm" or
        skip "Can't create '$Config_pm': $!", $to_skip;

    print CONFIGPM <<EOCONFIG;
package Config;

# Change 23147 messed all up!
local \*_ = \\my \$a;
\$_ = \<\<'!END!';
$config_sh
!END!

s/(byteorder=)(['"]).*?\\2/\$1\$2\$byteorder\$2/m; # emacs '
our \$Config_SH : unique = \$_;
# more stuff
1;
EOCONFIG
    close CONFIGPM or skip "Error '$Config_pm': $!", $to_skip;

    my %Config = get_smoked_Config( $tmpdir,
                                    qw( archname cf_email version
                                        osname osvers ));

    ok( -e $Config_pm, "Config from: $Config_pm" );
    is( $Config{archname}, $arch, "Architecture $arch" );
    is( $Config{cf_email}, 'abeltje@cpan.org', 'cf_email' );
    is( $Config{osname}, $osname, "OS name: $osname" );
    is( $Config{osvers}, $osvers, "OS version: $osvers" );
    is( $Config{version}, $version, "Perl version: $version" );

    1 while unlink $Config_pm;
}

END {
    rmtree( File::Spec->catdir( $tmpdir, 'lib' ) )
}

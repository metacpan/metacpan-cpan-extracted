#!perl
package MMUtil;

# This file is part of the build tools for Win32::GUI
# It encapsulates a number of helper functions that
# are repeatedly used in the build process.  Specifically
# helpers in this package are used to extend the ExtUtil::MakeMaker
# functionality during the Makefile.PL phase.
#
# Author: Robert May , rmay@popeslane.clara.co.uk, 20 June 2005
# $Id: MMUtil.pm,v 1.1 2008/02/01 13:29:49 robertemay Exp $

use 5.006001;
use strict;
use warnings;

use Config();

my $extra_compiler_flags = [];
my $remove_compiler_flags = [];

######################################################################
# Testing for whether various fixes are required.
######################################################################

# mms_bitfields_fix()
# When bulding Win32::GUI with Mingw (gcc) and the perl version we are
# building against uses bitfields in structs (perl >= 5.9.x)
# and perl.exe we are building against was built with MS VC++, then we
# need to pass the -mms-bitfields option to gcc to casue it to use the
# same bitfield alignment as MS VC++ did.
sub mms_bitfields_fix {
    if( builder_is_mingw() && $] >= 5.009000 && perl_is_msvc() ) {
        push @{$extra_compiler_flags}, '-mms-bitfields';
        return 1;
    }
    return; 0
}

# gcc_declaration_after_statement_fix()
# gcc-3.4 issues a warning if -Wdeclaration-after-statement is
# used with cpp files (c++ mode).  So remove it.
sub gcc_declaration_after_statement_fix {
    if( cc_is_gcc() ) {
        push @{$remove_compiler_flags}, '-Wdeclaration-after-statement';
        return 1;
    }
    return 0;
}

######################################################################
# Testing our build environment.
######################################################################

sub builder_is_mingw {
    return os_is_win32() && cc_is_gcc();
}

sub builder_is_gcc {
    return os_is_cygwin() && cc_is_gcc();
}

sub builder_is_msvc {
    return os_is_win32() && cc_is_cl();
}

sub cc_is_gcc {
    return $Config::Config{cc} =~ /gcc/i;
}

sub cc_is_cl {
    return $Config::Config{cc} =~ /cl/i;
}

sub os_is_win32 {
    return $^O =~ /MSWin32/i;
}

sub os_is_cygwin {
    return $^O =~ /cygwin/i;
}

######################################################################
# Testing the current Perl
######################################################################

# perl_is_msvc()
# Tell us whether it looks like the currently running perl
# was built with VC++ compiler.  We can't just check $config{cc}, as
# modules like ActiveState::Config and ExtUtils::FakeConfig hide
# the original value from us.
sub perl_is_msvc {
    return 0 unless os_is_win32();

    # Parse the raw Config data, so that we can find the values set
    # by the original perl build.
    require Config;
    my $config_file=$INC{'Config.pm'};

    my $cc = '';
    # What we're looking for is in Config_heavy.pl for all
    # recent perl's so look there first.  But that doesn't
    # exist on perl 5.6.1, so don't die if it's not
    for my $file (qw(Config_heavy.pl Config.pm)) {
        (my $fullname = $config_file) =~ s/Config.pm$/$file/;
        open(my $fh, "<", $fullname) or next;
        while (<$fh>) {
            $cc = $1, last if /^cc='(.*)'/;
        }
        last if length $cc;
    }
    return $cc =~ /cl/i;
}

######################################################################
# Extend ExtUtil::MakeMaker by creating stuff in package MY
######################################################################

# Extend_MM()
# Designed to be called just before calling
# ExtUtils::MakeMaker::WriteMakefile to prepare the extensions required
sub Extend_MM {

    # fix up c_flags
    mms_bitfields_fix();
    gcc_declaration_after_statement_fix();
    _fixup_cflags();

    return 1;
}

sub _fixup_cflags() {

    my $frag = '{ package MY; no warnings "redefine"; sub cflags { my $i = shift->SUPER::cflags(@_);';

    for my $c_flag (@{$extra_compiler_flags}) {
        $frag .= '$i =~ s/^(CCFLAGS\s*=\s*.*)$/$1 ' . $c_flag . '/m;';
    }

    for my $c_flag (@{$remove_compiler_flags}) {
        $frag .= '$i =~ s/' . $c_flag . '//mg;';
    }

    $frag .= 'return $i; } }';

    eval $frag;
    die $@ if $@;

    return;
}

1; # end of MMUtil

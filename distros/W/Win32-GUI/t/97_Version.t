#!perl -wT
# Win32::GUI test suite.
# $Id: 97_Version.t,v 1.1 2008/02/08 18:02:04 robertemay Exp $

# Testing that GUI.dll has the same version as GUI.pm

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More;

use Win32::GUI();
use Config;

my($maj_pm, $min_pm, $rc_pm);

my $version = $Win32::GUI::VERSION . '00';
if($version =~ m/^(\d+)\.(\d\d)(\d\d)/) {
    ($maj_pm, $min_pm, $rc_pm) = ($1, $2, $3);
}

my ($maj_rc, $min_rc, $rc_rc, $extra) = Win32::GUI::GetDllVersion('GUI.' . $Config{dlext});

plan tests => 4;

ok($maj_pm == $maj_rc, "Major Version numbers the same: ($version) vs. ($maj_rc.$min_rc.$rc_rc)");
ok($min_pm == $min_rc, "Minor Version numbers the same: ($version) vs. ($maj_rc.$min_rc.$rc_rc)");
ok($rc_pm  ==  $rc_rc,  "RC numbers the same: ($version) vs. ($maj_rc.$min_rc.$rc_rc)");
ok(!defined $extra,     "No extra information");

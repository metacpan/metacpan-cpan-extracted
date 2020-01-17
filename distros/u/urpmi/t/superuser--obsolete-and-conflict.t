#!/usr/bin/perl

# package "a" is split into "b" and "c",
# where "b" obsoletes/provides "a" and requires "c"
#       "c" conflicts with "a" (but can't obsolete it)
#
# package "d" requires "a"

use strict;
use lib '.', 't';
use helper;
use urpm::select;
use urpm::util;
use urpm::cfg;
use Test::More 'no_plan';

need_root_and_prepare();

my $name = 'obsolete-and-conflict';
urpmi_addmedia("$name $::pwd/media/$name");    

test1();
test_with_ad('b c', 'b c d');
test_with_ad('--split-level 1 --split-length 1 b c', 'b c d'); # perl-URPM fix for #31969 fixes this too ("d" used to be removed without asking)

# below need promotion of "b" (obsoleting "a") to work
test_with_ad('--auto c', 'b c d');

sub test1 {
    urpmi('a');
    check_installed_names('a');

    my $arch = urpm::cfg::get_arch();
    my $rm_msg = urpm::select::_rpm_version() gt 4.13.0 ? " a-1-1.$arch" : "";
    test_urpmi("b c", sprintf(<<'EOF', $rm_msg || ' ', $rm_msg));
      1/2: c
      2/2: b
removing package%s
      1/1: removing%s
EOF
    check_installed_and_remove('b', 'c');
}

sub test_with_ad {
    my ($para, $wanted) = @_;
    urpmi('a d');
    check_installed_names('a', 'd');
    urpmi($para);
    check_installed_and_remove(split ' ', $wanted);
}

sub test_urpmi {
    my ($para, $wanted) = @_;
    my $s = run_urpm_cmd("urpmi $para");

    $s =~ s/\s*#{40}#*//g;
    $s =~ s/.*\nPreparing\.\.\.\n//s;

    ok($s eq $wanted, "$wanted in $s");
}

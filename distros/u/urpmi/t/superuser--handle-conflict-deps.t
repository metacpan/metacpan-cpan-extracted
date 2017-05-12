#!/usr/bin/perl

# b requires b-sub
# a-sup requires a
# a conflicts with b, b conflicts with a
#
# c conflicts with d
#
# e conflicts with ff
# f provides ff
# g conflicts with ff
#
use strict;
use lib '.', 't';
use helper;
use urpm::util;
use Test::More 'no_plan';

need_root_and_prepare();

my $name = 'handle-conflict-deps';
urpmi_addmedia("$name $::pwd/media/$name");    

test_simple('c', 'd');
test_simple('d', 'c');
test_simple('e', 'f'); # test for mdvbz #17106
test_simple('f', 'e');

test_conflict_on_install();
test_conflict_on_upgrade(); #test from bugs #12696, #11885

sub test_conflict_on_upgrade {
    urpmi('--auto a-sup');
    check_installed_names('a', 'a-sup');

    urpmi('--auto b');
    check_installed_and_remove('b', 'b-sub');
}

sub test_conflict_on_install {
    urpmi_partial('--auto a b');
    # either a or b is chosen, depending on hdlist order; both are valid
    if (system("rpm -q --quiet --root $::pwd/root a") == 0) {
	check_installed_and_remove('a');
    } else {
	check_installed_and_remove('b', 'b-sub');
    }

    urpmi_partial('--auto f g'); # test for bug #52135
    # either f or g is chosen, depending on hdlist order; both are valid
    if (system("rpm -q --quiet --root $::pwd/root f") == 0) {
	check_installed_and_remove('f');
    } else {
	check_installed_and_remove('g');
    }
}

sub test_simple {
    my ($pkg1, $pkg2) = @_;
    urpmi($pkg1);
    check_installed_names($pkg1);

    urpmi("--auto $pkg2");
    check_installed_and_remove($pkg2);
}

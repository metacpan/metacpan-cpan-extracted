#!/usr/bin/perl

# a-1 requires b-1
# b-1 requires c-1
# a-2 requires c-2, no b-2
#
# d-1 requires dd-1
# d-2 requires dd-2
#
# e-1 requires f-1
# e-2 requires f-2
# f-1 requires gh = 1 provided by g-1
# f-2 requires gh = 2 provided by h-2
#
use strict;
use lib '.', 't';
use helper;
use urpm::util;
use Test::More 'no_plan';

need_root_and_prepare();

my $name = 'split-transactions--strict-require';
urpmi_addmedia("$name-1 $::pwd/media/$name-1");    
urpmi_addmedia("$name-2 $::pwd/media/$name-2");

test('--split-length 0');
test('--split-level 1 --split-length 1');

test_c('--split-level 1 --split-length 1');

# test_d(); 
# ERROR #34224: urpmi goes crazy, saying: 
# The following package has to be removed for others to be upgraded: d-2-1 (in order to install d-2-1)
# This is because both d-1 and d-2 are installed

test_efgh('--auto-select');
test_efgh('--debug g'); # didn't work because of perl-URPM "not promoting pkg because of currently unsatisfied require". it also broke small transactions

sub test {
    my ($option) = @_;

    urpmi("--media $name-1 --auto a");
    check_installed_fullnames('a-1-1', 'b-1-1', 'c-1-1');

    urpmi("--media $name-2 --auto $option --auto-select");
    check_installed_fullnames_and_remove('a-2-1', 'c-2-1');
}

sub test_c {
    my ($option) = @_;

    urpmi("--media $name-1 --auto a");
    check_installed_fullnames('a-1-1', 'b-1-1', 'c-1-1');

    urpmi("--media $name-2 --auto $option c");
    check_installed_fullnames_and_remove('a-2-1', 'c-2-1');
}

sub test_d {
    urpmi("--media $name-1 --auto d");

    # here d-2 is installed without its requirement dd-2
    system_("rpm --root $::pwd/root -i media/$name-2/d-2-*.rpm --nodeps");
    # we now have both d-1 and d-2 installed, which urpmi doesn't like much
    check_installed_fullnames('d-1-1', 'dd-1-1', 'd-2-1');

    urpmi("--media $name-2 --auto-select --auto");
    check_installed_fullnames_and_remove('d-2-1', 'dd-2-1');
}

sub test_efgh {
    my ($para) = @_;

    urpmi("--media $name-1 --auto e");
    check_installed_fullnames('e-1-1', 'f-1-1', 'g-1-1');

    urpmi("--media $name-2 --auto $para");
    check_installed_fullnames_and_remove('e-2-1', 'f-2-1', 'g-2-1', 'h-2-1');
}

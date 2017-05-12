#!/usr/bin/perl

# a requires b
# b-1 requires c
# b-2 requires d
# d conflicts with c
#
# e-1 requires d
# e-2 requires c
#
use strict;
use lib '.', 't';
use helper;
use urpm::util;
use Test::More 'no_plan';

need_root_and_prepare();

my $name = 'split-transactions--conflict';
urpmi_addmedia("$name-1 $::pwd/media/$name-1");    
urpmi_addmedia("$name-2 $::pwd/media/$name-2");

test('--split-length 0');
test('--split-level 1 --split-length 1');

test_d('--split-length 0');
test_d('--split-level 1 --split-length 1');

test_e('--split-length 0');
test_e('--split-level 1 --split-length 1');

test_ae('--split-length 0');
test_ae('--split-level 1 --split-length 1');

sub test {
    my ($option) = @_;

    urpmi("--media $name-1 --auto a b c");
    check_installed_fullnames('a-1-1', 'b-1-1', 'c-1-1');

    urpmi("--media $name-2 --auto $option --auto-select");
    check_installed_fullnames_and_remove('a-1-1', 'b-2-1', 'd-1-1');
}

sub test_d {
    my ($option) = @_;

    urpmi("--media $name-1 --auto a b c");
    check_installed_fullnames('a-1-1', 'b-1-1', 'c-1-1');

    #- below need the promotion of "b-2" (upgraded from "b-1") to work
    urpmi("--media $name-2 --auto $option d");
    check_installed_fullnames_and_remove('a-1-1', 'b-2-1', 'd-1-1');
}

sub test_e {
    my ($option) = @_;

    urpmi("--media $name-1 --auto e");
    check_installed_fullnames('d-1-1', 'e-1-1');

    #- below need the promotion of "e-2" (upgraded from "e-1") to work
    urpmi("--media $name-2 --auto $option c");
    check_installed_fullnames_and_remove('c-1-1', 'e-2-1');
}

sub test_ae {
    my ($option) = @_;

    urpmi("--auto a");
    check_installed_fullnames_and_remove('a-1-1', 'b-2-1', 'd-1-1');

    urpmi("--media $name-2 --auto $option e");
    check_installed_fullnames_and_remove('c-1-1', 'e-2-1'); # no other solution
}

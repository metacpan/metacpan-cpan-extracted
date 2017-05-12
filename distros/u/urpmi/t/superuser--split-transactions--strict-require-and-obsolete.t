#!/usr/bin/perl

# a requires b : bb or b
# bb requires c-1
# b requires c-2
# b obsoletes bb
#
# upgrading { bb, c-1 } to { b, c-2 } must be done in the same transaction,
# otherwise { c-1 } to { c-2 } implies removing { a, bb }
use strict;
use lib '.', 't';
use helper;
use urpm::util;
use Test::More 'no_plan';

need_root_and_prepare();

my $name = 'split-transactions--strict-require-and-obsolete';
urpmi_addmedia("$name-1 $::pwd/media/$name-1");    
urpmi_addmedia("$name-2 $::pwd/media/$name-2");

test('--split-length 0');
test('--split-level 1 --split-length 1'); # was broken (#31969)

test_c('--split-length 0');
test_c('--split-level 1 --split-length 1');

sub test {
    my ($option) = @_;

    urpmi("--media $name-1 --auto a");
    check_installed_fullnames('a-1-1', 'bb-1-1', 'c-1-1');

    urpmi("--media $name-2 $option --auto --auto-select");
    check_installed_fullnames_and_remove('a-1-1', 'b-2-1', 'c-2-1');
}

sub test_c {
    my ($option) = @_;

    urpmi("--media $name-1 --auto a");
    check_installed_fullnames('a-1-1', 'bb-1-1', 'c-1-1');

    #- below need the promotion of "b" (obsoleting bb) to work
    urpmi("--media $name-2 $option --auto c");
    check_installed_fullnames_and_remove('a-1-1', 'b-2-1', 'c-2-1');
}

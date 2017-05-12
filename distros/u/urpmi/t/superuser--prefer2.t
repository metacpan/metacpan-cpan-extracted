#!/usr/bin/perl

# testcase for bug #46874
# a requires both bb and b2
# bb is provided by both b1 and b2
# => b1 must be picked over b2
#
# d is the same as a with b1 => c2 and b2 => c1
# (needed to ensure both ordering works)
#
use strict;
use lib '.', 't';
use helper;
use urpm::util;
use Test::More 'no_plan';

need_root_and_prepare();

my $name = 'prefer2';
urpmi_addmedia("$name $::pwd/media/$name");    

test('a', ['a', 'b2']);
test('d', ['d', 'c1']);

sub test {
    my ($pkg, $result) = @_;

    urpmi("--auto $pkg");
    check_installed_and_remove(@$result);
}

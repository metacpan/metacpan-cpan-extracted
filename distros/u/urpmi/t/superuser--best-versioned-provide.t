#!/usr/bin/perl

# a_cc requires cc
# a_dd requires dd
# a_ee requires ee
#
# b1 provides cc = 1, dd = 2, ee = 3
# b2 provides cc = 2, dd = 3, ee = 1
# b3 provides cc = 3, dd = 1, ee = 2
#
# so a_cc should require b3
#    a_dd should require b2
#    a_ee should require b1
#
# (cf mdvbz #12645)
#
use strict;
use lib '.', 't';
use helper;
use Expect;
use urpm::util;
use Test::More 'no_plan';

need_root_and_prepare();

my $medium_name = 'best-versioned-provide';

urpmi_addmedia("$medium_name $::pwd/media/$medium_name");

test('a_cc', 'b3');
test('a_dd', 'b2');
test('a_ee', 'b1');

sub test {
    my ($to_install, $should_be_prefered) = @_;

    urpmi("--auto $to_install");
    check_installed_and_remove($to_install, $should_be_prefered);
}

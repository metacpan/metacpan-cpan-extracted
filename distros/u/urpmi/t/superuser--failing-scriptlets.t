#!/usr/bin/perl

use strict;
use lib '.', 't';
use helper;
use Test::More 'no_plan';
require urpm::select;

my $medium_name = 'failing-scriptlets';

need_root_and_prepare();

test_install_rpm_fail('pre');
#%pretrans scriptlet failure now fails the install of the package (similarly to %pre and %preun semantics):
if (urpm::select::_rpm_version() lt 4.10.0) {
    test_install_rpm('pretrans');
}
test_install_rpm('post');
test_install_rpm('preun');
test_install_rpm('postun');
test_install_rpm('posttrans');

test_install_upgrade_rpm('triggerprein');
test_install_upgrade_rpm('triggerin');
test_install_upgrade_rpm('triggerun');
test_install_upgrade_rpm('triggerpostun');

sub test_install_rpm {
    my ($name) = @_;
    system_("rpm --root $::pwd/root -i media/$medium_name/$name-*.rpm");
    check_installed_fullnames_and_remove("$name-1-1");
}
sub test_install_rpm_fail {
    my ($name) = @_;
    system_should_fail("rpm --root $::pwd/root -i media/$medium_name/$name-*.rpm");
    check_nothing_installed();
}

sub test_install_upgrade_rpm {
    my ($name) = @_;

    system_("rpm --root $::pwd/root -i media/$medium_name/$name-1-*.rpm");
    check_installed_fullnames("$name-1-1");
    system_("rpm --root $::pwd/root -U media/$medium_name/$name-2-*.rpm");
    check_installed_fullnames_and_remove("$name-2-1");
}

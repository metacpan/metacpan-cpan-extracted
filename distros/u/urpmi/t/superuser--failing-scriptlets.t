#!/usr/bin/perl

use strict;
use lib '.', 't';
use helper;
use Test::More 'no_plan';

my $medium_name = 'failing-scriptlets';

need_root_and_prepare();

test_install_rpm_fail('pre');
test_install_rpm_fail('pretrans');
test_install_rpm('post');
require urpm::select;
if (urpm::select::_rpm_version() lt 4.13.0 && -e '/etc/mageia-release') {
    test_install_rpm('preun');
} else {
    test_install_rpm_but_uninstall_fail('preun');
}
test_install_rpm('postun');
test_install_rpm('posttrans');

test_install_upgrade_rpm('triggerprein');
test_install_upgrade_rpm('triggerin');
test_install_upgrade_rpm('triggerun');
test_install_upgrade_rpm('triggerpostun');

sub test_install_rpm {
    my ($name) = @_;
    test_install_rpm_no_remove('sh');
    system_("rpm --root $::pwd/root -i media/$medium_name/$name-*.rpm");
    check_installed_fullnames_and_remove("$name-1-1", "sh-1-1");
}
sub test_install_rpm_no_remove {
    my ($name) = @_;
    system_("rpm --root $::pwd/root -i media/$medium_name/$name-*.rpm");
    check_installed_fullnames("$name-1-1");
}
sub test_install_rpm_fail {
    my ($name) = @_;
    test_install_rpm_no_remove('sh');
    system_should_fail("rpm --root $::pwd/root -i media/$medium_name/$name-*.rpm");
    check_installed_fullnames_and_remove("sh-1-1");
}

sub test_install_rpm_but_uninstall_fail {
    my ($name) = @_;
    test_install_rpm_no_remove('sh');
    system_("rpm --root $::pwd/root -i media/$medium_name/$name-*.rpm");
    check_installed_fullnames("$name-1-1", "sh-1-1");
    system_should_fail("rpm --root $::pwd/root -e $name");
    system_("rpm --root $::pwd/root -e $name --nopreun");
    check_installed_fullnames_and_remove("sh-1-1");
}

sub test_install_upgrade_rpm {
    my ($name) = @_;

    test_install_rpm_no_remove('sh');
    system_("rpm --root $::pwd/root -i media/$medium_name/$name-1-*.rpm");
    check_installed_fullnames("$name-1-1", "sh-1-1");
    system_("rpm --root $::pwd/root -U media/$medium_name/$name-2-*.rpm");
    check_installed_fullnames_and_remove("$name-2-1", "sh-1-1");
}

#!/usr/bin/perl

use strict;
use lib '.', 't';
use helper;
use Test::More 'no_plan';

my $medium_name = 'rpmnew';

my @names = ('config-noreplace', 'config', 'normal');

need_root_and_prepare();

my $rpm_cmd = "rpm --root $::pwd/root -U";
my $urpmi_cmd = urpmi_cmd();

test1($rpm_cmd);
test2($rpm_cmd);
test3($rpm_cmd);
test1($urpmi_cmd);
test2($urpmi_cmd);
test3($urpmi_cmd);

sub test1 {
    my ($cmd) = @_;

    test($cmd,
	 ['orig', 'orig', 'orig'],
	 ['orig', 'orig', 'orig'],
	 ['changed', 'changed', 'changed']);

    check_no_etc_files();
}

sub test2 {
    my ($cmd) = @_;

    mkdir "$::pwd/root/etc";
    system("echo orig > $::pwd/root/etc/$_") foreach @names;

    test($cmd,
	 ['orig', 'orig', 'orig'],
	 ['orig', 'orig', 'orig'],
	 ['changed', 'changed', 'changed']);

    check_no_etc_files();
}

sub test3 {
    my ($cmd) = @_;

    mkdir "$::pwd/root/etc";
    system("echo foo > $::pwd/root/etc/$_") foreach @names;

    test($cmd, 
	 ['foo', 'orig', 'orig'],
	 ['foo', 'orig', 'orig'],
	 ['foo', 'changed', 'changed']);

    check_one_content('<removed>', 'config.rpmorig', 'foo');
    check_one_content('<removed>', 'config-noreplace.rpmsave', 'foo');
    check_one_content('<removed>', 'config-noreplace.rpmnew', 'changed');
    ok(unlink "$::pwd/root/etc/config.rpmorig");
    ok(unlink "$::pwd/root/etc/config-noreplace.rpmsave");
    ok(unlink "$::pwd/root/etc/config-noreplace.rpmnew");

    check_no_etc_files();
}

sub check_no_etc_files() {
    if (my @l = grep { !m!/urpmi|rpm$! } glob("$::pwd/root/etc/*")) {
	fail(join(' ', @l) . " files should not be there");
    }
}

sub check_content {
    my ($rpm, $config_noreplace, $config, $normal) = @_;

    check_one_content($rpm, 'config-noreplace', $config_noreplace);
    check_one_content($rpm, 'config', $config);
    check_one_content($rpm, 'normal', $normal);
}

sub check_one_content {
    my ($rpm, $name, $val) = @_;
    my $s = `cat $::pwd/root/etc/$name`;
    chomp $s;
    is($s, $val, "$name for $rpm");
}

sub test {
    my ($cmd, $v1, $v2, $v3) = @_;

    system_("$cmd media/$medium_name/a-1-*.rpm");
    check_installed_fullnames("a-1-1");
    check_content('a-1', @$v1);

    system_("$cmd media/$medium_name/a-2-*.rpm");
    check_installed_fullnames("a-2-1");
    check_content('a-2', @$v2);

    system_("$cmd media/$medium_name/a-3-*.rpm");
    check_installed_fullnames("a-3-1");
    check_content('a-3', @$v3);

    system_("rpm --root $::pwd/root -e a");
}

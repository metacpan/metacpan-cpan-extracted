#!/usr/bin/perl

# a and b contains the same file name, with different content => should fail
# a and c contents the same file name, with same content => should work
# a and d contents the same directory name => should work
# a and e contents the same path for a directory vs a symlink => should fail
# 
# fa and fb contains the same file name, with different content but %ghost => should work
#
# a and gc/gc_/gd contains different file => should work
# ga and a and gc/gc_ contains the same resulting file, through symlink in ga, with same content => should work
# ga and a and gd contains the same resulting file, through symlink in ga, with different content => should fail
#
# h and i file conflicts, but on a manpage

use strict;
use lib '.', 't';
use helper;
use Expect;
use urpm::util;
use Test::More 'no_plan';

need_root_and_prepare();

my $medium_name = 'file-conflicts';

urpmi_addmedia("$medium_name $::pwd/media/$medium_name");


test_rpm_same_transaction();
test_rpm_different_transactions();

test_urpmi_same_transaction();
test_urpmi_different_transactions();

sub test_rpm_same_transaction() {

    test_rpm_i_fail('a', 'b');
    check_nothing_installed();

    test_rpm_i_succeeds('a', 'c');
    check_installed_and_remove('a', 'c');

    test_rpm_i_succeeds('a', 'd');
    check_installed_and_remove('a', 'd');

    test_rpm_i_fail('a', 'e');
    check_nothing_installed();

    test_rpm_i_succeeds('a', 'fa');
    check_installed_and_remove('a', 'fa');

    test_rpm_i_succeeds('fa', 'fb');
    check_installed_and_remove('fa', 'fb');

    # Mageia's rpm is patched in order to not conflict for doc files:
    if (is_mageia()) {
	test_rpm_i_succeeds('h', 'i');
	check_installed_and_remove('h', 'i');
    } else {
	test_rpm_i_fail('h', 'i');
	check_nothing_installed();
    }
}

sub test_rpm_different_transactions() {
    test_rpm_i_succeeds('a');
    test_rpm_i_fail('b');
    check_installed_names('a');

    test_rpm_i_fail('e');
    check_installed_names('a');

    test_rpm_i_succeeds('c');
    check_installed_and_remove('a', 'c');

    test_rpm_i_succeeds('a');
    test_rpm_i_succeeds('d');
    check_installed_and_remove('a', 'd');

    test_rpm_i_succeeds('a');
    test_rpm_i_succeeds('fa');
    check_installed_and_remove('a', 'fa');

    test_rpm_i_succeeds('fa');
    test_rpm_i_succeeds('fb');
    check_installed_and_remove('fa', 'fb');

    # the following need to be done in different transactions otherwise rpm is lost
    test_rpm_i_succeeds('a');
    test_rpm_i_succeeds('gd');
    check_installed_and_remove('a', 'gd');
    rmdir 'root/etc/dir_symlink'; # remove unowned directory
    check_no_etc_files();
    
    test_rpm_i_succeeds('a', 'ga');
    #test_rpm_i_fail('gd'); # WARNING: broken by rpm patch rpm-4.4.8-speedup-by-not-checking-same-files-with-different-paths-through-symlink.patch
    check_installed_names('a', 'ga');

    test_rpm_i_succeeds('gc');
    test_rpm_i_succeeds('gc_');
    check_installed_names('a', 'ga', 'gc', 'gc_');
    urpme('gc gc_'); # if you remove gc and a/ga at the same time, hell can happen...
    check_installed_and_remove('a', 'ga');
    check_no_etc_files();

    # Mageia's rpm is patched in order to not conflict for doc files:
    if (is_mageia()) {
	test_rpm_i_succeeds('h');
	test_rpm_i_succeeds('i');
	check_installed_and_remove('h', 'i');
    }
}

sub test_urpmi_same_transaction() {
    # Mageia's rpm is patched in order to not conflict for doc files:
    if (is_mageia()) {
	test_urpmi_fail('a b');
	check_nothing_installed();
    }

    urpmi('a c');
    check_installed_and_remove('a', 'c');

    urpmi('a d');
    check_installed_and_remove('a', 'd');

    test_urpmi_fail('a e');
    check_nothing_installed();

    urpmi('a fa');
    check_installed_and_remove('a', 'fa');

    urpmi('fa fb');
    check_installed_and_remove('fa', 'fb');

    # Mageia's rpm is patched in order to not conflict for doc files:
    if (is_mageia()) {
	urpmi('h i');
	check_installed_and_remove('h', 'i');
    }
}

sub test_urpmi_different_transactions() {
    urpmi('a');
    test_urpmi_fail('b');
    check_installed_names('a');

    test_urpmi_fail('e');
    check_installed_names('a');

    # fail when dropping RPMTAG_FILEDIGESTS
    urpmi('c');
    check_installed_and_remove('a', 'c');

    urpmi('a');
    urpmi('d');
    check_installed_and_remove('a', 'd');

    urpmi('a');
    urpmi('fa');
    check_installed_and_remove('a', 'fa');

    urpmi('fa');
    urpmi('fb');
    check_installed_and_remove('fa', 'fb');

    # the following need to be done in different transactions otherwise rpm is lost
    urpmi('a');
    urpmi('gd');
    check_installed_and_remove('a', 'gd');
    rmdir 'root/etc/dir_symlink'; # remove unowned directory
    check_no_etc_files();
    
    urpmi('a ga');
    #test_urpmi_fail('gd'); # WARNING: broken by rpm patch rpm-4.4.8-speedup-by-not-checking-same-files-with-different-paths-through-symlink.patch
    check_installed_names('a', 'ga');

    urpmi('gc');
    urpmi('gc_');
    check_installed_names('a', 'ga', 'gc', 'gc_');
    urpme('gc gc_'); # if you remove gc and a/ga at the same time, hell can happen...
    check_installed_and_remove('a', 'ga');
    check_no_etc_files();

    # Mageia's rpm is patched in order to not conflict for doc files:
    if (is_mageia()) {
	   urpmi('h');
	   urpmi('i');
	   check_installed_and_remove('h', 'i');
    }
}

sub test_rpm_i_succeeds {
    my (@rpms) = @_;
    my $rpms = join(' ', map { "media/$medium_name/$_-*.rpm" } @rpms);
    system_("rpm --root $::pwd/root -i $rpms");
}
sub test_rpm_i_fail {
    my (@rpms) = @_;
    my $rpms = join(' ', map { "media/$medium_name/$_-*.rpm" } @rpms);
    system_should_fail("rpm --root $::pwd/root -i $rpms");
}
sub check_no_etc_files() {
    if (my @l = grep { !m!/urpmi|rpm$! } glob("$::pwd/root/etc/*")) {
	fail(join(' ', @l) . " files should not be there");
    }
}

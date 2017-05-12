#!/usr/bin/perl

# a-1 requires b-1
# a-2 requires b-2
#
# c requires d
# d1-1 provides d, but not d1-2
# d2-2 provides d, but not d2-1
#
# e-2 conflicts with f-1
#
# h-1 conflicts with g-2
#
# i requires j
# j1 provides j and requires k
# j2 provides j
# k1-1 provides k, but not k1-2
#
# l-1 and l-2 requires k
# m-1 requires k but not m-2
# n requires m
#
use strict;
use lib '.', 't';
use helper;
use urpm::util;
use Test::More 'no_plan';

need_root_and_prepare();

my $name = 'split-transactions--promote';
urpmi_addmedia("$name-1 $::pwd/media/$name-1");    
urpmi_addmedia("$name-2 $::pwd/media/$name-2");

test('--split-length 0');
test('--split-level 1 --split-length 1');
test_conflict();

sub test {
    my ($split) = @_;

    test_ab("$split --auto-select");

    #- below need the promotion of "a-2" (upgraded from "a-1") to work
    test_ab("$split b");

    #- below need the promotion of "d2" (new installed package) to work
    test_cd("$split d1");

    #- below need the promotion of "f-2" (upgraded from "f-1") to work
    test_ef("$split e");

    #- below need the promotion of "h-2" (upgraded from "h-1") to work
    test_gh("$split g");

    #- below need the promotion of "j2" (replacing removed j1) to work
    test_ijk("$split k1");

    #- below tests for bug #52667
    #- transactions created with only k1 upgrade caused n to be removed
    test_klm("$split --auto-select");
    test_klm("$split k1");
}
sub test_conflict {
    test_conflict_ef();
    test_conflict_gh();
}

sub test_ab {
    my ($para) = @_;

    urpmi("--media $name-1 --auto a b");
    check_installed_names('a', 'b');

    urpmi("--media $name-2 --auto $para");
    check_installed_fullnames_and_remove('a-2-1', 'b-2-1');
}

sub test_cd {
    my ($para) = @_;

    urpmi("--media $name-1 --auto c");
    check_installed_names('c', 'd1');

    urpmi("--media $name-2 --auto $para");
    check_installed_fullnames_and_remove('c-1-1', 'd1-2-1', 'd2-2-1');
}

sub test_ef {
    my ($para) = @_;

    urpmi("--media $name-1 --auto e f");
    check_installed_names('f', 'e');

    urpmi("--media $name-2 --auto $para");
    check_installed_fullnames_and_remove('e-2-1', 'f-2-1');
}

sub test_gh {
    my ($para) = @_;

    urpmi("--media $name-1 --auto g h");
    check_installed_names('g', 'h');

    urpmi("--media $name-2 --auto $para");
    check_installed_fullnames_and_remove('g-2-1', 'h-2-1');
}

sub test_ijk {
    my ($para) = @_;

    urpmi("--media $name-1 --auto i");
    check_installed_names('i', 'j1', 'k1');

    urpmi("--media $name-2 --auto $para");
    check_installed_fullnames_and_remove('i-1-1', 'j2-1-1', 'k1-2-1');
}

sub test_klm {
    my ($para) = @_;
    urpmi("--media $name-1 --auto l");
    urpmi("--media $name-1 --auto n"); # separated in order to force install order
    check_installed_names('k1', 'l', 'm', 'n');

    my $output = run_urpm_cmd("urpmi --media $name-2 --auto $para 2>&1");
    ok($output !~ /transaction is too small/, "test_klm transaction validity");
    ok($output !~ /due to missing m/, "do not ask for removal of n"); # false message
    # installation was always ok, just transactions and messages above were wrong
    check_installed_fullnames_and_remove('k1-2-1', 'm-2-1', 'n-1-1');
}

sub test_conflict_ef {
    my ($para) = @_;

    urpmi("--media $name-1 f");
    check_installed_names('f');

    my @reasons = run_urpmi_and_get_conflicts("--media $name-1 --auto media/$name-2/e-2-*.rpm");
    $reasons[0] =~ s/\.\w+$//; # get rid of arch
    my $wanted = 'e-2-1';
    ok($reasons[0] eq $wanted, "$wanted in @reasons");
    check_installed_fullnames_and_remove('e-2-1');
}

sub test_conflict_gh {
    my ($para) = @_;

    urpmi("--media $name-1 h");
    check_installed_names('h');

    my @reasons = run_urpmi_and_get_conflicts("--media $name-1 --auto media/$name-2/g-2-*.rpm");
    my $wanted = 'g[> 1]';
    ok($reasons[0] eq $wanted, "$wanted in @reasons");
    check_installed_fullnames_and_remove('g-2-1');
}

sub run_urpmi_and_get_conflicts {
    my ($para) = @_;
    my $output = run_urpm_cmd("urpmi $para");
    $output =~ /\(due to conflicts with (.*)\)/g;
}

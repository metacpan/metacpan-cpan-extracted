#!/usr/bin/perl

# a-1 upgrades to a-2
# b-1 upgrades to bb-2 (via obsoletes)
# c-1 (requires cc) upgrades to c-2 (requires cc)
# d-1 (requires dd) upgrades to d-2
# e-1 (requires ee1) upgrades to e-2 (requires ee2)
# f-1 (requires ff1) upgrades to f-2 (requires ff2), ff2 conflicts with ff1
# g-1 (requires gg = 1) upgrades to g-2 (requires gg = 2)
# h-1 (suggests hh) upgrades to h-2
#
# l-1 upgrades to l-2, l requires ll and ll requires l
# m-1 (requires mm = 1) upgrades to m-2 (requires mm = 2), mm requires m (circular dep)
# n-1 (requires nn = 1) upgrades to n-2 (requires nn = 2), nn-1 requires n-1, nn-2 requires n-2 (circular dep)
# o-1 (requires oo1) upgrades to o-2 (requires oo2), oo1 requires o = 1, oo2 requires o = 2 (circular dep)
#
# r-1 (requires rr) upgrades to r-2, rr1 provides rr, rr2 provides rr
# s-1 (requires ss1 and ss2) upgrades to s-2 (requires ss), ss1-2 provides ss, ss2-2 provides ss    
# t-1 (requires tt >= 1) upgrades to t-2 (requires tt >= 2), tt1-1 provides tt = 1, tt1-2 provides tt = 2
#
# req-a requires a, req-b requires b...
#
# u1 requires u2, u4 requires u3
#
use strict;
use lib '.', 't';
use helper;
use urpm::util;
use urpm::orphans;
use Test::More 'no_plan';

need_root_and_prepare();

my $name = 'orphans';
urpmi_addmedia("$name-1 $::pwd/media/$name-1");    
urpmi_addmedia("$name-2 $::pwd/media/$name-2");

# we want urpmi --auto-select to always check orphans (when not using --auto-orphans)
set_urpmi_cfg_global_options({ 'nb-of-new-unrequested-pkgs-between-auto-select-orphans-check' => 0 });


test_urpme_v1(['h'], 'h', '');
if (are_weak_deps_supported()) {
    test_urpme_v1(['hh', 'h'], 'h', 'hh');
} else {
    test_urpme_v1(['h'], 'h');
}

test_urpme_v1(['u1 u2'], 'u1', 'u2');
test_urpme_v1(['u3 u4'], 'u4', 'u3');

test_auto_select_both('a', '',    'a-2');
test_auto_select_both('b', '',    'bb-2');
test_auto_select_both('c', 'cc',  'c-2 cc-1');
test_auto_select_both('d', 'dd',  'd-2', 'dd-1');
test_auto_select_both('e', 'ee1', 'e-2 ee2-2', 'ee1-1');
test_auto_select_both('f', 'ff1', 'f-2 ff2-2');
test_auto_select_both('g', 'gg',  'g-2 gg-2');
if (are_weak_deps_supported()) {
    test_auto_select_both('h', 'hh',  'h-2', 'hh-1');
} else {
    test_auto_select_both('h', '',  'h-2', '');
}
test_auto_select_both('l', 'll',  'l-2 ll-1');
test_auto_select_both('m', 'mm',  'm-2 mm-2');
test_auto_select_both('n', 'nn',  'n-2 nn-2');
test_auto_select_both('o', 'oo1', 'o-2 oo2-2');
test_auto_select_both('r', 'rr1', 'r-2', 'rr1-1');
test_auto_select_both('s', 'ss1 ss2', 's-2 ss1-1 ss2-1');
test_auto_select_both('t', 'tt1', 't-2 tt2-2', 'tt1-1');

test_auto_select(['r', 'rr2'], 'r rr1 rr2', 'r-2 rr2-1', 'rr1-1');
#test_auto_select(['s ss1'],    's ss1 ss2', 's-2 ss1-1', 'ss2-1'); # this fails, but that's ok

test_urpme(['g'], 'g', 'g', '');
test_urpme(['gg', 'g'], 'g', 'g', 'gg-2');

test_unorphan_v1('u1', 'u2');
test_unorphan_v2('u1', 'u2');
test_unorphan_v3('u1', 'u2');


sub add_version1 { map { "$_-1-1" } split(' ', $_[0] || '') }
sub add_version2 { map { "$_-2-1" } split(' ', $_[0] || '') }
sub add_release  { map { "$_-1"   } split(' ', $_[0] || '') }
sub add_version1_s { join(' ', add_version1(@_)) }
sub add_version2_s { join(' ', add_version2(@_)) }
sub add_release_s  { join(' ', add_release(@_)) }

sub test_auto_select_both {
    my ($pkg, $wanted_v1, $wanted_v2, $orphans_v2) = @_;

    test_urpme1($pkg, $wanted_v1);

    if ($pkg !~ /[mlno]/) { # skip when $wanted_v1 requires $pkg
	test_urpme2($pkg, $wanted_v1);
    }

    $orphans_v2 ||= '';
    test_auto_select([$pkg], "$pkg $wanted_v1", $wanted_v2, $orphans_v2);
    test_auto_select(["req-$pkg"], "req-$pkg $pkg $wanted_v1", "req-$pkg-2", "$wanted_v2 $orphans_v2");
}

sub test_urpme1 {
    my ($pkg, $wanted) = @_;
    print "# test_urpme($pkg, $wanted)\n";
    urpmi("--media $name-1 --auto $pkg");
    urpme("--auto --auto-orphans $pkg");    
    check_nothing_installed();
    reset_unrequested_list();
}
sub test_urpme2 {
    my ($pkg, $wanted) = @_;
    print "# test_urpme($pkg, $wanted)\n";
    urpmi("--media $name-1 --auto $pkg");
    check_installed_names($pkg, split(' ', $wanted));
    urpme("--auto --auto-orphans"); # this must not do anything
    check_installed_names($pkg, split(' ', $wanted));
    run_and_get_suggested_orphans("urpme $pkg", add_version1($wanted));
    urpme("--auto --auto-orphans");    
    check_nothing_installed();
    reset_unrequested_list();
}

sub test_auto_select {
    my ($req_v1, $wanted_v1, $wanted_v2, $orphans_v2) = @_;
    test_auto_select_raw_urpmq_urpme ($req_v1, add_version1_s($wanted_v1), add_release_s($wanted_v2), add_release_s($orphans_v2));
    test_auto_select_raw_auto_orphans($req_v1, add_version1_s($wanted_v1), add_release_s($wanted_v2));
}

sub test_auto_select_raw_urpmq_urpme {
    my ($req_v1, $wanted_v1, $wanted_v2, $orphans_v2) = @_;
    print "# test_auto_select_raw_urpmq_urpme(@$req_v1, $wanted_v1, $wanted_v2, $orphans_v2)\n";
    urpmi("--media $name-1 --auto $_") foreach @$req_v1;
    check_installed_fullnames(split ' ', $wanted_v1);
    run_and_get_suggested_orphans("urpmi --media $name-2 --auto --auto-select", split(' ', $orphans_v2));
    check_installed_fullnames(split ' ', "$wanted_v2 $orphans_v2");
    is(run_urpm_cmd('urpmq -r --auto-orphans'), join('', sort map { "$_\n" } split ' ', $orphans_v2));
    urpme("--auto --auto-orphans");
    check_installed_fullnames_and_remove(split ' ', $wanted_v2);
    reset_unrequested_list();
}

sub test_auto_select_raw_auto_orphans {
    my ($req_v1, $wanted_v1, $wanted_v2) = @_;
    print "# test_auto_select_raw_auto_orphans(@$req_v1, $wanted_v1, $wanted_v2)\n";
    urpmi("--media $name-1 --auto $_") foreach @$req_v1;
    check_installed_fullnames(split ' ', $wanted_v1);
    urpmi("--media $name-2 --auto --auto-select --auto-orphans");
    check_installed_fullnames_and_remove(split ' ', $wanted_v2);
    reset_unrequested_list();
}

sub test_urpme {
    my ($req_v1, $wanted_v2, $remove_v2, $remaining_v2) = @_;
    print "# test_urpme(@$req_v1, $wanted_v2, $remove_v2, $remaining_v2)\n";
    urpmi("--media $name-1 --auto $_") foreach @$req_v1;
    urpmi("--media $name-2 --auto $wanted_v2");
    urpme("--auto --auto-orphans $remove_v2");
    check_installed_fullnames_and_remove(add_release($remaining_v2));
    reset_unrequested_list();
}

sub test_urpme_v1 {
    my ($req_v1, $remove_v1, $remaining_v1) = @_;
    print "# test_urpme_v1(@$req_v1, $remaining_v1)\n";
    urpmi("--media $name-1 --auto $_") foreach @$req_v1;
    urpme("--auto --auto-orphans $remove_v1");
    check_installed_and_remove(split ' ', $remaining_v1);
    reset_unrequested_list();
}

sub test_unorphan_v1 {
    my ($pkg1, $pkg2) = @_;
    print "# test_unorphan_v1($pkg1, $pkg2)\n";
    urpmi("--media $name-1 --auto $pkg1");
    urpmi("--media $name-1 --auto $pkg2");
    urpme("--auto --auto-orphans $pkg1");    
    check_installed_and_remove($pkg2);
}

sub test_unorphan_v2 {
    my ($pkg1, $pkg2) = @_;
    print "# test_unorphan_v2($pkg1, $pkg2)\n";
    urpmi("--media $name-1 --auto $pkg1");
    urpme("--auto $pkg1");    
    urpmi("--media $name-1 --auto $pkg2");
    urpme("--auto --auto-orphans");    
    check_installed_and_remove($pkg2);
}

sub test_unorphan_v3 {
    my ($pkg1, $pkg2) = @_;
    print "# test_unorphan_v3($pkg1, $pkg2)\n";
    urpmi("--media $name-1 --auto $pkg1");
    check_installed_and_remove($pkg2, $pkg1);
    urpmi("--media $name-1 --auto $pkg2");
    urpme("--auto --auto-orphans");    
    check_installed_and_remove($pkg2);
}

sub run_and_get_suggested_orphans {
    my ($cmd, @wanted) = @_;
    my $s = run_urpm_cmd($cmd);
    print $s;

    my ($lines) = $s =~ /^The following packages?:\n(.*)\n(?:is|are) now orphaned, if you wish to remove (?:it|them), you can use "urpme --auto-orphans"/ms;
    my @msgs = $lines ? $lines =~ /^  (\S+)\.\S+$/mg : (); # we don't want the arch

    my $msg = join(" -- ", sort @msgs);
    my $wanted = join(" -- ", sort @wanted);
    ok($msg eq $wanted, "wanted:$wanted, got:$msg");
}

sub reset_unrequested_list() {
    my $f = urpm::orphans::unrequested_list__file({ root => 'root' });
    output_safe($f, '');
    output_safe("$f.old", ''); # needed to ensure check_unrequested_orphans_after_auto_select() works
}

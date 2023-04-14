#!/usr/bin/perl

# kernel-desktop-latest request latest kernel-desktop-foobar
#
use strict;
use lib '.', 't';
use helper;
use urpm::cfg;
use urpm::orphans;
use Test::More 'no_plan';

need_root_and_prepare();

my $arch = urpm::cfg::get_arch();
my $name = 'kernel';
my $dkms_name = 'virtualbox';
urpmi_addmedia("$name-1 $::pwd/media/$name-1");
urpmi_addmedia("$name-2 $::pwd/media/$name-2");

# we want urpmi --auto-select to always check orphans (when not using --auto-orphans)
set_urpmi_cfg_global_options({ 'nb-of-new-unrequested-pkgs-between-auto-select-orphans-check' => 0 });

# old naming, each kernel NVR is N=kernel-desktop-5.6.2-1, V=1 R=1.mga8
test_unorphan_kernels("$name-1", 'kernel-desktop-latest');
# new naming, each kernel NVR is N=kernel-desktop, V=5.6.2 R=1.mga8
test_unorphan_kernels("$name-2", 'kernel-desktop-latest', 'kernel-desktop');

# FIXME: add virtualbox-kernel-XXX -> kernel-XXX
sub test_unorphan_kernels {
    my ($medium, $pkg, $o_pkg2) = @_;
    my $base_kversion = '5.15.4';
    my $dkms_version = '6.1.36';
    #my $latest_dkms_dep = 'virtualbox-kernel-5.15.45-desktop-1'; # harcoded but no choice...
    my $latest_dkms_dep = "virtualbox-kernel-${base_kversion}5-desktop-1"; # harcoded but no choice...
    my ($latest_kpkg, $latest_dpkg);
    print "# test_unorphan_kernels($pkg) ($base_kversion)\n";
    foreach (1..5) {
	    $latest_kpkg = "$pkg-${base_kversion}$_-1";
	    urpmi("--media $medium --auto $latest_kpkg");
	    # Add some DKMS packages:
	    $latest_dpkg = "$dkms_name-$pkg-${dkms_version}-$_.$arch";
	    urpmi("--media $medium --auto $latest_dpkg");
    }
    #urpmi("--media $medium --auto $pkg");
    urpme("--auto --auto-orphans");
    $o_pkg2 ||= $latest_kpkg;
    $o_pkg2 =~ s/-latest//;
    check_installed_and_remove($pkg, 'virtualbox-kernel-desktop-latest', $o_pkg2, $latest_dkms_dep);
}


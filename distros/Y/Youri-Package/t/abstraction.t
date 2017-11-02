#!/usr/bin/perl

use strict;

use File::Temp qw/tempdir/;
use Test::More;
use UNIVERSAL::require;
use Youri::Package::RPM;
use Youri::Package::RPM::Generator;

plan(skip_all => 'neither RPM4 nor RPM available, skipping')
    unless RPM4->require() or RPM->require();

plan tests => 1;

my $topdir = tempdir(CLEANUP => $ENV{TEST_DEBUG} ? 0 : 1);
my ($package)  = Youri::Package::RPM::Generator->new(tags => {
    name      => 'test',
    version   => '1.0',
    release   => '1',
    buildarch => 'noarch'
})->get_source();

my $wrapper_class = Youri::Package::RPM->get_wrapper_class();

my %rpm_dirs = (
    sourcedir => 'SOURCES',
    patchdir  => 'SOURCES',
    specdir   => 'SPECS',
    builddir  => 'BUILD',
    rpmdir    => 'RPMS',
    srcrpmdir => 'SRPMS',
);

foreach my $name (keys %rpm_dirs) {
    my $value = $topdir . '/' . $rpm_dirs{$name};
    $wrapper_class->add_macro("_$name $value");
}

$wrapper_class->install_srpm($package);

my @subdirs = <$topdir/*>;
is (@subdirs, 1, 'installation tree state');

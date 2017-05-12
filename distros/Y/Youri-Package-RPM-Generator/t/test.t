#!/usr/bin/perl
# $Id: test.t 2377 2013-01-03 20:12:35Z guillomovitch $

use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Spec;
use File::Which;
use URPM;

plan(skip_all => 'unable to find rpmbuild; skipping')
    if !which('rpmbuild');

plan(tests => 13);

use_ok('Youri::Package::RPM::Generator');

my $generator = Youri::Package::RPM::Generator->new();
isa_ok($generator, 'Youri::Package::RPM::Generator');

my $urpm = URPM->new();

my $src_rpm;
lives_ok {
    $src_rpm = $generator->get_source()
} 'generating source package works';
ok(-f $src_rpm, 'source package exists');
$urpm->parse_rpm($src_rpm, keep_all_tags => 1);
my $src_header = $urpm->{depslist}->[0];
isa_ok($src_header, 'URPM::Package');
is($src_header->name(), 'test', 'expected name');
is($src_header->version(), '1', 'expected version');
is($src_header->release(), '1', 'expected release');
is($src_header->arch(), 'src', 'expected arch');

my @binary_rpms;
lives_ok {
    @binary_rpms = $generator->get_binaries()
} 'generating binary packages works';
is(scalar @binary_rpms, 2, 'two package');
my $binary_rpm = $binary_rpms[0];
ok(-f $binary_rpm, 'binary package exists');
$urpm->parse_rpm($binary_rpm, keep_all_tags => 1);
my $binary_header = $urpm->{depslist}->[1];
isa_ok($binary_header, 'URPM::Package');

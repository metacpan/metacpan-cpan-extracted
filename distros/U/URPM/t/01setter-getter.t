#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 64;
use URPM;


chdir 't' if -d 't';

my $u = URPM->new;
ok($u, 'URPM');

$u->parse_rpm("tmp/RPMS/noarch/test-rpm-1.0-1mdk.noarch.rpm");
ok(@{$u->{depslist}} == 1, 'depslist');

my $pkg = $u->{depslist}[0];
ok($pkg, 'Package');
is($pkg->payload_format, 'cpio', 'payload');

is($pkg->rflags, undef, 'default rflags');
is($pkg->set_rflags(1, 3), undef, 'storing rflags');
is(join(',', $pkg->set_rflags(1, 4)), "1,3", 'storing rflags');
is(join(',', $pkg->rflags), "1,4", 'retrieving stored rflags');

########################################

test_flags($pkg, ());

$pkg->set_flag_skip;
test_flags($pkg, skip => 33554432);
$pkg->set_flag_skip(0);

$pkg->set_flag_base;
test_flags($pkg, base => 16777216);
$pkg->set_flag_base(0);

$pkg->set_flag_installed;
test_flags($pkg, installed => 134217728);
$pkg->set_flag_installed(0);

$pkg->set_flag_upgrade;
test_flags($pkg, upgrade => 1073741824);
$pkg->set_flag_upgrade(0);

$pkg->set_flag_required;
test_flags($pkg, required => 536870912);
$pkg->set_flag_required(0);

$pkg->set_flag_requested;
test_flags($pkg, requested => 268435456);
$pkg->set_flag_requested(0);

$pkg->set_flag_disable_obsolete;
test_flags($pkg, disable_obsolete => 67108864);
$pkg->set_flag_disable_obsolete(0);

sub test_flags {
    my ($pkg, %flags) = @_;
    is($pkg->flag_base, $flags{base} || 0, 'base flag');
    is($pkg->flag_skip, $flags{skip} || 0, 'skip flag');
    is($pkg->flag_disable_obsolete, $flags{disable_obsolete} || 0, 'disable_obsolete flag');
    is($pkg->flag_installed, $flags{installed} || 0, 'installed flag');
    is($pkg->flag_requested, $flags{requested} || 0, 'requested flag');
    is($pkg->flag_required, $flags{required} || 0, 'required flag');
    is($pkg->flag_upgrade, $flags{upgrade} || 0, 'upgrade flag');
}




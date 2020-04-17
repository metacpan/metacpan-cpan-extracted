#!/usr/bin/perl

use strict;
use lib '.', 't';
use helper;
use Test::More 'no_plan';
BEGIN { use_ok "URPM" }

need_root_and_prepare();

#- things are going to be noisy, and that's normal
open STDERR, '>/dev/null';

my @pkgs = map { "data/rpm-buggy/$_" } 'invalid-signature.rpm', 'not-a-rpm.rpm', 'weird-header.rpm';
foreach (@pkgs) {
    # rpm-4.14.2's errors messages mess up with TAP:
    system("rpm -K $_ &>/dev/null");
    is($?, 1 << 8, "rpm -K $_");

    system(urpmi_cmd() . " $_");
    is($?, 2 << 8, "urpmi $_");

    my $verif = URPM::verify_signature($_);
    ok($verif =~ /NOT OK/, 'signature is OK');
}

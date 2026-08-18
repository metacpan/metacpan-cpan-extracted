#!/bin/perl
#
#  Direct API route isolation coverage.
#
use strict qw(vars);
use warnings;

BEGIN {
    $ENV{'WEBDYNE_CONF'}='.';
    $ENV{'WEBDYNE_HEAD_INSERT'}=0;
}

use Test::More tests => 3;
use File::Spec;
use File::Temp qw(tempdir);
use WebDyne qw(html);

my $tmp_dn=tempdir(CLEANUP => 1);
my $api_fn=File::Spec->catfile($tmp_dn, 'api_route_isolation.psp');
open(my $api_fh, '>', $api_fn) || die "unable to open '$api_fn' for write, $!";
print {$api_fh} <<'END_API';
<api handler=first pattern="/api/first">
<api handler=second pattern="/api/second">
__PERL__
sub first {
    return { route => 'first' };
}
sub second {
    return { route => 'second' };
}
END_API
close($api_fh) || die "unable to close '$api_fn', $!";

local $ENV{'PATH_INFO'}='/api/second';

my $json=html($api_fn);
like($json, qr/"route"\s*:\s*"second"/, 'second API route dispatches to second handler');

$json=html($api_fn);
like($json, qr/"route"\s*:\s*"second"/, 'second API route still dispatches correctly on repeated render');

local $ENV{'PATH_INFO'}='/api/first';
$json=html($api_fn);
like($json, qr/"route"\s*:\s*"first"/, 'first API route dispatches to first handler after cache reuse');

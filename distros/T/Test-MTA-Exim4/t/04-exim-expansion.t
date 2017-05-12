#!/usr/bin/perl

use FindBin qw($Bin);
use Test::More 'no_plan';

BEGIN {
    use_ok('Test::MTA::Exim4');
}

my $exim_path = "$Bin/scripts/fake_exim";

my $exim = Test::MTA::Exim4->new( { exim_path => $exim_path, debug => 1 } );
ok( $exim, 'Created exim test object' );
$exim->config_ok;

# simple option checks
$exim->expansion_is( '${lookup{postmaster}lsearch{/etc/exim/aliases}}',     'root' );
$exim->expansion_is( '${lookup{slartibartfast}lsearch{/etc/exim/aliases}}', '' );
$exim->expansion_is( 'xyzzy',                                               'xyzzy' );

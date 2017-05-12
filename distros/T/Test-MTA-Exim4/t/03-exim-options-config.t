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
$exim->has_option('accept_8bitmime');
$exim->option_is( 'accept_8bitmime', 1 );
$exim->has_not_option('accept_9bitmime');
$exim->option_is( 'allow_domain_literals', undef );
$exim->option_is( 'acl_smtp_rcpt',         'acl_check_rcpt' );

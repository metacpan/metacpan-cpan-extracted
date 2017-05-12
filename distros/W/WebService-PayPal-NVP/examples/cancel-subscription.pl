#!/usr/bin/env perl

=head2 SYNOPSIS

    perl examples/cancel-subscription.pl S-F00X3SERBE

This script also prints extensive debugging information so that you can debug
LWP requests and responses.

=cut

use strict;
use warnings;
use feature qw( say );

use Data::Printer;
use LWP::ConsoleLogger::Easy qw( debug_ua );
use YAML::Syck;
use WebService::PayPal::NVP;

die 'auth.yml required' unless -f 'auth.yml';
die 'usage: perl examples/cancel-subscription.pl [subscription_id]'
    unless @ARGV;

my $config = LoadFile('auth.yml');

my $ua = LWP::UserAgent->new;
debug_ua( $ua, 10 );

my $nvp = WebService::PayPal::NVP->new(
    branch => $config->{branch},
    user   => $config->{user},
    pwd    => $config->{pass},
    sig    => $config->{sig},
    ua     => $ua,
);

my $res = $nvp->manage_recurring_payments_profile_status(
    {
        profileid => shift @ARGV,
        action    => 'cancel',
    }
);

say "success!" if $res->success;

if ( $res->success ) {
    say 'Success!';
}
else {
    say 'Failure.';
    p( $res->errors );
}

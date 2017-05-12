package Util;

use strict;
use warnings;
use feature qw( say );

use LWP::ConsoleLogger::Easy qw( debug_ua );
use LWP::UserAgent;
use Path::Tiny qw( path );
use WebService::PayPal::PaymentsAdvanced;
use WebService::PayPal::PaymentsAdvanced::Mocker;

sub config {
    return _get_config('config.pl');
}

sub sample_config {
    return _get_config('sample-config.pl');
}

sub _get_config {
    my $name = shift;
    my $file = path( 't/test-data/', $name );

    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    my $config = eval $file->slurp;
    return $config;
}

sub mocked_ppa {
    my %args = @_;

    my $mocker
        = WebService::PayPal::PaymentsAdvanced::Mocker->new( plack => 1 );
    my $ua = $mocker->mocked_ua;
    debug_ua($ua);

    my $config = sample_config();
    return WebService::PayPal::PaymentsAdvanced->new(
        password                 => $config->{password},
        ua                       => $ua,
        user                     => $config->{user},
        validate_hosted_form_uri => 1,
        vendor                   => $config->{vendor},
        %args,
    );
}

sub ppa {
    my %args = @_;

    my $ua = LWP::UserAgent->new;
    debug_ua($ua);
    my $config = config();
    return WebService::PayPal::PaymentsAdvanced->new(
        password                 => $config->{password},
        ua                       => $ua,
        user                     => $config->{user},
        validate_hosted_form_uri => 1,
        vendor                   => $config->{vendor},
        %args,
    );
}

1;

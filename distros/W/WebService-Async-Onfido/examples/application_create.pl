#!/usr/bin/env perl 
use strict;
use warnings;

use IO::Async::Loop;
use WebService::Async::Onfido;

use Scalar::Util qw(blessed);
use Log::Any qw($log);
use Getopt::Long;

require Log::Any::Adapter;
GetOptions(
    't|token=s' => \my $token,
    'l|log=s'   => \my $log_level,
) or die;
$log_level ||= 'info';
Log::Any::Adapter->import(
    qw(Stdout),
    log_level => $log_level
);

my $loop = IO::Async::Loop->new;
$loop->add(
    my $onfido = WebService::Async::Onfido->new(
        token => $token
    )
);

my $app = $onfido->applicant_create(
    title      => 'Mr',
    first_name => 'Example',
    last_name  => 'User',
    email      => 'user@example.com',
    gender     => 'male',
    dob        => '1980-01-22',
    country    => 'GBR',
    address => {
        building_number => '100',
        street          => 'Main Street',
        town            => 'London',
        postcode        => 'SW4 6EH',
        country         => 'GBR',
    },
)->get;

$log->infof('Applicant created: %s', $app->as_string);


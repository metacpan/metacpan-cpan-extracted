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

# Clear all users apart from our initial test one
$log->infof('Clearing initial users');
$onfido->applicant_list
    ->filter(sub { $_->id ne '20aa1a21-7234-412c-a6ba-0ff8d8bd27f1' })
    ->each(sub { $log->debugf('Will remove %s', $_->as_string) })
    ->map('delete')
    ->each(sub { $_->on_done(sub { $log->debugf('Removed successfully') }) })
    ->resolve
    ->await;

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


#!/usr/bin/env perl 
use strict;
use warnings;

use IO::Async::Loop;
use WebService::Async::Onfido;
use Time::Moment;

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

my %broker_by_month;
$onfido->applicant_list
    ->map(sub {
        $_->checks
            ->each(sub {
                my $created = Time::Moment->from_string($_->created_at, lenient => 1);
                my ($broker) = map { /^([A-Z]+)/ } $_->tags->@*;
                ++$broker_by_month{$broker // ''}{$created->strftime('%Y-%m')};
            })
            ->completed
    })->resolve
      ->await;
for my $broker (sort keys %broker_by_month) {
    $log->infof('Broker %s:', $broker);
    for my $month (sort keys $broker_by_month{$broker}->%*) {
        $log->infof('%s %d', $month, $broker_by_month{$broker}{$month});
    }
}


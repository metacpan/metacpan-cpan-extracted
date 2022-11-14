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

$onfido->applicant_list
    ->map(sub {
        $_->documents
            ->each(sub { $log->infof('Document %s', $_->as_string) })
            ->completed
    })->resolve
      ->await;

#!/usr/bin/env perl 
use strict;
use warnings;

use Future::AsyncAwait;
use Syntax::Keyword::Try;
use IO::Async::Loop;
use WebService::Async::Onfido;

use Scalar::Util qw(blessed);
use Log::Any qw($log);
use Getopt::Long;
use List::UtilsBy qw(rev_nsort_by);

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

require Log::Any::Adapter;
GetOptions(
    't|token=s'     => \my $token,
    'l|log=s'       => \my $log_level,
    'a|applicant=s' => \my $applicant_id,
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

my $handler = async sub {
    try {
        my ($applicant) = @_;
        my @checks = await $applicant->checks->as_list;
        $log->infof('Have %d checks for applicant %s', 0 + @checks, $applicant->as_string);

        foreach my $check (@checks) {
            $log->infof('Check id %s, with reports %s', $check->id, $check->reports);
        }
    } catch {
        $log->errorf('Failed to process - %s', $@);
        die $@;
    }
};

if($applicant_id) {
    $onfido->applicant_get(
        applicant_id => $applicant_id,
    )->then($handler)
     ->get;
} else {
    $onfido->applicant_list
        ->map($handler)->resolve
          ->await;
}


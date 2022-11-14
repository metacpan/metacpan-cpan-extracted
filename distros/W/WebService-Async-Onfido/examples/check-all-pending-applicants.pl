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
    'c|count=s'     => \my $count,
    'a|applicant=s' => \my $applicant_id,
) or die;

$count //= 0;
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

# When submitting checks, Onfido expects an identity document,
# so we prioritise the IDs that have a better chance of a good
# match. This does not cover all the types, but anything without
# a photo is unlikely to work well anyway.
my %document_priority = (
    uk_biometric_residence_permit => 5,
    passport                      => 4,
    passport_card                 => 4,
    national_identity_card        => 3,
    driving_licence               => 2,
    voter_id                      => 1,
    tax_id                        => 1,
    unknown                       => 0,
);

my $bypass;
my $handler = async sub {
    try {
        my ($applicant) = @_;
        my @checks = await $applicant->checks->as_list;
        $log->infof('Have %d checks for applicant %s', 0 + @checks, $applicant->as_string);
        return 0 if @checks and not $bypass;
        my @docs = await $applicant->documents->as_list;
        my @photos = await $applicant->photos->as_list;
        $log->infof('Have %d documents, %d photos for applicant %s', 0 + @docs, 0 + @photos, $applicant->as_string);
        return 0 unless @docs and @photos;
        my ($filename) = map $_->file_name, @docs;
        my ($loginid) = $filename =~ /^([A-Z]+[0-9]+)/
            or die 'Unable to extract client login ID from document ' . $filename;
        my ($broker) = $loginid =~ /^([A-Z]+)/;
        my ($doc) = rev_nsort_by {
            ($_->side eq 'front' ? 10 : 1)
            *
            $document_priority{$_->type} // 0
        } @docs;
        $log->infof('Starting check for applicant %s - %s', $loginid, $applicant->as_string);
        return await $applicant->check(
            # We don't want Onfido to start emailing people
            suppress_form_emails => 1,
            # Used for reporting and filtering in the web interface
            tags                 => ['automated', $broker, $loginid],
            # Note that there are additional report types which are not currently useful:
            # - proof_of_address - only works for UK documents
            # - street_level - involves posting a letter and requesting the user enter
            # a verification code on the Onfido site
            # plus others that would require the feature to be enabled on the account:
            # - identity
            # - watchlist
            reports              => [
                {
                    name      => 'document',
                    documents => [ $doc->id ],
                },
                {
                    name      => 'facial_similarity',
                    variant   => 'standard',
                    documents => [ $doc->id ],
                }
            ],
            # async flag if true will queue checks for processing and
            # return a response immediately
            async                => 1,
            # The type is always "express" since we are sending data via API.
            # https://documentation.onfido.com/#check-types
            type                 => 'express',
        )->on_fail(sub { $log->errorf('Failed with %s', $_[0]) })->else_done
    } catch {
        $log->errorf('Failed to process - %s', $@);
        die $@;
    }
};

if($applicant_id) {
    $bypass = 1;
    $onfido->applicant_get(
        applicant_id => $applicant_id,
    )->then($handler)
     ->get;
} else {
    $onfido->applicant_list
        ->map($handler)->resolve
          ->await;
}


#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/./lib";
use lib "$FindBin::Bin/../lib";

=head1 DESCRIPTION

Tests for code working with languages and laguage pairs.

=cut

use WebService::MyGengo::Test::Util::Client;
use WebService::MyGengo::Test::Util::Job;

use Getopt::Long;
use Test::More;

use Data::Dumper;

BEGIN {
    use_ok 'WebService::MyGengo::Base';
    use_ok 'WebService::MyGengo::Client';
}

# CLI options
my $DEBUG   = undef;
my $FILTER  = undef;
my $LIVE    = 0;
GetOptions(
    'debug'         => \$DEBUG
    , 'filter=s'    => \$FILTER
    , 'live:i'      => \$LIVE
    );
$LIVE and $ENV{WS_MYGENGO_USE_SANDBOX} = 1;
sub is_mock { !$LIVE }

my $tests = [
    'can_get_service_language_pairs'
    , 'language_pair_isa_object'
    , 'can_filter_language_pairs_by_lc_src'
    , 'filter_for_bad_language_returns_empty_list'
    , 'can_get_service_languages'
    ];

my $client = client();
if ( $DEBUG ) {
    $client->DEBUG(1);
    is_mock() and $client->_user_agent->DEBUG(1);
}
my @_dummies;

run_tests();
done_testing();
teardown();

################################################################################
sub run_tests {
    foreach ( @$tests ) {
        next if $FILTER && $_ !~ /.*$FILTER.*/;
        $DEBUG and diag "##### Start test: $_";
        no strict 'refs';
        eval { &$_() };
        $@ and fail("Error in test $_: ".Dumper($@));
        $DEBUG and diag "##### End   test: $_";
    }
}

sub teardown {
    $DEBUG and print STDERR "TEARDOWN\n";
    foreach ( @_dummies ) {
        !$_->is_available and next;
        $client->delete_job( $_ ) or
            diag "Error deleting Job ".$_->id . ": "
                    . Dumper($client->last_response);
    }
}

################################################################################
sub can_get_service_language_pairs {
    my $pairs = $client->get_service_language_pairs;
    is( ref($pairs), 'ARRAY', "Got an array" );
    ok( $#$pairs > 0, "Have at least 1 pair in array" );
}

sub language_pair_isa_object {
    my $pairs = $client->get_service_language_pairs;
    foreach my $pair ( @$pairs ) {
        isa_ok( $pair, 'WebService::MyGengo::LanguagePair' );
    }
}

sub can_filter_language_pairs_by_lc_src {
    my $pairs = $client->get_service_language_pairs( 'en' );
    ok( $#$pairs > 0, "Have at least 1 pair in array" );
    foreach my $pair ( @$pairs ) {
        is( $pair->lc_src, "en", "lc_src is english" );
    }
    my @non_en_pairs = grep { $_->lc_src ne 'en' } @$pairs;
    is( scalar(@non_en_pairs), 0, "No non-en language pairs" );
}

sub filter_for_bad_language_returns_empty_list {
    my $pairs = $client->get_service_language_pairs( 'BLAH' );
    is( ref($pairs), 'ARRAY', "Got an array" );
    is( scalar(@$pairs), 0, "No language pairs returned" );
}

sub can_get_service_languages {
    my $langs = $client->get_service_languages();
    is( ref($langs), 'ARRAY', "Got an array" );
}

sub service_language_isa_object {
    my $langs= $client->get_service_language_pairs;
    foreach my $lang ( @$langs ) {
        isa_ok( $lang, 'WebService::MyGengo::Language' );
    }
}

#!/usr/bin/perl

use strict;
use warnings;
use WebService::Buxfer;
use DateTime;
use Data::Dumper;

# Make a new account in your Buxfer account called 'perl' before
#   running write tests.
my $DO_READ_TESTS = 1;
my $DO_WRITE_TESTS = 1;

# Enter login info. here
my $params = {
    userid => '',
    password => '',
    #debug => 1,
    };

my $bux = WebService::Buxfer->new($params);

if ( $DO_READ_TESTS ) {
    no strict 'refs';
    foreach my $method ( qw/transactions analysis accounts impacts tags budgets groups contacts/ ) {
        my $response = $bux->$method;
        print "$method RESULTS: '".Dumper($response)."'\n";
    }
}

if ( $DO_WRITE_TESTS ) {
    print "Check for Buxfer account named 'perl'\n";

    unless ( grep { $_->{name} eq 'perl'; } values(%{$bux->accounts}) ) {
        die "You must create a Buxfer account called 'perl' to run WRITE tests.\n";
    }

    print "Add sample transactions\n";
    my $transactions = &get_sample_transactions;
    my @responses = $bux->add_transactions($transactions);
    
    print "Response: ".($_->buxfer_status)."\n" for (@responses);
}

################################################################################
sub get_sample_transactions {
    return [
        {
            description => 'Shared expense One',
            amount => -1000,
            tags => [qw/test blah/],
            account => 'perl',
            date => '2009-01-03',
            status => 'pending',
            participants => [['andy',10]],
        },
        {
            description => 'Shared expense Two',
            amount => -2000,
            payer => 'andy',
            tags => [qw/test blah/],
            account => 'perl',
            date => '2009-01-03',
            status => 'pending',
            participants => [qw/me/],
        },
        {
            description => 'Test expense One',
            amount => -3000,
            tags => [qw/test blah/],
            account => 'perl',
            date => '2009-01-03',
            status => 'pending',
        },
        {
            description => 'Test deposit One',
            amount => 4000,
            tags => [qw/test blah/],
            account => 'perl',
            date => '2009-01-03',
        },
        {
            description => 'Test deposit Two',
            amount => 5000,
            tags => ['test', 'blah', 'long tag here'],
            account => 'perl',
            date => '2009-01-03',
        },
        ];
}



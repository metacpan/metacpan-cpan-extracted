#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/./lib";
use lib "$FindBin::Bin/../lib";

=head1 DESCRIPTION

Account-related tests

=cut

use WebService::MyGengo::Account;
use WebService::MyGengo::Test::Util::Client;
use Test::More;

use Data::Dumper;

BEGIN {
    use_ok 'WebService::MyGengo::Base';
    use_ok 'WebService::MyGengo::Client';
    use_ok 'WebService::MyGengo::Account';
}

my $client = client();

run_tests();
done_testing();

sub run_tests {
    foreach ( qw/get_account_stats get_account_balance get_account/ ) {
        no strict 'refs';
        eval { &$_() };
        $@ and fail("Error in test $_: ".Dumper($@));
    }
}

sub get_account_stats {
    my $struct = $client->get_account_stats();

    ok( $client->last_response->is_success, "Response is success" )
        or diag "Response: ".Dumper($client->last_response);
    ok( defined($struct), "Has a response struct" );

    ok( exists($struct->{credits_spent}), "Has credits_spent" );
    ok( exists($struct->{user_since}), "Has user_since" );
}

sub get_account_balance {
    my $struct = $client->get_account_balance();

    ok( $client->last_response->is_success, "Response is success" )
        or diag "Response: ".Dumper($client->last_response);
    ok( defined($struct), "Has a response struct" );

    ok( exists($struct->{credits}), "Has credits" );
}

sub get_account {
    my $acct = $client->get_account();

    ok( $acct, "Got a response" );
    isa_ok( $acct, 'WebService::MyGengo::Account', "Got an Account" );

    ok( $acct->user_since, "Has user_since" );
    isa_ok( $acct->user_since, "DateTime", "user_since is a DateTime" );

    ok( $acct->credits_spent, "Has credits_spent" );
    ok( $acct->credits, "Has credits" );
}

use strict;
use warnings;
no warnings qw/ uninitialized /;

use Test::More;

use WWW::Ohloh::API;

plan skip_all => <<'END_MSG', 1 unless $ENV{OHLOH_KEY};
set OHLOH_KEY to your api key to enable these tests
END_MSG

unless ( $ENV{TEST_OHLOH_ACCOUNT} =~ /(id|email):(.+)/ ) {
    plan skip_all =>
      "set TEST_OHLOH_ACCOUNT to 'id:accountid' or 'email:addie' "
      . "to enable these tests";
}

plan 'no_plan';

my $ohloh = WWW::Ohloh::API->new( debug => 1, api_key => $ENV{OHLOH_KEY} );

diag "testing kudos with account $ENV{TEST_OHLOH_ACCOUNT}\n";

my $kudos = $ohloh->get_kudos( split ':', $ENV{TEST_OHLOH_ACCOUNT} );

ok $kudos->isa( 'WWW::Ohloh::API::Kudos' );

my %all = $kudos->all;
my @sent = $kudos->sent;
my @rcx = $kudos->received;

diag "received ", scalar( @rcx ), " gave ", scalar( @sent ), "\n";
ok exists $all{sent}, '$all{sent}';
ok exists $all{received}, '$all{received}';
ok @sent >= 0, "sent()"; 
ok @rcx >= 0, "received()"; 
is @{$all{received}} + @{$all{sent}} => @sent + @rcx, 
    "all = sent + received";

# testing the kudos themselves
for ( @sent, @rcx ) {
    ok $_->created_at, 'created_at';
    like $_->sender_account_id, qr/^\d+$/, 'sender_account_id';
    ok length( $_->sender_account_name ), 'sender_account_name';
    ok defined $_->receiver_account_name, 'receiver_account_name';
    ok defined $_->receiver_account_id, 'receiver_account_id';
    ok defined $_->project_id,   'project_id';
    ok defined $_->project_name, 'project_name';
    ok defined $_->contributor_id, 'contributor_id';
    ok defined $_->contributor_name, 'contributor_name';

    like $_->recipient_type, qr/^account|contributor$/, "recipient()";
}

SKIP: {
    # take a single kudo
    my( $k ) = grep { $_->recipient_type eq 'account' } ( @sent, @rcx ) 
        or skip "no kudo to test on", 1;

    isa_ok $k->sender,   'WWW::Ohloh::API::Account';
    isa_ok $k->receiver, 'WWW::Ohloh::API::Account';
}



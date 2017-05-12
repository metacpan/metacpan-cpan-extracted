use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use lib "$Bin/../inc";

my $json_dir = $ENV{'API_CREDENTIAL_DIR'};

use Test::More;

unless ($json_dir && -e $json_dir) {  plan skip_all => 'No credential file found in $ENV{"API_CREDENTIAL_DIR"} or path is invalid!'; }

use Webservice::OVH;

my $api = Webservice::OVH->new_from_json($json_dir);

my $example_email_domains = $api->email->domain->domains;
my $example_email_domain  = $example_email_domains->[0];

ok( $example_email_domain, "example domain ok" );
ok( $example_email_domain->service_infos && ref $example_email_domain->service_infos eq 'HASH', "service_info ok" );
ok( $example_email_domain->properties    && ref $example_email_domain->properties eq 'HASH',    "properties ok" );
ok( ref $example_email_domain->allowed_account_size eq 'ARRAY', "allowed_account_size ok" );
ok( ref $example_email_domain->creation_date eq 'DateTime',     "creation_date ok" );
ok( $example_email_domain->status,                              "status ok" );

my $redirections = $example_email_domain->redirections;
ok( ref $redirections eq 'ARRAY', "redirections ok" );

if ( scalar @$redirections ) {

    my $redirection = $redirections->[0];
    ok( ref $redirection eq 'Webservice::OVH::Email::Domain::Domain::Redirection', "Type ok" );
}

my $accounts        = $example_email_domain->accounts;
my $example_account = $accounts->[0];
my $search_account  = $example_email_domain->account( $example_account->name );

ok( $accounts && ref $accounts eq 'ARRAY', 'accounts ok' );
ok( $example_account, 'one accounts exists ok' );
ok( $search_account,  'acount found ok' );

my $mailing_lists        = $example_email_domain->mailing_lists;
my $example_mailing_list = $mailing_lists->[0];

ok( $mailing_lists && ref $mailing_lists eq 'ARRAY', 'mailing_lists ok' );

if ($example_mailing_list) {

    my $search_mailing_list = $example_email_domain->mailing_list( $example_mailing_list->name );
    ok( $example_mailing_list, 'one mailing_list exists ok' );
    ok( $search_mailing_list,  'mailing_list found ok' );
}

ok ( scalar keys %{$example_email_domain->{_redirections}} == scalar @$redirections, 'intern redirections ok' );
ok ( scalar keys %{$example_email_domain->{_accounts}} == scalar @$accounts, 'intern accounts ok' );
ok ( scalar keys %{$example_email_domain->{_mailing_lists}} == scalar @$mailing_lists, 'intern mailing_lists ok' );

done_testing();

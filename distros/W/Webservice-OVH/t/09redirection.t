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
my $example_redirections  = $example_email_domain->redirections;
my $example_redirection   = $example_redirections->[0];

if ($example_redirection) {

    ok( $example_redirection->id, "id ok" );
    ok( $example_redirection->domain && ref $example_redirection->domain eq 'Webservice::OVH::Email::Domain::Domain', "domain ok" );
    ok( $example_redirection->properties && ref $example_email_domain->properties eq 'HASH', "properties ok" );
    ok( $example_redirection->from, "from ok" );
    ok( $example_redirection->to,   "to ok" );

} else {

    print STDERR "No redirection to test\n";

    ok( !$example_redirection, "No redirection found" );
}

my $redirection;
eval { $redirection = $example_email_domain->new_record; };
ok( !$redirection, "missing parameter ok" );

eval { $redirection = $example_email_domain->new_record( from => sprintf( 'test@%s', $redirection->domain->name ) ); };
ok( !$redirection, "missing parameter ok" );

eval { $redirection = $example_email_domain->new_record( to => 'test@test.de' ); };
ok( !$redirection, "missing parameter ok" );

eval { $redirection = $example_email_domain->new_record( to => 'test@test.de', from => sprintf( 'test@%s', $redirection->domain->name ) ); };
ok( !$redirection, "missing parameter ok" );

my $from = sprintf( 'test@%s', $example_email_domain->name );

#TODO Insert waiting
=head2 This test takes way too long. Deleting a newly created redirection can take up to 2 Minutes 

$redirection = $example_email_domain->new_redirection( to => 'test@test.de', from => $from, local_copy => 'false' );
ok( $redirection,                       "new redirection ok" );
ok( $redirection->from eq $from,        "new redirection from ok" );
ok( $redirection->to eq 'test@test.de', "new redirection to ok" );

my $old_id = $redirection->id;

$redirection->change('test@testtest.de');
ok( $redirection->id ne $old_id,            "changed redirection id ok" );
ok( $redirection->to eq 'test@testtest.de', "changed redirection to ok" );

$redirection->delete;
ok( !$redirection->is_valid, "validity ok" );

my $new_redirections = $example_email_domain->redirections;

my @not_found = grep { $_->id eq $redirection->id } @$new_redirections;

ok( scalar @not_found == 0, "not found anymore ok" );

=cut

done_testing();

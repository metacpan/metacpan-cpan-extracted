use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use lib "$Bin/../inc";

my $json_dir = $ENV{'API_CREDENTIAL_DIR'};

use Test::More;

unless ( $json_dir && -e $json_dir ) { plan skip_all => 'No credential file found in $ENV{"API_CREDENTIAL_DIR"} or path is invalid!'; }

use Webservice::OVH;

=head2

    You need to choose an email domain with a free account quota
    Passwort change can't be tested, because password cannot be requested
    This test can take up to 10 minutes to complete, because ovh need up to 10 minutes to delete an account

=cut

my $api = Webservice::OVH->new_from_json($json_dir);
ok( $api, "module ok" );

my $email_domain = $api->email->domain->domains->[0];

SKIP: {

    skip "No email domain found in connected account", 1 if !$email_domain;

    ok( $email_domain, 'email_domain ok' );

    my $new_account;
    eval { $new_account = $email_domain->new_account( account_name => 'testaccount', password => '%%12345$tets$s089', description => 'Ein Account' ); };

  SKIP: {

        skip "Max account quota reached for connected account", 1 if !$new_account;
#TODO
=head2 This test take way too long. Creating and deleting an account could take up to 15 Minutes
        ok( $new_account, 'new account ok' );

        ok( $new_account->name, 'name ok' );
        ok( $new_account->properties && ref $new_account->properties eq 'HASH', 'properties ok' );
        ok( $new_account->email,  'email ok' );
        ok( $new_account->domain, 'domain ok' );
        ok( $new_account->description && $new_account->description eq 'Ein Account', 'description ok' );
        ok( $new_account->size, 'size ok' );
        ok( $new_account->usage && ref $new_account->usage eq 'HASH', 'usage ok' );

        $new_account->change( description => 'this is an account', size => 2000000000 );

        ok( $new_account->description eq 'this is an account', 'account change description ok' );
        ok( $new_account->size == 2000000000,                  'account change size ok' );
        while ( $new_account->is_valid ) {

            eval { $new_account->delete; };
            warn $@ if $@;
            sleep(60);
        }

        ok( !$new_account->is_valid,                'validity ok' );
        ok( !$email_domain->account('testaccount'), 'not found ok' );
        my @accounts = grep { $_->name eq 'testaccount' } @{ $email_domain->accounts };
        ok( scalar @accounts == 0, 'not found in list ok' );
=cut
    }

}

done_testing();

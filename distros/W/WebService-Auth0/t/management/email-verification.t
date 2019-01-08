use Test::Most;
use WebService::Auth0::Management::Tickets;

plan skip_all => 'Missing AUTH0_DOMAIN and AUTH0_TOKEN'
 unless $ENV{AUTH0_DOMAIN} and $ENV{AUTH0_TOKEN};

ok my $user_mgmt = WebService::Auth0::Management::Tickets->new(
  domain => $ENV{AUTH0_DOMAIN},
  token => $ENV{AUTH0_TOKEN} );

{
  ok my $f = $user_mgmt->create_email_verification({
      q=>'XXXxxXXX123444NEVERFOUNDIHOPE'
  });

  ok my ($data) = $f->catch(sub {
    fail "Don't expect an error here and now";
  })->get;

  is @$data, 0, 'created email verfication ticket';
}

done_testing;

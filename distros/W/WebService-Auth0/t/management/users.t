use Test::Most;
use WebService::Auth0::Management::Users;

plan skip_all => 'Missing AUTH0_DOMAIN and AUTH0_TOKEN'
 unless $ENV{AUTH0_DOMAIN} and $ENV{AUTH0_TOKEN};

ok my $user_mgmt = WebService::Auth0::Management::Users->new(
  domain => $ENV{AUTH0_DOMAIN},
  token => $ENV{AUTH0_TOKEN} );

{
  ok my $f = $user_mgmt->search({q=>'XXXxxXXX123444NEVERFOUNDIHOPE'});
  ok my ($data) = $f->catch(sub {
    fail "Don't expect an error here and now";
  })->get;

  is @$data, 0, 'correct number of not founds';
}

{
  ok my $f = $user_mgmt->search(+{});
  ok my ($data) = $f->catch(sub {
    fail "Don't expect and error here and now";
  })->get;

  ok @$data, 'found some users';

  my $last_user_id;
  foreach(@$data) {
    fail 'no user_id' unless $_->{user_id};
    ok my $f = $user_mgmt->get($_->{user_id});
    ok my ($data) = $f->catch(sub {
      fail "Don't expect an error here and now";
    })->get;

    ok $data->{user_id}, 'got a user';
    is $_->{user_id}, $data->{user_id}, 'got expected user';
    $last_user_id = $_->{user_id};
  }

  {
    my $opinion = scalar(time);
    my %user_data = (
      user_metadata => {
        opinion => $opinion,
      });

    ok my $f = $user_mgmt->update($last_user_id, \%user_data);
    ok my ($data) = $f->catch(sub {
      fail "Don't expect an error here and now (update)";
    })->get;

    is $data->{user_metadata}{opinion}, $opinion, 'got expected opinion';
  }
}

{
  my %user_data = (
    "connection" => "database",
    "email" => "john.doe\@gmail.com",
    "password" => "secret",
  );

  ok my $f = $user_mgmt->create(\%user_data);
  ok my ($data) = $f->catch(sub {
    fail "Don't expect an error here and now (create)";
  })->get;

  ok $data->{user_id};

  sleep 5; # Need this, if you create and delete too fast it breaks auth0!

  {
    ok my $f = $user_mgmt->delete($data->{user_id});
    ok my ($data) = $f->catch(sub {
      fail "Don't expect an error here and now";
    })->get;
  }
}

done_testing;

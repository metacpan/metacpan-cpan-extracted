use strict;
use warnings;
use Test::More;
use WebService::Moodle::Simple;
use Data::Dumper;

unless ($ENV{TEST_WSMS_ADMIN_PWD} && $ENV{TEST_WSMS_DOMAIN} && $ENV{TEST_WSMS_TARGET}) {
  plan skip_all => 'Not running live tests. Set $ENV{TEST_WSMS_ADMIN_PWD}, $ENV{TEST_WSMS_DOMAIN} and $ENV{TEST_WSMS_TARGET} to enable';
}

my $moodle = WebService::Moodle::Simple->new( 
  domain   =>  $ENV{TEST_WSMS_DOMAIN},
  target   =>  $ENV{TEST_WSMS_TARGET},
);

is(ref($moodle), 'WebService::Moodle::Simple');
my $login = $moodle->login(username => 'admin', password => $ENV{TEST_WSMS_ADMIN_PWD});

ok($login->{ok}, 'login succeeds');

{
  my $timestamp = time();
  my $username = 'test_'.$timestamp;
  note 'testing raw api';
  $moodle->add_user(
    firstname => 'Test',
    lastname  => 'User',
    email     => $username.'@example.com',
    username  => $username,
    token     => $login->{token},
    password  => 'test_pwd',
  );


  my $ra_users = $moodle->get_users(token => $login->{token});

  my @test_user = grep { $_->{username} eq $username } @$ra_users;

  is ($test_user[0]->{email}, $username.'@example.com', $username.'@example.com exists');

  note 'userid = '.$test_user[0]->{id};

  # now delete using the raw api

  my $delresp = $moodle->raw_api(
      token => $login->{token},
      method => 'core_user_delete_users',
      params => { 'userids[0]' => $test_user[0]->{id}}
  );

  note 'make sure the user is gone now';
  $ra_users = $moodle->get_users(token => $login->{token});

  @test_user = grep { $_->{username} eq $username } @$ra_users;
  ok (! scalar (@test_user), 'user has been deleted with the raw_api');

}

{
  sleep(1);
  my $timestamp = time();
  my $username = 'test_'.$timestamp;
  note 'testing raw api';
  $moodle->add_user(
    firstname => 'Test',
    lastname  => 'User',
    email     => $username.'@example.com',
    username  => $username,
    token     => $login->{token},
    password  => 'test_pwd',
  );


  my $suspension = $moodle->suspend_user(
    token => $login->{token},
    username  => $username
  );

  my $ra_users = $moodle->get_users(token => $login->{token});

  my @test_user = grep { $_->{username} eq $username } @$ra_users;

  is ($test_user[0]->{email}, $username.'@example.com', $username.'@example.com exists');

  ok($test_user[0]->{suspended}, 'the user is suspended as expected');

  note 'userid = '.$test_user[0]->{id};


}


done_testing();



use strict;
use warnings;
use Test::More;
use WebService::LiveJournal;

plan skip_all => 'for live tests set TEST_WEBSERVICE_LIVEJOURNAL' unless defined $ENV{TEST_WEBSERVICE_LIVEJOURNAL};
plan tests => 5;

my($user,$pass,$server) = split /:/, $ENV{TEST_WEBSERVICE_LIVEJOURNAL};

my $client = WebService::LiveJournal->new(
  server => $server,
  username => $user,
  password => $pass,
);

my $response1 = $client->console_command('print', 'hello world', '!error', 'and again');

is $response1->[1]->[1], 'hello world';
is $response1->[2]->[1], '!error';
is $response1->[3]->[1], 'and again';

$client->batch_console_commands(
  [ 'print', 'test1' ],
  sub { is $_[1]->[1], 'test1' },
  [ 'print', 'test2' ],
  sub { is $_[1]->[1], 'test2' },
);

$client->console_command('foo');

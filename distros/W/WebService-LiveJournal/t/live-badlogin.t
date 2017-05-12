use strict;
use warnings;
use Test::More;
use WebService::LiveJournal;
use WebService::LiveJournal::Client;

plan skip_all => 'for live tests set TEST_WEBSERVICE_LIVEJOURNAL' unless defined $ENV{TEST_WEBSERVICE_LIVEJOURNAL};

my $data_dir = eval q{
  use YAML;
  use File::HomeDir;
  File::HomeDir->my_dist_data('WebService-LiveJournal', { create => 1 });
};

plan skip_all => 'test requires File::HomeDir and YAML' unless -d $data_dir;

note "data_dir = $data_dir";

if(-e "$data_dir/live-badlogin.yml")
{
  my $time = eval { YAML::LoadFile("$data_dir/live-badlogin.yml")->{time} };
  if($@ || !$time)
  {
    unlink "$data_dir/live-badlogin.yml";
  }
  else
  {
    # don't run this test any more often than every file minutes lest
    # LJ ban your IP.
    plan skip_all => 'test has run too recently' unless abs($time-time()) > 60*5;
  }
  YAML::DumpFile("$data_dir/live-badlogin.yml", { time => time() });
}
else
{
  YAML::DumpFile("$data_dir/live-badlogin.yml", { time => time() });
}

plan tests => 3;

my($user,$pass,$server) = split /:/, $ENV{TEST_WEBSERVICE_LIVEJOURNAL};
is(WebService::LiveJournal::Client->new( server => $server, username => $user, password => 'bogus' ), undef, 'bad password new returns undef');
is $WebService::LiveJournal::Client::error, 'Invalid password (101) on LJ.XMLRPC.sessiongenerate', '$error set';

eval {
  WebService::LiveJournal->new(
    server   => $server,
    username => $user,
    password => 'bogus',
  );
};
my $error = $@;

like $error, qr{Invalid password \(101\) on LJ\.XMLRPC\.sessiongenerate}, 'throws error';


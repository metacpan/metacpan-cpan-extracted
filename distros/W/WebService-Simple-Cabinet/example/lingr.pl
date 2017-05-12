# author: mattn
use strict;
use warnings;
use WebService::Simple::Cabinet;
use Cache::File;
use YAML;

my $api_key  = "your_api_key";
my $room_id  = "hO4SmQWTdJ4"; # http://www.lingr.com/room/hO4SmQWTdJ4
my $nickname = "lingr.pl";
my $message  = $ARGV[0] || "Hello, World.";

#my $cache   = Cache::File->new(
#    cache_root      => '/tmp/mycache',
#    default_expires => '30 min',
#);

my $config = Load( do { local $/;<DATA> } );

my $lingr = WebService::Simple::Cabinet->new(
    $config,
    #cache => $cache,
    api_key => $api_key,
    format  => 'xml'
);

# create session, get session
my $session = $lingr->session_create()->{session};

# enter the room, get ticket
my $ticket = $lingr->room_enter(
  session => $session, id => $room_id, nickname => $nickname)->{ticket};

# say 'Hello, World'
my $status = $lingr->room_say(
  session => $session, ticket => $ticket, message => $message)->{status};

# destroy session
$lingr->session_destroy( session => $session );

1;

__DATA__
global:
  name: lingr
  package: Lingr
  base_url: http://www.lingr.com/
  params:
    api_key:
    format:
  
method:
  - name: session_create
    params:
    options:
      path: /api/session/create

  - name: room_enter
    params:
      session:
      id:
      nickname:
    options:
      path: /api/room/enter

  - name: room_say
    params:
      session:
      ticket:
      message:
    options:
      path: /api/room/say

  - name: session_destroy
    params:
      session:
    options:
      path: /api/session/destroy


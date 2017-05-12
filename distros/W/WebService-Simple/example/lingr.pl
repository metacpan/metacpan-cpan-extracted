use strict;
use warnings;
use WebService::Simple;

my $api_key = $ARGV[0] || "your_api_key";
my $room_id = "hO4SmQWTdJ4";    # http://www.lingr.com/room/hO4SmQWTdJ4
my $nickname = "WebService::Simple";
my $message  = "Hello, World.";

my $lingr = WebService::Simple->new(
    base_url => 'http://www.lingr.com/',
    param    => { api_key => $api_key, format => 'xml' }
);

# create session, get session
my $response;
$response = $lingr->get( 'api/session/create', {} );
my $session = $response->parse_response->{session};

# enter the room, get ticket
$response = $lingr->get(
    'api/room/enter',
    {
        session  => $session,
        id       => $room_id,
        nickname => $nickname,
    },
);
my $ticket = $response->parse_response->{ticket};

# say 'Hello, World'
$response = $lingr->get(
    'api/room/say',
    {
        session => $session,
        ticket  => $ticket,
        message => $message,
    },
);
my $status = $response->parse_response->{status};

# destroy session
$lingr->get( 'api/session/destroy', { session => $session, } );

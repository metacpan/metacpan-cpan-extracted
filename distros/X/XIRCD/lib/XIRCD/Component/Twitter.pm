package XIRCD::Component::Twitter;
use strict;
use MooseX::POE;
use XIRCD::Component;

with qw(XIRCD::Role);

use Encode;
use HTTP::Request::Common;
use HTTP::Date ();
use JSON::Any;
use POE qw( Component::Client::HTTP );
use URI;


has 'apiurl'   => ( isa => 'Str', is => 'rw', default => sub { 'http://twitter.com/statuses' } );
has 'apihost'  => ( isa => 'Str', is => 'rw', default => sub { 'twitter.com:80' } );
has 'apirealm' => ( isa => 'Str', is => 'rw', default => sub { 'Twitter API' } );

has 'screenname' => ( isa => 'Str', is => 'rw' );
has 'username'   => ( isa => 'Str', is => 'rw' );
has 'password'   => ( isa => 'Str', is => 'rw' );
has 'retry'      => ( isa => 'Int', is => 'rw', default => sub { 60 } );

has 'since' => (
    is => 'rw',
);

around 'new' => sub {
    my $call = shift;

    my $self = $call->(@_);

    POE::Component::Client::HTTP->spawn(
        Agent => 'xircd_component_twitter/0.1',
        Alias => $self->http_alias,
    );

    return $self;
};

event send_message => sub {
    my ($status,) = get_args;

    my $req = HTTP::Request::Common::POST(
        self->apiurl . '/update.json',
        [ status => encode('utf-8',$status) ],
    );  
    $req->authorization_basic(self->username, self->password);

    post self->http_alias => request => 'http_response', $req;
};

event start => sub {
    debug "read twitter";

    my $uri = URI->new(self->apiurl . '/friends_timeline.json');
    $uri->query_form(since => HTTP::Date::time2str(self->since)) if self->since;
    self->since(time);

    my $req = HTTP::Request->new(GET => $uri);
    $req->authorization_basic(self->username, self->password);

    post self->http_alias => request => 'http_response', $req;
};

event http_response => sub {
    my ($request_packet, $response_packet) = get_args;

    my $request  = $request_packet->[0];
    my $response = $response_packet->[0];

    my $uri = $request->uri;
    if ($uri =~ /update.json/) {
        unless ($response->is_success) {
            yield response_error => $response;
            return;
        }
        yield update_success => $response;
    } elsif ($uri =~ /friends_timeline.json/) {
        yield friend_timeline_success => $response;
    }
};

event friend_timeline_success => sub {
    debug "get friend timeline";
    my ( $response, ) = get_args;

    if ( $response->is_success ) {
        my $ret;
        eval {
            $ ret = JSON::Any->jsonToObj($response->content);
        };
        for my $line ( reverse @{ $ret || [] } ) {
            publish_message  $line->{user}->{screen_name} => $line->{text};
        }
    }

    delay start => self->retry;
};

event update_success => sub {
    my ( $response, ) = get_args;

    if ( $response->is_success ) {
        my $ret = JSON::Any->jsonToObj($response->content);
        publish_notice $ret->{text};
    }
};


1;


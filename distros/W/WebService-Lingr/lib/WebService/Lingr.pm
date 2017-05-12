package WebService::Lingr;

use strict;
our $VERSION = '0.02';

use Carp;
use Data::Visitor::Callback;
use HTTP::Request::Common;
use LWP::UserAgent;
use JSON::Syck;
use URI;

our $APIBase = "http://www.lingr.com/api";

# scraped from Lingr wiki page
our $Methods = {
    'session.create' => 'POST',
    'session.destroy' => 'POST',
    'auth.login' => 'POST',
    'auth.logout' => 'POST',
    'explore.getHotRooms' => 'GET',
    'explore.getNewRooms' => 'GET',
    'explore.getHotTags' => 'GET',
    'explore.getAllTags' => 'GET',
    'explore.search' => 'GET',
    'explore.searchTags' => 'GET',
    'user.getInfo' => 'GET',
    'user.startObserving' => 'POST',
    'user.observe' => 'GET',
    'user.stopObserving' => 'POST',
    'room.getInfo' => 'GET',
    'room.enter' => 'POST',
    'room.getMessages' => 'GET',
    'room.observe' => 'GET',
    'room.setNickname' => 'POST',
    'room.say' => 'POST',
    'room.exit' => 'POST',
};

sub new {
    my($class, %args) = @_;

    my %self;
    $self{api_key} = $args{api_key} or croak "api_key is required.";
    $self{ua}      = $args{ua} || LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");

    my $self = bless \%self, $class;

    unless($args{no_create_session}) {
        my $res = $self->create_session;
        $self->{session} = $res->{session};
    }

    $self;
}

sub create_session {
    my $self = shift;
    $self->_call('session.create', { api_key => $self->{api_key} });
}

sub call {
    my($self, $method, $args) = @_;
    $args->{session} = $self->{session} if $self->{session};
    $self->_call($method, $args);
}

sub _call {
    my($self, $method, $args) = @_;

    my @method = map { s/([A-Z])/"_".lc($1)/eg; $_ } split /\./, $method;
    my $uri = URI->new($APIBase . "/" . join("/", @method));

    # downgrade all parameters to utf-8, if they're Unicode
    my $v = Data::Visitor::Callback->new(
        plain_value => sub {
            if (utf8::is_utf8($_)) {
                utf8::encode($_);
            }
        },
        ignore_return_values => 1,
    );

    $v->visit($args);

    my $req_method = $Methods->{$method} || do {
        Carp::carp "Don't know method '$method'. Defaults to GET";
        "GET";
    };

    $args->{format} = 'json';

    my $req;
    if ($req_method eq 'GET') {
        $uri->query_form(%$args);
        $req = HTTP::Request->new(GET => $uri);
    } else {
        $req = HTTP::Request::Common::POST( $uri, [ %$args ] );
    }

    my $res = $self->{ua}->request($req);
    $self->_parse_response($res);
}

sub _parse_response {
    my($self, $res) = @_;

    $res->is_success or croak "Request failed: " . $res->status_line;

    local $JSON::Syck::ImplicitUnicode = 1;
    my $data = JSON::Syck::Load($res->content);
    $data->{status} eq 'ok' or croak "Response error: $data->{error}->{message} ($data->{error}->{code})";

    return $self->{res} = $data;
}

sub response { $_[0]->{res} }

sub DESTROY {
    my $self = shift;
    $self->call('session.destroy');
}

1;
__END__

=for stopwords JSON API Lingr

=head1 NAME

WebService::Lingr - Low-level Lingr Chat API

=head1 SYNOPSIS

  use WebService::Lingr;

  # create a session using your API key
  my $lingr = WebService::Lingr->new(api_key => "YOUR_API_KEY");

  # enter the room 'MyFavoriteRoom' with nick 'api-dude'
  my $res = $lingr->call('room.enter', { id => 'MyFavoriteRoom', nickname => 'api-dude' });
  my $ticket  = $res->{ticket};
  my $counter = $res->{counter};

  # say "Hello world!"
  my $res = $lingr->call('room.say', { message => 'hello world', ticket => $ticket });

  # room.observe blocks
  while (1) {
      my $res = $lingr->call('room.observe', { ticket => $ticket, counter => $counter });
      for my $message (@{$res->{messages}}) {
          print "$message->{nick} says: $message->{content}\n";
      }
  }

  # room.getMessages doesn't, but you can call this method at most once per minute
  while (1) {
      my $res = $lingr->call('room.getMessages', { ticket => $ticket, counter => $counter });
      # do something ...
      sleep 60;
  }

=head1 DESCRIPTION

WebService::Lingr is a low-level Lingr API implementation in Perl. By
"low-level" it means that this module just gives you a straight
mapping of Perl object methods to Lingr REST API, session management
and data mapping via JSON.

For higher level event driven programming, you might want to use
POE::Component::Client::Lingr (unfinished).

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://wiki.lingr.com/dev/show/HomePage>

=cut

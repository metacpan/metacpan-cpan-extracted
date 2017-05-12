package WWW::PubNub;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: PubNub API
$WWW::PubNub::VERSION = '0.001';
use Moo;
use LWP::UserAgent;
use Carp qw( croak );
use HTTP::Request;
use JSON::MaybeXS;
use WWW::PubNub::Message;

has useragent => (
  is => 'lazy',
);

sub _build_useragent {
  my ( $self ) = @_;
  return LWP::UserAgent->new(
    agent => 'WWW::PubNub/'.$WWW::PubNub::VERSION,
    timeout => $self->timeout,
  );
}

has subscribe_key => (
  is => 'ro',
  predicate => 1,
);

has _subscribe => (
  is => 'ro',
  predicate => 1,
  init_arg => 'subscribe',
);

has publish_key => (
  is => 'ro',
  predicate => 1,
);

has timeout => (
  is => 'lazy',
);

sub _build_timeout { return 320 }

has host => (
  is => 'lazy',
);

sub _build_host { return 'pubsub.pubnub.com' }

has port => (
  is => 'ro',
  predicate => 1,
);

has ssl => (
  is => 'lazy',
);

sub _build_ssl { return 1 }

has raw => (
  is => 'lazy',
);

sub _build_raw { return 0 }

has max_fail => (
  is => 'lazy',
);

sub _build_max_fail { return 3 }

has error_wait => (
  is => 'lazy',
);

sub _build_error_wait { return 5 }

has base_url => (
  is => 'lazy',
);

sub _build_base_url {
  my ( $self ) = @_;
  return 'http'.( $self->ssl ? 's' : '' ).'://'.$self->host.( $self->port ? ':'.$self->port : '' );
}

sub _request {
  my ( $self, $url ) = @_;
  return HTTP::Request->new( GET => $url );
}

sub BUILD {
  my ( $self ) = @_;
  if ($self->_subscribe) {
    $self->subscribe(@{$self->_subscribe});
  }
}

sub subscribe_url {
  my ( $self, $channel ) = @_;
  my @channels = ref $channel eq 'ARRAY' ? @{$channel} : ( $channel );
  croak __PACKAGE__." requires channel names on subscribe_url" unless @channels;
  my $channel_string = join(',',@channels);
  croak __PACKAGE__." requires subscribe_key for subscribe_url" unless $self->has_subscribe_key;
  my $subscribe_key = $self->subscribe_key;
  return join('/',$self->base_url, 'subscribe', $self->subscribe_key, $channel_string, '0', '0');
}

sub subscribe_request {
  my ( $self, @subscribe_url_args ) = @_;
  return $self->_request($self->subscribe_url(@subscribe_url_args));
}

sub subscribe_next_request_and_messages {
  my ( $self, $response, $request ) = @_;
  $request = $response->request unless $request;
  my $data = decode_json($response->decoded_content);
  my ( $raw_messages_arrayref, $timetoken, $channel ) = @{$data};
  my @raw_messages = @{$raw_messages_arrayref};
  my @messages = map {
    WWW::PubNub::Message->new(
      pubnub => $self,
      request => $request,
      response => $response,
      message => $_,
      $channel ? ( channel => $channel ) : (),
    )
  } @raw_messages;
  my $request_uri = $request->uri;
  my @url_parts = split('/', $request_uri);
  pop @url_parts;
  push @url_parts, $timetoken;
  my $new_request_uri = join('/', @url_parts);
  return $self->_request($new_request_uri), @messages;
}

sub subscribe {
  my ( $self, $channel, @more_args ) = @_;
  if (!ref $self) {
    $self = $self->new( subscribe_key => $channel );
    $channel = shift @more_args;
  }
  my $for_all = ref $more_args[0] eq 'CODE' ? (shift @more_args) : undef;
  croak __PACKAGE__." requires at least one function for subscribe" unless $for_all || @more_args;
  my %args = @more_args;
  my $request = $self->subscribe_request($channel);
  my $response = $self->useragent->request($request);
  unless ($response->is_success) {
    if ($args{error} && ref $args{error} eq 'CODE') {
      $args{error}->( $self, __PACKAGE__." got error from server on subscribe: ".$response->status_line, $request, $response );
    } else {
      croak __PACKAGE__." errored while subscription: $@";
    }
  }
  my $raw = defined $args{raw} ? delete $args{raw} : $self->raw;
  my $fail_count = 0;

  while (1) {
    my $next_response;

    eval {
      my ( $next_request, @messages ) = $self->subscribe_next_request_and_messages($response);
      $request = $next_request;
      for my $message (@messages) {
        my @params = $raw ? (
          $message->message, $message->has_channel ? ( $message->channel ) : ()
        ) : ( $message );
        $for_all->(@params) if $for_all;
        if ($message->has_channel) {
          if ($args{'-'.$message->channel} && ref $args{'-'.$message->channel} eq 'CODE') {
            $args{'-'.$message->channel}->(@params);
          } elsif ($args{$message->channel} && ref $args{$message->channel} eq 'CODE') {
            $args{$message->channel}->(@params);
          }
        }
      }
      $next_response = $self->useragent->request($request);
    };

    if ($@) {
      if ($args{error} && ref $args{error} eq 'CODE') {
        $args{error}->( $self, $@, $request, $response );
      } else {
        croak __PACKAGE__." errored while subscription: $@";
      }
    } else {
      if ($next_response->is_success) {      
        $fail_count = 0;
        $response = $next_response;
      } else {
        $fail_count++;
        if ($self->max_fail && $fail_count >= $self->max_fail) {
          croak __PACKAGE__." got repeated (".$self->max_fail." times) error on HTTP from server for request to ".$request->uri;
        }
        sleep $self->error_wait;
        if ($args{failed} && ref $args{failed} eq 'CODE') {
          $args{failed}->( $self, $response, $request );
        }
      }
    }
  }
}

1;

__END__

=pod

=head1 NAME

WWW::PubNub - PubNub API

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use WWW::PubNub;

  my $pubnub = WWW::PubNub->new(
    subscribe_key => 'demo',
    publish_key => 'demo', # not supported yet
  );

  #
  # Blocking usage
  #
  #################

  $pubnub->subscribe(
    my_channel => sub {                             # $_[0] is a WWW::PubNub::Message
      print "It is said ".$_[0]->get('text')."\n";  # helper function for accessing raw message
    },
  );

  # alternative shortcut:

  WWW::PubNub->subscribe( demo => my_channel => sub { ... } );

  # multi subscription works out of box:

  $pubnub->subscribe(
    [qw( my_channel1 my_channel2 )] => sub {        # called on any message (optional)
      print "On ".$_[0]->channel." it is said ".$_[0]->message->{text}."\n";
    },
    my_channel2 => sub { ... },                     # only called for specific channel
  );

  # multi subscription and raw

  $pubnub->subscribe(
    [qw( my_channel1 my_channel2 )] => sub {
      my ( $message, $channel ) = @_;
      print "On ".$channel." it is said ".$message->{text}."\n"; # raw message of PubNub
    },
    raw => 1,
  );

  #
  # Non-Blocking usage
  #
  #####################

  my $request = $pubnub->subscribe_request('my_channel');

  # Repeat:

  my $response = your_http_agent($request);

  my ( $next_request, @messages ) = $pubnub->subscribe_next_request_and_messages($response);

  # There can be no messages! Do something with the messages, repeat with $next_request

=head1 DESCRIPTION

Module for using the L<PubNub API|https://www.pubnub.com/>.

A message is a L<WWW::PubNub::Message> object.

Publish not yet implemented

More documentation to come...

More tests to come...

=head1 INIT ARGS

=head2 subscribe_key

Subscribe key used for PubNub.

=head2 publish_key

Publish key used for PubNub. (Not supported yet)

=head1 METHODS

=head2 subscribe

Takes a channel name or an arrayref of channel names as argument, followed by
a coderef which gets called for every new message. After that a hash of
arguments can be used to add additional coderefs for specific events:

=head1 SPONSORING

This distribution is sponsored by L<RealEstateCE.com|http://realestatece.com/>.

=head1 SUPPORT

IRC

  /msg Getty on irc.perl.org or chat.freenode.net.

Repository

  https://github.com/Getty/p5-www-pubnub
  Pull request and additional contributors are welcome

Issue Tracker

  https://github.com/Getty/p5-www-pubnub/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

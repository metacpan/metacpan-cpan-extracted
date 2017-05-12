package Web::Hippie::PubSub;

use strict;
use warnings;
our $VERSION = '0.08';
use parent 'Plack::Middleware';

use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;
use Plack::Request;
use Plack::Builder;
use Plack::App::Cascade;
use Web::Hippie;
use Web::Hippie::Pipe;
use JSON;
use Carp qw/croak cluck/;

# bus = AnyMQ pubsub client bus
# keep_alive = seconds between "ping" events
use Plack::Util::Accessor qw/
    bus keep_alive
/;

sub call {
    my ($self, $env) = @_;
    my $res = $self->app->($env);
    return $res;
}

sub prepare_app {
    my ($self) = @_;

    die "bus is a required builder argument for Web::Hippie::PubSub"
        unless $self->bus;

    my $keep_alive = $self->keep_alive;

    my $builder = Plack::Builder->new;

    # stats server
    $builder->add_middleware(sub {
        my $app = shift;
        return sub {
            my $env = shift;
            my $req = Plack::Request->new($env);
            my $path = $req->path;

            #warn "path: $path";
            if ($path eq '/stats') {
                my $res = $req->new_response(200);
                $res->content_type('text/html; charset=utf-8');

                my $ret = '';
                while (my ($stat, $count) = each %{$self->stats}) {
                    $ret .= "$stat: $count\n";
                }

                $res->content($ret);
                $res->finalize;
            } else {
                return $app->($env);
            }
        }
    });

    # websocket/mxhr/poll handlers
    $builder->add_middleware('+Web::Hippie');
    
    # AnyMQ stuff for Web::Hippie
    $builder->add_middleware('+Web::Hippie::Pipe', bus => $self->bus);
    
    # our simple publish/subscribe event code
    $builder->add_middleware(sub {
        my $app = shift;
        return sub {
            # these are handlers for internal hippie events, NOT actual
            # URLs visited by the client
            # (/new_listener, /message, /error)
            my $env = shift;
            my $channel = $env->{'hippie.args'};
            my $req = Plack::Request->new($env);
            my $h = $env->{'hippie.handle'};

            if ($req->path eq '/new_listener') {
                # called when we get a new topic subscription

                return [ 400, [], [ "Channel is required for new_listener" ] ] unless $channel;
                my $topic = eval { $env->{'hippie.bus'}->topic($channel) };
                unless ($topic) {
                    warn "Could not get topic for channel $channel: $@";
                    return [ 500, [ 'Content-Type' => 'text/plain' ], [ "Unable to create listener for channel $channel" ] ];
                }

                # subscribe client to events on $channel
                my $res;
                my $ok = eval {
                    $env->{'hippie.listener'}->subscribe($topic);
                    $res = $app->($env);
                    1;
                };

                unless ($ok) {
                    warn "Error subscribing to topic '$topic': $@";
                }

                $self->start_keepalive_timer($env);

                $self->increment_stats_counter('current_subscribers');
                $self->increment_stats_counter('total_subscribers');
                
                # success
                return $res || [ '200', [ 'Content-Type' => 'text/plain' ], [ "Now listening on $channel" ] ];

            } elsif ($req->path eq '/message') {
                # called when we are publishing a message

                # get message channel
                return [ '400', [ 'Content-Type' => 'text/plain' ], [ "Channel is required" ] ] unless $channel;
                my $topic = $env->{'hippie.bus'}->topic($channel);

                # get message, tack on sent time and from addr
                my $msg = $env->{'hippie.message'};
                $msg->{time} = time;
                $msg->{address} = $env->{REMOTE_ADDR};

                # publish event, but don't notify local listeners (or
                # they will receive a duplicate event)
                $topic->publish($msg);

                $self->increment_stats_counter('events_published');

                my $res = $app->($env);
                return $res || [ '200', [ 'Content-Type' => 'text/plain' ], [ "Event published on $channel" ] ];
            } elsif ($req->path eq '/error') {
                $self->stop_keepalive_timer($env);
                $self->decrement_stats_counter('current_subscribers');
            }

            my $res = $app->($env);
            
            # we didn't handle anything
            return $res || [ '404', [ 'Content-Type' => 'text/plain' ], [ "unknown event server path " . $req->path ] ];
        }
    });

    $self->app( $builder->to_app($self->app) );
}

sub start_keepalive_timer {
    my ($self, $env) = @_;

    return unless $self->keep_alive;

    my $h = $env->{'hippie.handle'};
    
    my $w = AnyEvent->timer(
        interval => $self->keep_alive,
        cb => sub {
            my $ok = eval {
                $h->send_msg({
                    type => 'ping',
                    time => AnyEvent->now,
                });
                1;
            };

            # client has disconnected, stop firing
            unless ($ok) {
                $self->stop_keepalive_timer($env);
            }
        }
    );
    $env->{'hippie.listener'}->{keepalive_timer} = $w;
}

sub stop_keepalive_timer {
    my ($self, $env) = @_;

    undef $env->{'hippie.listener'}->{keepalive_timer};
    
    delete $env->{'hippie.listener'}->{keepalive_timer}
        if $env->{'hippie.listener'};
}

sub increment_stats_counter {
    my ($self, $stat_name) = @_;

    $self->{_stats}{$stat_name} ||= 0;
    $self->{_stats}{$stat_name}++;
}

sub decrement_stats_counter {
    my ($self, $stat_name) = @_;

    $self->{_stats}{$stat_name} ||= 0;
    $self->{_stats}{$stat_name}--;
}

sub stats {
    my ($self) = @_;
    
    return $self->{_stats} || {};
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Web::Hippie::PubSub - Comet/Long-poll event server using AnyMQ

=head1 SYNOPSIS

  use Plack::Builder;
  use AnyMQ;
  use AnyMQ::ZeroMQ;

  my $bus = AnyMQ->new_with_traits(
    traits            => [ 'ZeroMQ' ],
    subscribe_address => 'tcp://localhost:4001',
    publish_address   => 'tcp://localhost:4000',
  );

  # your plack application
  my $app = sub { ... }

  builder {
    # mount hippie server
    mount '/_hippie' => builder {
      enable "+Web::Hippie::PubSub",
        keep_alive => 30,   # send 'ping' event every 30 seconds
        bus        => $bus;
      sub {
        my $env = shift;
        my $args = $env->{'hippie.args'};
        my $handle = $env->{'hippie.handle'};
        # Your handler based on PATH_INFO: /init, /error, /message
      }
    };
    mount '/' => my $app;
  };

=head1 ATTRIBUTES

=over 4

=item bus

AnyMQ bus configured for publish/subscribe events

=item keep_alive

Number of seconds between keep-alive events. ZMQ::Server will send a
"ping" event to keep connections alive. Set to zero to disable.

=back

=head1 METHODS

=over 4

=item stats

Returns hashref of statistical event handling information.

=back

=head1 DESCRIPTION

This module adds publish/subscribe capabilities to L<Web::Hippie> using
AnyMQ.

See eg/event_server.psgi for example usage.

=head1 SEE ALSO

L<Web::Hippie>, L<Web::Hippie::Pipe>, L<AnyMQ>,
L<ZeroMQ::PubSub>

=head1 AUTHOR

Mischa Spiegelmock E<lt>revmischa@cpan.orgE<gt>


Based on work by:

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

Jonathan Rockway E<lt>jrockway@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

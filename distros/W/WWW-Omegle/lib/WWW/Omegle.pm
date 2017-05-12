package WWW::Omegle;

use 5.006000;
use strict;
use warnings;

use Carp qw/croak/;
use JSON;

use base qw/WWW::Mechanize/;
use HTTP::Async;
use HTTP::Request;
use HTTP::Request::Common;

our $VERSION = '0.02';

sub new {
    my ($class, %opts) = @_;

    my $chat_cb = delete $opts{on_chat};
    my $disconnect_cb = delete $opts{on_disconnect};
    my $connect_cb = delete $opts{on_connect};

    my $self = $class->SUPER::new(%opts);

    $self->{om_callbacks} = {
        chat => $chat_cb,
        connect => $connect_cb,
        disconnect => $disconnect_cb,
    };

    my $async = new HTTP::Async();
    $self->{async} = $async;

    bless $self, $class;

    return $self;
}

sub start {
    my ($self) = @_;

    my $res = $self->post("http://omegle.com/start");
    return undef unless $res->is_success;

    my $res_body = $res->content || '';
    my ($id) = $res_body =~ /"(\w+)"/;
    return undef unless $id;

    $self->{om_id} = $id;

    $self->handle_event($res);
    $self->request_next_event;

    return $id;
}

sub callback {
    my ($self, $action, @args) = @_;
    
    my $callback = $self->{om_callbacks}->{$action}
        or return;

    my $extra = $self->{om_callback_userdata}->{$action} || [];
    $callback->($self, @args, @$extra);
}

sub set_callback {
    my ($self, $action, $cb, @extra) = @_;

    $self->{om_callback_userdata}->{$action} = \@extra;
    $self->{om_callbacks}->{$action} = $cb;
}

# process a HTTP::Response from /events. parse JSON and dispatch to callbacks
sub handle_event {
    my ($self, $res) = @_;

    unless ($res->is_success) {
        $self->callback('error', $res->status_line);
        warn "HTTP error: " . $res->status_line;
        return;
    }

    return undef unless $res->content;

    unless ($res->content =~ /^\[/) {
        if ($res->content eq 'win') {
            # yay, message delivered OK
            return;
        } elsif ($res->content =~ /^"/) { # " ){  # emacs :(
            # got id
            return;
        } else {
            # not JSON array of events
            $self->callback(error => "Got invalid JSON: " . $res->content);
            return;
        }
    }
    
    my $json = new JSON;
    my $events = $json->decode($res->content)
        or return undef;

    return undef unless ref $events && ref $events eq 'ARRAY';

    foreach my $evt (@$events) {
        my $evt_name = $evt->[0]
            or next;
        if ($evt_name eq 'connected') {
            $self->callback('connect');
        } elsif ($evt_name eq 'gotMessage') {
            $self->callback('chat', $evt->[1]);
        } elsif ($evt_name eq 'strangerDisconnected') {
            $self->callback('disconnect');
            delete $self->{om_id};
        } elsif ($evt_name eq 'waiting') {
            
        } else {
            warn "Got unknown omegle event: $evt_name";
        }
    }

    $self->callback('event_handled', 1);

    return 1;
}

# event loop, currently runs forever.
sub run_event_loop {
    my ($self) = @_;

    my $done;
    while (! $done) {
        my $res = $self->wait_next_event;
        next unless $res;

        $self->handle_event($res);
        $self->request_next_event;
    }
}

# block and wait for next omegle event
sub wait_next_event {
    my ($self, $wait_for) = @_;
    $wait_for ||= 0.5;
    return $self->{async}->wait_for_next_response($wait_for);
}

# let async http worker do some work, and flush event queue
sub poke {
    my $self = shift;

    $self->{async}->poke;
    $self->flush_events;
}

# process all http responses in the queue
sub flush_events {
    my $self = shift;

    my $got_events = 0;

    while ($self->{async}->not_empty) {
        if (my $response = $self->{async}->next_response) {
            $self->handle_event($response);
            $got_events = 1;
        } else {
            last;
        }
    }

    # got some events, should ask for more
    $self->request_next_event if $got_events;
}

# post an asynchronous http request asking omegle for the next event.
# this may take a long time to complete
sub request_next_event {
    my ($self) = @_;

    return undef unless $self->{om_id};
    $self->{async}->add(POST "http://omegle.com/events", [ id => $self->{om_id} ]);
}

sub say {
    my ($self, $what) = @_;

    return undef unless $self->{om_id};
    $self->{async}->add(POST "http://omegle.com/send", [ id => $self->{om_id}, msg => $what ]);
}

sub disconnect {
    my ($self) = @_;

    return undef unless $self->{om_id};
    $self->{async}->add(POST "http://omegle.com/disconnect", [ id => $self->{om_id} ]);
}    

1;


__END__


=head1 NAME

WWW::Omegle - Perl interface www.omegle.com

=head1 SYNOPSIS

  use WWW::Omegle;
  my $ombot = WWW::Omegle->new(
                             on_connect    => \&connect_cb,
                             on_chat       => \&chat_cb,
                             on_disconnect => \&disconnect_cb,
                             );

  $ombot->start;
  while ($ombot->get_next_event) { 1; }
  exit;

  sub connect_cb {
    my ($om) = @_;
    print "Connected\n";
    $om->say('Hello, sir!');
  }

  sub chat_cb {
    my ($om, $what) = @_;
    print ">> $what\n";
  }

  sub disconnect_cb {
    my ($om) = @_;
    print "Disconnected.\n";
  }


=head1 DESCRIPTION

This is a perl interface to the backend API for www.omegle.com. This
module lets you easily script chating with random, anonymous people
around the world. Note that this uses an unofficial API and is subject
to breakage if the site author chooses to change their interface.

=head2 EXPORT

None by default.


=head1 METHODS

=over 4

=item new(%opts)

Construct a new Omeglebot. Supported options are
on_chat, on_disconnect and on_connect, which must be coderefs. See
synopsis for usage examples.
Other %opts are passed to the WWW::Mechanize constructor

=item set_callback($action, $callback, @userdata)

Sets the callback for $action, where $action is 'connect, 'chat' or 'disconnect'.
@userdata is user-supplied opaque data that will be bassed to the callback.

=item start

Begins a chat with a random stranger. Returns success/failure.

=item say($message)

Says something to your chat buddy. Returns success/failure

=item disconnect

Terminates your conversation.

=item get_next_event

Fetches the next event and dispatches to the appropriate callback. See
synopsis. This method will block while waiting for the next event.

=item run_event_loop

Sit and process events forever. Only useful for simple, callback-based scripts

=item poke

Check for events that have been received and flush event queue.
Call this method frequently in your main loop if you are not using run_event_loop()

=back

=head1 SEE ALSO

WWW::Mechanize

=head1 AUTHOR

Mischa Spiegelmock, E<lt>revmischa@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Mischa Spiegelmock

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut

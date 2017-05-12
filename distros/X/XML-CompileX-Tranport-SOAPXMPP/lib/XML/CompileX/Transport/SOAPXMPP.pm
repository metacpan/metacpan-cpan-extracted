{   package XML::CompileX::Transport::SOAPXMPP;
    use strict;
    use warnings;
    use Encode;
    use base qw(XML::Compile::Transport);
    our $VERSION = '1.0';

    sub init {
        my ($self, $args) = @_;
        $self->SUPER::init($args);

        # defaults
        $self->wait_iq_reply(1);

        for (qw(connection force_stanza_types wait_iq_reply)) {
            $self->{$_} = $args->{$_} if exists $args->{$_};
        }

        $self;
    }

    # the code returned here is executed receiving a text and is
    # expected to return text
    sub _prepare_call {
        my ($self, $args) = @_;
        my $hook = $args->{hook};
        my $kind = $args->{kind};
        $hook ||= sub {
            my ($messageref, $trace) = @_;
            my $message = $$messageref;
            # this is the standard code, it is overriden by a given
            # hook that might be sent to this method.

            die 'No XMPP connection while trying to send message'
              unless $trace->{connection};

            if ($trace->{stanza_type} eq 'message') {
                $trace->{message_id} = $trace->{connection}->send_message
                  ($trace->{address}, 'normal',
                   sub {
                       my $writer = shift;
                       $message =~ s/\<\?[^\?]+\?\>//;
                       $writer->raw(encode('utf8',$message));
                   });
                $self->last_sent_message_id($trace->{message_id});

                return '';

            } else {
                $trace->{eventwatcher} = AnyEvent->condvar
                  if $trace->{wait_iq_reply};

                $trace->{iq_id} = $trace->{connection}->send_iq
                  ('set',
                   sub {
                       my $writer = shift;
                       $message =~ s/\<\?[^\?]+\?\>//;
                       $writer->raw(encode('utf8',$message));
                   },
                   sub {
                       my $node = shift;

                       if ($node) {
                           my $id = $node->attr('id');
                           $self->iq_replies({}) unless $self->iq_replies;
                           $self->iq_replies->{$id} = $node;
                       }

                       $trace->{eventwatcher}->broadcast()
                         if $trace->{eventwatcher};

                   },
                   to => $trace->{address});
                $self->last_sent_iq_id($trace->{iq_id});

                if ($trace->{eventwatcher}) {
                    $trace->{eventwatcher}->wait;

                    $trace->{node} = $self->consume_iq_reply($trace->{iq_id});
                    return '' unless $trace->{node};
                    my $content = join '',
                      $trace->{node}->text,
                        map { $_->as_string } $trace->{node}->nodes;

                    return \$content;

                } else {
                    return '';
                }
            }
        };
        sub {
            my ($messageref, $trace) = @_;
            my $transport_manager = $self;

            $trace->{kind} = $kind;
            $trace->{stanza_type} = $self->force_stanza_types;
            $trace->{stanza_type} ||= $kind eq 'one-way' ? 'message' : 'iq';
            $trace->{wait_iq_reply} = $self->wait_iq_reply;
            $trace->{address} = $self->address;
            $trace->{connection} = $self->connection;

            return $hook->($messageref, $trace);
        }
    }

    sub consume_iq_reply {
        my ($self, $id) = @_;
        $self->{iq_replies} ||= {};
        return delete $self->{iq_replies}{$id};
    }

    # I would use Class::Accessor::Fast, but I wouldn't like to mess with
    # XML::Compile::Transport inheritance.
    for my $name (qw(connection force_stanza_types wait_iq_reply addrs
                     last_sent_message_id last_sent_iq_id iq_replies)) {
        no strict 'refs';
        *{$name} = sub {
            my $self = shift;
            $self->{$name} = $_[0] if @_;
            return $self->{$name};
        };
    }
}

__PACKAGE__

__END__

=head1 NAME

XML::CompileX::Transport::SOAPXMPP - Send SOAP messages through XMPP

=head1 SYNOPSIS

  use XML::CompileX::Transport::SOAPXMPP;

  my $trans = XML::CompileX::Transport::SOAPXMPP->new()
  $send = $trans->compileClient();

  my $call = $wsdl->compileClient(
    operation => 'foo',
    transport => $send);

  # later on...

  $trans->connection($net_xmpp2_connection_object);
  $trans->address('user@domain.com/resource')
  $call->(...);

=head1 DESCRIPTION

This module serves as the transport layer for the XML::Compile::SOAP
suite. It provides XMPP acccess to srevices, but it doesn't deal with
the parsing of the message or of the wsdl in any way, it is simply
used to send and receive XML data.

=head1 METHODS

=over

=item XML::CompileX::Transport::SOAPXMPP->new(OPTIONS)

This method creates a new transport object. Unlike the HTTP transport
this object does not represent a connection by itself. This object
represents a connection manager, that will allow you to set the
Net::XMPP2 object to use when doing the actual requests.

This is a important feature because XMPP implies a context of who in
sending the message, unlike HTTP, and in most cases, you might want to
reuse the result from Compile Client to do the same call using
different sender identifications.

OPTIONS can be (see below for details):

=over

=item connection

Allows you to set the initial connection to be used. It's not required
if you set it later, but there must be a set connection before a
message can be sent.

=item force_stanza_type

See below.

=item wait_iq_reply

See below.

=back

=item $trans->connection($net_xmpp2_connection_object)

This method sets the connection to be used by the calls that were
compiled with this transport manager. This is mostly like setting a
global variable, but it is limited to the scope of the clients
compiled with this transport.

=item $trans->force_stanza_type('iq'|'message'|undef)

By default, request/response messages will be sent using 'iq' stanzas
and request-only messages will be sent using 'message'. You can force
one of both, or set it to the default behaviour.

It is important to realise that in order to maintain a coherent
interface with XML::Compile::SOAP, 'iq' messages will, by default,
block the current execution until the iq reply is received.

=item $trans->wait_iq_reply(1|0)

This method can be used to override the default behaviour of holding
the execution until the iq reply is received. It's important to
realise that this is not really blocking the process, but simply
getting into the main loop while the iq reply is received. This is
done using AnyEvent->condvar. Please take a look at AnyEvent
documentation.

=item $trans->last_sent_message_id()

Id of the last message sent.

=item $trans->last_sent_iq_id()

Id of the last iq sent.

=item $trans->iq_replies()

Returns a hashref of all currently stored iq replies.

=item $trans->consume_iq_reply(id)

When an iq reply is received, it is stored in this object using the id
as a key. This method allows you to fetch that response. It will
return undef if there is no reply for that id, which can mean that
either the reply didn't arrive or it was already consumed.

The return of this method is the Net::XMPP2::Node object of the iq
reply.

=back

=head1 SEND BUFFER

Net::XMPP2 is completely asynchronous. This means that even when you
ask it to send a message, the message might not be sent yet, because
if the write would block, Net::XMPP2 will return immediatly and wait
for a next event loop iteraction to continue the send process. This
might not be desirable when dealing with SOAP services.

On the other hand, Net::XMPP2 also provides an option for waiting
until the buffer is empty before returning from send_message and
send_iq. Please take a look at Net::XMPP2::Connection documentation
for details on that.

=head1 ERROR HANDLING

It's important to realise that XMPP is, by definition, an async
protocol. When using request-only messages, the only way to know that
something went wrong is to wait for errors. If the error is not
transport-related, it won't even be reported as an error, but as a
normal message with a fault in the body.

This is the basic reason for mapping request/response messages as iq
stanzas.

This module, at this moment, won't expect for fault messages. If
you're using request-only, you should register callbacks in the xmpp
connection to receive them. You can introspect into the WSDL Operation
to compile and parse the fault messages.

=head1 SEE ALSO

L<XML::Compile::SOAP>, L<XML::Compile::Transport::SOAPHTTP>,
L<Net::XMPP2::Connection>, L<AnyEvent>

=head1 LICENSE

Copyright 2008 by Daniel Ruoso. For other contributors see ChangeLog.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
See F<http://www.perl.com/perl/misc/Artistic.html>

=cut


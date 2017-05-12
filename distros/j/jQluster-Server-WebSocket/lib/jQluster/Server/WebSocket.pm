package jQluster::Server::WebSocket;
use strict;
use warnings;
use base ("Plack::Component");
use jQluster::Server;
use Plack::App::WebSocket;
use Scalar::Util qw(weaken refaddr);
use Try::Tiny;
use JSON qw(decode_json encode_json);

our $VERSION = "0.03";

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);
    $self->{logger} ||= sub {};
    $self->{jqluster} = jQluster::Server->new(
        logger => $self->{logger}
    );
    $self->{websocket_app} = $self->_create_websocket_app();
    return $self;
}

sub call {
    my ($self, $env) = @_;
    return $self->{websocket_app}->call($env);
}

sub _log {
    my ($self, $level, $msg) = @_;
    $self->{logger}->($level, $msg);
}

sub _create_websocket_app {
    my ($self) = @_;
    weaken $self;
    my $app = Plack::App::WebSocket->new(on_establish => sub {
        my ($conn) = @_;
        return if !$self;
        $conn->on(message => sub {
            my ($conn, $message_str) = @_;
            return if !$self;
            try {
                my $message = decode_json($message_str);
                if(!ref($message) || ref($message) ne "HASH") {
                    die("Message is not a HASH");
                }
                if(!defined($message->{message_type})) {
                    die("message_type is not defined in the message");
                }
                if($message->{message_type} eq "register") {
                    $self->_register($conn, $message);
                }else {
                    $self->{jqluster}->distribute($message);
                }
            }catch {
                my $e = shift;
                $self->_log("error", $e);
            }
        });
        $conn->on(finish => sub {
            return if !$self;
            $self->{jqluster}->unregister(refaddr($conn));
            undef $conn;
        });
    });
    return $app;
}

sub _register {
    my ($self, $conn, $message) = @_;
    weaken $self;
    $self->{jqluster}->register(
        unique_id => refaddr($conn),
        message => $message,
        sender => sub {
            my ($send_message) = @_;
            try {
                $conn->send(encode_json($send_message));
            }catch {
                my $e = shift;
                return !$self;
                $self->_log("error", "send error: $e");
            }
        }
    );
}


1;
__END__

=pod

=head1 NAME

jQluster::Server::WebSocket - jQluster server implementation using WebSocket transport

=head1 SYNOPSIS

In your app.psgi

    use Plack::Builder;
    use jQluster::Server::WebSocket;
    
    my $jq_server = jQluster::Server::WebSocket->new();
    
    builder {
        mount "/jqluster", $jq_server->to_app;
        mount "/", $your_app;
    };

Then, in your JavaScript code

    $.jqluster.init("my_node_id", "ws://myhost.mydomain/jqluster");


=head1 DESCRIPTION

L<jQluster::Server::WebSocket> is part of jQluster project. To learn more about jQluster, visit L<https://github.com/debug-ito/jQluster>.

This module is a jQluster server implementation using simple WebSocket
transport. It accepts WebSocket connections and distribute jQluster
messages through the connections.

L<jQluster::Server::WebSocket> creates a L<PSGI> application. You can
use it as a stand-alone app or mount it together with your own app.

Currently L<jQluster::Server::WebSocket> uses
L<Plack::App::WebSocket>, so your L<PSGI> server must meet its
requirements.

=head1 CLASS METHODS

=head2 $server = jQluster::Server::WebSocket->new(%args)

The constructor. Fields in C<%args> are

=over

=item C<logger> => CODE (optional, default: do nothing)

A subroutine reference that the server calls when it wants to log
something.

The C<$logger> is called like

    $logger->($level, $message)

where C<$level> is a log level string such as "info", "warning",
"error" etc.  C<$message> is the log message string.

=back

=head1 OBJECT METHODS

=head2 $psgi_app = $server->to_app()

Create a L<PSGI> application object from the C<$server>.


=head1 SEE ALSO

=over

=item L<jQluster::Server>

jQluster server independent of connection implementations.

=item L<Plack::App::WebSocket>

WebSocket server implementation as a L<Plack> app.

=back


=head1 REPOSITORY

L<https://github.com/debug-ito/jQluster-Server-WebSocket>

=head1 BUGS AND FEATURE REQUESTS

Please report bugs and feature requests to my Github issues
L<https://github.com/debug-ito/jQluster-Server-WebSocket/issues>.

Although I prefer Github, non-Github users can use CPAN RT
L<https://rt.cpan.org/Public/Dist/Display.html?Name=jQluster-Server-WebSocket>.
Please send email to C<bug-jQluster-Server-WebSocket at rt.cpan.org> to report bugs
if you do not have CPAN RT account.


=head1 AUTHOR
 
Toshio Ito, C<< <toshioito at cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Toshio Ito.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut


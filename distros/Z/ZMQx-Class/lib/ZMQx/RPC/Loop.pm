package ZMQx::RPC::Loop;
use strict;
use warnings;
use Carp qw(croak);
use MooseX::Role::Parameterized;
use AnyEvent;
use Log::Any qw($log);
use ZMQx::RPC::Message::Request;
use ZMQx::RPC::Message::Response;

parameter 'commands' => ( is => 'ro', isa => 'ArrayRef', required => 1 );

my %DISPATCH;
my %DISPATCH_RAW;

role {
    my $p = shift;

    my @commands = @{ $p->commands };
    for ( my $i = 0; $i < @commands; $i++ ) {
        my $cmd  = $commands[$i];
        my $opts = {};
        if ( ref( $commands[ $i + 1 ] ) eq 'HASH' ) {
            $opts = $commands[ $i + 1 ];
            $i++;
        }

        if ( defined $opts->{payload} && $opts->{payload} eq 'raw' ) {
            $DISPATCH_RAW{$cmd} = $opts;
        }
        else {
            $DISPATCH{$cmd} = $opts;
        }
    }
    has '_server_is_running' => (
        is      => 'rw',
        isa     => 'Bool',
        default => 1,
    );

    method 'loop' => sub {
        my ( $self, $server ) = @_;

        my $running = AnyEvent->condvar;
        # FIXME - deal with DEALERs, and anything else fun.
        my $has_envelope = $server->type eq 'ROUTER';
        my $w = $server->anyevent_watcher(
            sub {
                $running->send unless $self->_server_is_running;

                return
                    unless $server->socket->has_pollin
                    ;    # Check if this works with a big message / high load
                #$log->debugf("i have a poll_in");

                # We have to deal in bytes and do the encoding/decoding ourselves
                # as the envelope section is bytes, not UTF-8-encoded characters.
                while ( my $msg = $server->receive_bytes ) {
                    #$log->debugf("i have a msg");
                    my $envelope = $has_envelope && $self->unpack_envelope($msg);
                    my $req;
                    my $res = eval {
                        $req = ZMQx::RPC::Message::Request->unpack($msg);
                        #$log->debugf("i have a req");

                        # TODO: handle timeouts using alarm() because AnyEvent won't be interrupted in $cmd
                        my $cmd = $req->command;

                        if ( $DISPATCH{$cmd} ) {
                            #$log->debugf("Dispatching $cmd");
                            my @cmd_res = $self->$cmd( @{ $req->payload } );
                            if (@cmd_res == 1 && blessed($cmd_res[0])
                                && $cmd_res[0]->DOES('ZMQx::RPC::Message::Response')) {
                                # If you return exactly one item which is a
                                # ZMQx::RPC::Message::Response then it is
                                # assumed that you are aware that you are
                                # running inside this server loop and know
                                # exactly what response you wish to generate:
                                return $cmd_res[0];
                            }
                            return $req->new_response( \@cmd_res );
                        }
                        elsif ( $DISPATCH_RAW{$cmd} ) {
                            #$log->debugf("Raw dispatching $cmd");
                            return $self->$cmd($req);
                        }
                        else {
                            my $error = "command $cmd not registered for package "
                                . ref($self);
                            $log->info($error);
                            return $req->new_error_response( 400, $error );
                        }
                    };
                    if ($@) {
                        $log->warn($@);
                        $res = ZMQx::RPC::Message::Response->new_error( 500,
                            $@ );
                    }

                    my $raw = $res->pack;
                    unshift (@$raw, @$envelope) if $has_envelope;
                    $server->send_bytes( $raw )
                        ;    # TODO handle 0mq network errors?
                    my $post = $res->post_send;
                    # TODO - this could probably also be passed the network
                    # status. Or maybe the response object is taught that.
                    # Explicitly pass the response, to avoid the callback
                    # needing to close over it, which likely will cause a
                    # reference loop and hence a memory leak. (strictly, it's
                    # freed at global destruction, but servers never exit.)
                    if ($post) {
                        my $cmd = $req->command;
                        # TODO - time this?
                        $log->debug("Running post_send after $cmd");
                        $post->($req, $res);
                        $log->debug("Completed post_send after $cmd");
                    }
                }
            }
        );

        my $check_running = AnyEvent->timer(
            after    => 0.1,
            interval => 1,
            cb       => sub {
                $running->send unless $self->_server_is_running;
            }
        );

        $running->recv;
        $log->info("Shutting down  instance");
    };

    method 'unpack_envelope' => sub {
        my ( $self, $msg ) = @_;

        # unpack envelope
        my @envelope;
        while ( my $part = shift(@$msg) ) {
            last unless $part;
            push( @envelope, $part );
        }
        push( @envelope, '' );
        return \@envelope;
    };
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ZMQx::RPC::Loop

=head1 VERSION

version 0.006

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Validad AG.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

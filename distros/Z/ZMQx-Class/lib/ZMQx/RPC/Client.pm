package ZMQx::RPC::Client;
use strict;
use warnings;
use ZMQx::RPC::Message::Request;
use ZMQx::RPC::Message::Response;
use ZMQx::RPC::Header;
use Log::Any qw($log);
use Carp qw(croak carp);

sub new {
    my $class = shift;
    carp('Odd number of arguments passed to new')
        if @_ % 2;
    bless \@_, $class;
}

sub rpc_bind {
    my $self = shift;
    # Mandatory are:
    # server
    #     an object that quacks like ZMQ::Class::Socket, or a function to call
    #     that returns one.
    # command
    #     name of the command to call.
    # Optional:
    # on_error
    #     A callback to handle errors. Assumed to throw, or to return a default.
    # server_name:
    #     A descriptive name for the server to use in log messages.
    # munge_args:
    #     A callback to transform the arguments ready to pass to pack()
    my %args = (
                # Default parameter type. Maybe this should be JSON
                type => 'string',
                # Default return type. Also valid Item, List and a code
                # reference.
                return => 'ArrayRef',
                (ref $self ? @$self : ()),
                @_);
    my ($command, $server, $type, $on_error, $return)
        = @args{qw(command server type on_error return)};
    croak('command is a mandatory argument')
        unless length $command;
    croak('server is a mandatory argument')
        unless ref $server;
    my $server_name = $args{server_name} // 'server';

    return sub {
        my $socket = 'CODE' eq ref $server ? &$server(@_) : $server;
        carp("No $server_name for $command")
            unless ref $socket;

        my $msg = ZMQx::RPC::Message::Request->new(command => $command,
                                                   header=>ZMQx::RPC::Header->new(type => $type),
                                                  );

        my $response;
        eval {
            # We're actually a closure, not a method.
            # This probably needs to be "fixed" to be general.
            # A ternary avoids entering a scope
            $args{munge_args}
                ? $socket->send_bytes($msg->pack($args{munge_args}(@_)))
                    : $socket->send_bytes($msg->pack(@_[1..$#_]));

            # $log->debugf("Sent message >%.40s< to $server_name", join(",", $command, @_));
            my $raw = $socket->receive_bytes(1);
            die "no response from Server >$server_name< for Command >$command<"
                unless $raw;
            $response = ZMQx::RPC::Message::Response->unpack($raw);
            die "failed to unpack response from Server >$server_name< for Command >$command<"
                unless $response;
            die $response->payload->[0]
                unless $response->status == 200;
        };
        if ($@) {
            if ($@ =~ /^no response from/) {
                # TODO: try to reconnect to Server
                # TODO: if not possible, tell YP to remove Server?
                $log->debug('No response from Server, socket might be broken, TODO');
            }
            if ( $on_error ) {
                # When we are in global destruction $log *might* already been gone :-/
                if ( defined $log ) {
                    $log->errorf('Dispatching to on_error callback >%s<, error: >%s<', $on_error, $@);
                }
                else {
                    warn sprintf('Dispatching to on_error callback >%s<, error: >%s<', $on_error, $@);
                }
                return &$on_error($@, $response, \@_, $msg, \%args)
            }
            else {
                $log->errorf('No error handler installed, got error %s', $@);
            }

            croak $@;
        }
        # Hopefully in order, most frequent first:
        return $response->payload
          if $return eq 'ArrayRef';
        return $response->payload->[0]
          if $return eq 'Item';
        return $return->($response, \@_, $msg, \%args)
            if 'CODE' eq ref $return;
        # Assume 'List'
        return @{$response->payload}
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ZMQx::RPC::Client

=head1 VERSION

version 0.006

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Validad AG.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

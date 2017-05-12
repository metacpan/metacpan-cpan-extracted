package XAS::Lib::RPC::JSON::Server;

our $VERSION = '0.04';

use POE;
use Try::Tiny;
use Set::Light;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::Net::Server',
  utils     => ':validation dotid',
  accessors => 'methods',
  codec     => 'JSON',
  constants => 'HASH ARRAY :jsonrpc ARRAYREF HASHREF',
;

my $ERRORS = {
    '-32700' => 'Parse Error',
    '-32600' => 'Invalid Request',
    '-32601' => 'Method not Found',
    '-32602' => 'Invalid Params',
    '-32603' => 'Internal Error',
    '-32099' => 'Server Error',
    '-32001' => 'App Error',
};

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub process_request {
    my $self = shift;
    my ($input, $ctx) = validate_params(\@_, [
        1,
        { type => HASHREF }
    ]);

    my $request;
    my $alias = $self->alias;

    $self->log->debug("$alias: entering process_request");
    $self->log->debug(Dumper($input));

    try {

        $request = decode($input);

        if (ref($request) eq ARRAY) {

            foreach my $r (@$request) {

                $self->_rpc_request($r, $ctx);

            }

        } else {

            $self->_rpc_request($request, $ctx);

        }

    } catch {

        my $ex = $_;

        $self->log->error(Dumper($input));
        $self->exception_handler($ex);

    };

}

sub process_response {
    my $self = shift;
    my ($output, $ctx) = validate_params(\@_, [
        1,
        { type => HASHREF }
    ]);

    my $json;
    my $alias = $self->alias;

    $self->log->debug("$alias: entering process_response");

    $json = $self->_rpc_result($ctx->{'id'}, $output);

    $poe_kernel->post($alias, 'client_output', encode($json), $ctx);

}

sub process_errors {
    my $self = shift;
    my ($error, $ctx) = validate_params(\@_, [
        { type => HASHREF },
        { type => HASHREF }
    ]);

    my $json;
    my $alias = $self->alias;

    $self->log->debug("$alias: entering process_errors");

    $json = $self->_rpc_error($ctx->{'id'}, $error->{'code'}, $error->{'message'});

    $poe_kernel->post($alias, 'client_output', encode($json), $ctx);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _rpc_exception_handler {
    my $self = shift;
    my ($ex, $id) = validate_params(\@_, [1,1]);

    my $packet;
    my $ref = ref($ex);

    if ($ref) {

        if ($ex->isa('XAS::Exception')) {

            my $type = $ex->type;
            my $info = $ex->info;

            if ($type =~ /server\.rpc_method$/) {

                $packet = $self->_rpc_error($id, RPC_ERR_METHOD, $info);

            } elsif ($type =~ /server\.rpc_version$/) {

                $packet = $self->_rpc_error($id, RPC_ERR_REQ, $info);

            } elsif ($type =~ /server\.rpc_format$/) {

                $packet = $self->_rpc_error($id, RPC_ERR_PARSE, $info);

            } elsif ($type =~ /server\.rpc_notify$/) {

                $packet = $self->_rpc_error($id, RPC_ERR_INTERNAL, $info);

            } else {

                my $msg = $type . ' - ' . $info;
                $packet = $self->_rpc_error($id, RPC_ERR_APP, $msg);

            }

            $self->log->error_msg('exception', $type, $info);

        } else {

            my $msg = sprintf("%s", $ex);

            $packet = $self->_rpc_error($id, RPC_ERR_SERVER, $msg);
            $self->log->error_msg('unexpected', $msg);

        }

    } else {

        my $msg = sprintf("%s", $ex);

        $packet = $self->_rpc_error($id, RPC_ERR_APP, $msg);
        $self->log->error_msg('unexpected', $msg);

    }

    return $packet;

}

sub _rpc_request {
    my $self = shift;
    my ($request, $ctx) = validate_params(\@_, [
        { type => HASHREF },
        { type => HASHREF },
    ]);

    my $method;
    my $alias = $self->alias;
    
    try {

        if ($request->{'jsonrpc'} ne RPC_JSON) {

            $self->throw_msg(
                dotid($self->class) . '.server.rpc_version', 
                'json_rpc_version'
            );

        }

        unless (defined($request->{'id'})) {

            $self->throw_msg(
                dotid($self->class) . '.server.rpc_notify', 
                'json_rpc_notify'
            );

        }

        if ($self->methods->has($request->{'method'})) {

            $ctx->{'id'} = $request->{'id'};
            $self->log->debug("$alias: performing \"" . $request->{'method'} . '"');

            $poe_kernel->post($alias, $request->{'method'}, $request->{'params'}, $ctx);

        } else {

            $self->throw_msg(
                dotid($self->class) . '.server.rpc_method', 
                'json_rpc_method', 
                $request->{'method'}
            );

        }

    } catch {

        my $ex = $_;

        my $output = $self->_rpc_exception_handler($ex, $request->{'id'});
        $poe_kernel->post($alias, 'client_output', encode($output), $ctx);

    };

}

sub _rpc_error {
    my $self = shift;
    my ($id, $code, $message) = validate_params(\@_, [1,1,1]);

    return {
        jsonrpc => RPC_JSON,
        id      => $id,
        error   => {
            code    => $code,
            message => $ERRORS->{$code},
            data    => $message
        }
    };

}

sub _rpc_result {
    my $self = shift;
    my ($id, $result) = validate_params(\@_, [1,1]);

    return {
        jsonrpc => RPC_JSON,
        id      => $id,
        result  => $result
    };

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{'methods'} = Set::Light->new();

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::RPC::JSON::Server - A mixin for a simple JSON RPC server

=head1 SYNOPSIS

 package Echo;

 use POE;
 use XAS::Class
   debug   => 0,
   version => '0.01',
   base    => 'XAS::Lib::RPC::JSON::Server'
 ;

 sub session_initialize {
     my $self = shift;

     my $alias = $self->alias;

     $self->log->debug("$alias: entering session_initialize()");

     # define our events.

     $poe_kernel->state('echo', $self, '_echo');

     # define the RPC methods, these are linked to the above events

     $self->methods->insert('echo');

     # walk the chain

     $self->SUPER::session_initialize();

     $self->log->debug("$alias: leaving session_initialize()");

 }

 sub _echo {
     my ($self, $params, $ctx) = @_[OBJECT, ARGO, ARG1];

     my $alias = $self->alias;
     my $line  = $params->{'line'};

     $self->process_response($line, $ctx);

 }

 package main;

     my $echo = Echo->new();

     $echo->run();

=head1 DESCRIPTION

This modules implements a simple L<JSON RPC v2.0|http://www.jsonrpc.org/specification> 
server. It doesn't support "Notification" calls. 

=head1 METHODS

=head2 new

This module inherits from L<XAS::Lib::Net::Server|XAS::Lib::Net::Server> 
and accepts the same parameters.

=head2 methods

A handle to a L<Set::Light|https://metacpan.org/pod/Set::Light> object 
that contains the methods that can be evoked.

=head2 process_request($input, $ctx)

This method accepts a JSON RPC packet and dispatches to the appropiate handler.
If a handler is not present, it signals an error and returns that to the client.

=over 4

=item B<$input>

The JSON RPC packet.

=item B<$ctx>

Network context for the request.

=back

=head2 process_response($output, $ctx)

This method will process output and convert it into a JSON RPC response. 

=over 4

=item B<$input>

The output from the called handler.

=item B<$ctx>

Network context for the response.

=back

=head2 process_error($error, $ctx)

This method will process errors, it will be converted into a JSON RPC error
response.

=over 4

=item B<$errors>

The errors that were generated. 

=item B<$ctx>

Network context for the response.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::RPC::JSON::Client|XAS::Lib::RPC::JSON::Client>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut

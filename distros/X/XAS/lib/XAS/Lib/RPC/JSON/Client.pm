package XAS::Lib::RPC::JSON::Client;

our $VERSION = '0.02';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::Net::Client',
  utils     => ':validation dotid',
  codec     => 'JSON',
  constants => ':jsonrpc HASHREF',
;

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub call {
    my $self = shift;
    my $p = validate_params(\@_, {
        -method => 1,
        -id     => 1,
        -params => { type => HASHREF }
    });

    my $params;
    my $response;

    while (my ($key, $value) = each(%{$p->{'params'}})) {

        $key =~ s/^-//;
        $params->{$key} = $value;

    }

    my $packet = {
        jsonrpc => RPC_JSON,
        id      => $p->{'id'},
        method  => $p->{'method'},
        params  => $params
    };

    $self->log->debug(Dumper($packet));

    $self->puts(encode($packet));

    if ($response = $self->gets()) {

        $response = decode($response);
        $self->log->debug(Dumper($response));

        if ($response->{'id'} eq $p->{'id'}) {

            $self->_check_for_errors($response);
            return $response->{'result'};

        } else {

            $self->throw_msg(
                dotid($self->class) . '.call.invalid_id',
                'json_rpc_invalid_id',
            );

        }
        
    } else {
        
        $self->throw_msg(
            dotid($self->class) . '.call.invalid_response',
            'json_rpc_invalid_response',
            $p->{'method'}
        );

    }

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _check_for_errors {
    my $self = shift;
    my $response = shift;

    if ($response->{'error'}) {

        $self->throw_msg(
            dotid($self->class) . '.call.rpc_error',
            'json_rpc_error',
            $response->{'error'}->{'code'} || '',
            $response->{'error'}->{'message'} || '',
            $response->{'error'}->{'data'} || '',
        );

    }

}

1;

__END__

=head1 NAME

XAS::Lib::RPC::JSON::Client - A mixin for a JSON RPC interface

=head1 SYNOPSIS
 
 package Client

 use XAS::Class
     debug   => 0,
     version => '0.01',
     base    => 'XAS::Lib::RPC::JSON::Client',
 ;

 package main

  my $client = Client->new(
     -port => 9505,
     -host => 'localhost',
 );
 
 $client->connect();
 
 my $data = $client->call(
     -method => 'test'
     -id     => $id,
     -params => {}
 );
 
 $client->disconnect();
 
=head1 DESCRIPTION

This modules implements a simple L<JSON RPC v2.0|http://www.jsonrpc.org/specification> client. 
It doesn't support "Notification" calls.

=head1 METHODS

=head2 new

This module inherits from L<XAS::Lib::Net::Client|XAS::Lib::Net::Client>.

=head2 call

This method is used to format the JSON packet and send it to the server. 
Any errors returned from the server are parsed and then thrown.

=over 4

=item B<-method>

The name of the RPC method to invoke.

=item B<-id>

The id used to identify this method call.

=item B<-params>

A hashref of the parameters to be passed to the method.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::RPC::JSON::Server|XAS::Lib::RPC::JSON::Server>

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

package VM::EC2::ELB::Listener;

=head1 NAME

VM::EC2::ELB:Listener - Elastic Load Balancer Listener

=head1 SYNOPSIS

 use VM::EC2;

 my $ec2             = VM::EC2->new(...);
 my $lb              = $ec2->describe_load_balancers('my-lb');
 my @http_listeners  = map { grep { $_->LoadBalancerPort eq '80' } $_->Listener } $lb->ListenerDescriptions;

=head1 DESCRIPTION

This object is used to describe a listener attached to an Elastic Load
Balancer.

=head1 METHODS

The following object methods are supported:
 
 Protocol           -- The protocol of the load balancer listener
 LoadBalancerPort   -- The port the listener is listening on
 InstanceProtocol   -- The protocol the load balancer uses to communicate
                       with the instance
 InstancePort       -- The port on the instance the load balancer connects to
 SSLCertificateId   -- The ARN string of the server certificate

=head1 STRING OVERLOADING

When used in a string context, this object will return a string containing
all the parameters of the listener in a pretty format.


=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::ELB>
L<VM::EC2::ELB::ListenerDescription>

=head1 AUTHOR

Lance Kinley E<lt>lkinley@loyaltymethods.comE<gt>.

Copyright (c) 2012 Loyalty Methods, Inc.

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

use strict;
use base 'VM::EC2::Generic';

sub valid_fields {
    my $self = shift;
    return qw(InstancePort InstanceProtocol LoadBalancerPort Protocol SSLCertificateId);
}

use overload
    '""'     => sub {
        my $self = shift;
        my $string = $self->Protocol . ':' . $self->LoadBalancerPort . ' --> ' . $self->InstanceProtocol . ':' . $self->InstancePort;
        my $ssl_id = $self->SSLCertificateId;
        $string .= ':' . $ssl_id if (defined $ssl_id);
        return $string},
    fallback => 1;

sub InstanceProtocol {
    my $self = shift;
    my $instance_protocol = $self->SUPER::InstanceProtocol;
    return defined $instance_protocol ? $instance_protocol : $self->Protocol;
}

1;

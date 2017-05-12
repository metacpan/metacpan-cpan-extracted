package VM::EC2::VPC::InternetGateway;

=head1 NAME

VM::EC2::VPC::InternetGateway -- A VPC internet gateway

=head1 SYNOPSIS

 use VM::EC2;
 my $ec2      = VM::EC2->new(...);
 my @gateways = $ec2->describe_internet_gateways;
 
 for my $gw (@gateways) {
    print $gw->internetGatewayId,"\n";
    my @attachments = $gw->attachments;
 }

=head1 DESCRIPTION

This object provides information about EC2 Virtual Private Cloud
internet gateways, which, together with routing tables, allow
instances within a VPC to communicate with the outside world.

=head1 METHODS

These object methods are supported:
 
 internetGatewayId   -- the ID of the gateway
 attachments         -- An array of VM::EC2::VPC::InternetGateway::Attachment
                        objects, each describing a VPC attached to this gateway.

This class supports the VM::EC2 tagging interface. See
L<VM::EC2::Generic> for information.

In addition, this object supports the following convenience methods:

 attach($vpc)          -- Attach this gateway to the indicated VPC (ID or
                          VM::EC2::VPC object).
 detach($vpc)          -- Detach this gateway from the indicated VPC (ID or
                          VM::EC2::VPC object).
 refresh               -- Refreshes the contents of the object, primarily to
                          check for changes in attachment state.

=head1 STRING OVERLOADING

When used in a string context, this object will be interpolated as the
internet gateway ID.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::VPC>

=head1 AUTHOR

Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Copyright (c) 2012 Ontario Institute for Cancer Research

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

use strict;
use Carp 'croak';
use base 'VM::EC2::Generic';
use VM::EC2::VPC::InternetGateway::Attachment;

sub valid_fields {
    my $self  = shift;
    return qw(internetGatewayId attachmentSet);
}

sub primary_id { shift->internetGatewayId }

sub attachments {
    my $self = shift;
    my $set  = $self->attachmentSet or return;
    return map {VM::EC2::VPC::InternetGateway::Attachment->new($_,$self->aws)} @{$set->{item}};
}

sub attach {
    my $self = shift;
    my $vpc  = shift or croak "Usage: attach(\$vpc)";
    my $result = $self->aws->attach_internet_gateway($self=>$vpc);
    $self->refresh if $result;
    return $result;
}

sub detach {
    my $self = shift;
    my $vpc  = shift or croak "Usage: detach(\$vpc)";
    my $result = $self->aws->detach_internet_gateway($self => $vpc);
    $self->refresh if $result;
    return $result;
}

sub refresh {
    my $self = shift;
    my $i   = shift;
    local $self->aws->{raise_error} = 1;
    ($i) = $self->aws->describe_internet_gateways($self->internetGatewayId) unless $i;
    %$self  = %$i if $i;
    return defined $i;
}

1;


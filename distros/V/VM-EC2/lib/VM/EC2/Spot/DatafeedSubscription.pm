package VM::EC2::Spot::DatafeedSubscription;

=head1 NAME

VM::EC2::Spot::DatafeedSubscription - Object describing an Amazon EC2 spot instance datafeed subscription

=head1 SYNOPSIS

  use VM::EC2;

  $ec2     = VM::EC2->new(...);
  $sub     = $ec2->create_spot_datafeed_subscription('myBucket','SPOT:');
  my $owner  = $sub->ownerId;
  my $bucket = $sub->bucket;
  my $prefix = $sub->prefix;
  my $state  = $sub->state;
  my $error  = $sub->fault;

=head1 DESCRIPTION

This object represents an Amazon EC2 spot instance datafeed subscription, 
and is returned by VM::EC2->create_spot_datafeed_subscription() and 
VM::EC2->describe_spot_datafeed_subscription().

=head1 METHODS

These object methods are supported:

 ownerId         -- ID of the owner of this subscription
 bucket          -- bucket receiving the subscription files
 prefix          -- prefix for log files written into the bucket
 state           -- state of the subscription; one of 'Active' or 'Inactive'
 fault           -- VM::EC2::Error object describing errors in the
                     subscription.
=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>

=head1 AUTHOR

Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Copyright (c) 2011 Ontario Institute for Cancer Research

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
    return qw(ownerId bucket prefix state fault);
}

sub fault {
    my $self = shift;
    my $f    = $self->SUPER::fault or return;
    return VM::EC2::Error->new($f,$self->ec2);
}
1;

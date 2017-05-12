package VM::EC2::Instance::Status::Details;

=head1 NAME

VM::EC2::Instance::Status::Details - Object describing the details of an instance status check

=head1 SYNOPSIS

 @status_items = $ec2->describe_instance_status();
 for my $i (@status_items) {
    print $i->instance_id,
           ': instance check=',$i->instance_status,
           ', system check=',$i->system_status,"\n";
   if ($i->instance_status ne 'ok') {
      my @details = $i->instance_status->details;
      for my $d (@details) {
            print $d->name,"\n";
            print $d->status,"\n";
            print $d->impaired_since,"\n";
      }
   }
 }

=head1 DESCRIPTION

This object represents additional details about a failed system or
instance status check.

=head1 METHODS

These methods are supported:

 name()           -- The type of instance status detail, such as "reachability".
 status()         -- The status of the check, "passed", "failed" or "insufficient-data".
 impaired_since() -- The time when a status check failed as a DateTime string.

In a string context, this object interpolates as the name().

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::Instance>
L<VM::EC2::Instance::State>
L<VM::EC2::Instance::StatusItem>
L<VM::EC2::Instance::Status>
L<VM::EC2::Instance::Status::Event>
L<VM::EC2::Tag>

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
use base 'VM::EC2::Generic';

use strict;

sub valid_fields {
    my $self = shift;
    return qw(name status impairedSince);
}

sub short_name {
    my $self = shift;
    my $status = $self->status;
    my $name   = $self->name;
    my $since  = $self->impairedSince;
    if ($since) {
	return "$name $status since $since";
    } else {
	return "$name $status";
    }
}

1;


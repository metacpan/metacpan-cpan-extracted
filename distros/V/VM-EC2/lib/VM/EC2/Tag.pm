package VM::EC2::Tag;

=head1 NAME

VM::EC2::Tag -- Object describing a tagged Amazon EC2 resource

=head1 SYNOPSIS

  use VM::EC2;

  $ec2       = VM::EC2->new(...);
  @tags = $ec2->describe_tags(-filter=> {'resource-type'=>'volume'});
  for my $t (@tags) {
     $id    = $t->resourceId;
     $type  = $t->resourceType;
     $key   = $t->key;
     $value = $t->value;
  }

=head1 DESCRIPTION

This object is used to describe an Amazon EC2 tag. Each object
contains information about the resource it is tagging, the tag key,
and the tag value. Tags are returned by the VM::EC2->describe_tags()
method.

In most cases you will not want to work with this object directly, but
instead read tags by calling a resource object's tags() method, which
returns a hash of key value pairs, or specify particular tag values as
one of the filters in a describe_*() call.

=head1 METHODS

The following object methods are supported:
 
 resourceId    -- The ID of the resource being tagged.
 resourceType  -- The type of the resource being tagged e.g. "image"
 key           -- The tag key.
 value         -- The tag value.

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
resourceId.

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

use overload 
    '""'     => sub {
	my $self = shift;
	return $self->resourceId},
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(resourceId resourceType key value);
}

1;

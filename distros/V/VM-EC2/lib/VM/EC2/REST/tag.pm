package VM::EC2::REST::tag;

use strict;
use VM::EC2 '';  # important not to import anything!
package VM::EC2;  # add methods to VM::EC2

VM::EC2::Dispatch->register(
    CreateTags        => 'boolean',
    DeleteTags        => 'boolean',
    DescribeTags      => 'fetch_items,tagSet,VM::EC2::Tag,nokey',
    );

=head1 NAME VM::EC2::REST::tag

=head1 SYNOPSIS
 
 use VM::EC2 ':standard';

=head1 METHODS

These methods allow you to create, delete and fetch resource tags. You
may find that you rarely need to use these methods directly because
every object produced by VM::EC2 supports a simple tag interface:

  $object = $ec2->describe_volumes(-volume_id=>'vol-12345'); # e.g.
  $tags = $object->tags();
  $name = $tags->{Name};
  $object->add_tags(Role => 'Web Server', Status=>'development);
  $object->delete_tags(Name=>undef);

See L<VM::EC2::Generic> for a full description of the uniform object
tagging interface.

These methods are most useful when creating and deleting tags for
multiple resources simultaneously.

Implemented:
 CreateTags
 DeleteTags
 DescribeTags

Unimplemented:
 (none)

=head2 @t = $ec2->describe_tags(-filter=>\%filters);

Return a series of VM::EC2::Tag objects, each describing an
AMI. A single optional -filter argument is allowed.

Available filters are: key, resource-id, resource-type and value. See
http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeTags.html

=cut

sub describe_tags {
    my $self = shift;
    my %args = @_;
    my @params = $self->filter_parm(\%args);
    return $self->call('DescribeTags',@params);    
}

=head2 $bool = $ec2->create_tags(-resource_id=>\@ids,-tag=>{key1=>value1...})

Tags the resource indicated by -resource_id with the tag(s) in in the
hashref indicated by -tag. You may specify a single resource by
passing a scalar resourceId to -resource_id, or multiple resources
using an anonymous array. Returns a true value if tagging was
successful.

The method name "add_tags()" is an alias for create_tags().

You may find it more convenient to tag an object retrieved with any of
the describe() methods using the built-in add_tags() method:

 @snap = $ec2->describe_snapshots(-filter=>{status=>'completed'});
 foreach (@snap) {$_->add_tags(ReadyToUse => 'true')}

but if there are many snapshots to tag simultaneously, this will be faster:

 @snap = $ec2->describe_snapshots(-filter=>{status=>'completed'});
 $ec2->add_tags(-resource_id=>\@snap,-tag=>{ReadyToUse=>'true'});

Note that you can tag volumes, snapshots and images owned by other
people. Only you will be able to see these tags.

=cut

sub create_tags {
    my $self = shift;
    my %args = @_;
    $args{-resource_id} or croak "create_tags() -resource_id argument required";
    $args{-tag}         or croak "create_tags() -tag argument required";
    my @params = $self->list_parm('ResourceId',\%args);
    push @params,$self->tagcreate_parm(\%args);
    return $self->call('CreateTags',@params);    
}

sub add_tags { shift->create_tags(@_) }

=head2 $bool = $ec2->delete_tags(-resource_id=>$id1,-tag=>{key1=>value1...})

Delete the indicated tags from the indicated resource. Pass an
arrayref to operate on several resources at once. The tag syntax is a
bit tricky. Use a value of undef to delete the tag unconditionally:

 -tag => { Role => undef }    # deletes any Role tag

Any scalar value will cause the tag to be deleted only if its value
exactly matches the specified value:

 -tag => { Role => 'Server' }  # only delete the Role tag
                               # if it currently has the value "Server"

An empty string value ('') will only delete the tag if its value is an
empty string, which is probably not what you want.

Pass an array reference of tag names to delete each of the tag names
unconditionally (same as passing a value of undef):

 $ec2->delete_tags(['Name','Role','Description']);

You may find it more convenient to delete tags from objects using
their delete_tags() method:

 @snap = $ec2->describe_snapshots(-filter=>{status=>'completed'});
 foreach (@snap) {$_->delete_tags(Role => undef)}

=cut

sub delete_tags {
    my $self = shift;
    my %args = @_;
    $args{-resource_id} or croak "create_tags() -resource_id argument required";
    $args{-tag}         or croak "create_tags() -tag argument required";
    my @params = $self->list_parm('ResourceId',\%args);
    push @params,$self->tagdelete_parm(\%args);
    return $self->call('DeleteTags',@params);    
}

=head2 @arguments = $ec2->tagcreate_parm(\%args)

=cut

sub tagcreate_parm {
    my $self = shift;
    my $args = shift;
    return $self->key_value_parameters('Tag','Key','Value',$args);
}

=head2 @arguments = $ec2->tagdelete_parm(\%args)

=cut

sub tagdelete_parm {
    my $self = shift;
    my $args = shift;
    return $self->key_value_parameters('Tag','Key','Value',$args,1);
}

=head1 SEE ALSO

L<VM::EC2>

=head1 AUTHOR

Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Copyright (c) 2011 Ontario Institute for Cancer Research

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut


1;

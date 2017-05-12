package UMMF::Object::Extent;

use 5.6.1;
use strict;
#use warnings;


our $AUTHOR = q{ kstephens@users.sourceforge.net 2003/10/05 };
our $VERSION = do { my @r = (q$Revision: 1.4 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::Object::Extent - Traces the extent of objects.

=head1 SYNOPSIS

  my $extent = UMML::Object::Extent->new();

  # Begin tracing extents of UML::__ObjectBase.
  UML::__ObjectBase->add___extent($extent);

  ... Create some objects that are subclasses of UML::__ObjectBase ...

  # Select all objects where $object->isaAttribute is true.
  my @attributes = $extent->object_where(sub { shift->isaAttribute });

  UML::__ObjectBase->remove___extent($extent);

=head1 DESCRIPTION

Extents are used to capture and manipulate collections of objects in a particular context.

For example: object databases are extents because they capture objects that are stored in databases; a CGI application session is an extent because it captures objects (i.e. values) to be stored and retrieved.

This class provides a base class for extents.

Although this class captures creation of objects, it uses weak references such that captured objects are still subjected to garbage collection.

=head1 USAGE

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@users.sourceforge.net 2003/10/05

=head1 SEE ALSO

L<UMMF|UMMF>

=head1 VERSION

$Revision: 1.4 $

=head1 METHODS

=cut

#######################################################################

use Scalar::Util qw(weaken);

#######################################################################

sub initialize
{
  my ($self) = @_;

  $self->SUPER::initialize;

  $self->{'id'} = 0;
  $self->{'object'} = { };
  $self->{'classifier'} = [ ];

  $self;
}


#######################################################################


sub add_classifier
{
  my ($self, $cls) = @_;

  my $v = $self->{'classifier'};

  push(@$v, $cls);

  $self;
}


sub remove_classifier
{
  my ($self, $cls) = @_;

  my $v = $self->{'classifier'};

  @$v = grep($_ ne $cls, @$v);

  $self;
}


#######################################################################


=head2 add_object

  $extent->add_object($obj);

Called when a Classifier creates a new object.

This will assign an id, unique to this Extent.  The id can be used to retrieve the object using C<<$extent->object_by_id($id)>>.

Returns the assigned id.

=cut
sub add_object
{
  my ($self, $obj) = @_;

  my $v = $self->{'object'};

  my $id = ++ $self->{'id'};

  weaken($v->{$id} = $obj);

  $id;
}


#######################################################################


sub true { 1 };


#######################################################################


sub object
{
  my ($self) = @_;

  $self->object_where(\&true);
}


#######################################################################


=head2 object_where

  my @obj = $extent->object_where($predicate);

Returns all C<$object>s where C<<$predicate->($object)>> is true.

Any objects that have been garbage-collected will not be selected.

=cut
sub object_where
{
  my ($self, $predicate) = @_;

  my $v = $self->{'object'};

  my @v = grep(defined $_ && $predicate->($_), values %$v);

  wantarray ? @v : \@v;  
}


#######################################################################


=head2 object_by_id

  my $obj = $extent->object_by_id($id);

Returns the object stored in this Extent that was assigned the C<<$id>>.

If the object has been garbage collected, this will return C<undef>.

=cut
sub object_by_id
{
  my ($self, $id) = @_;

  my $v = $self->{'object'};

  defined $v->{$id} ? $v->{$id} : delete $v->{$id};
}


#######################################################################

1;

#######################################################################


### Keep these comments at end of file: kstephens@users.sourceforge.net 2003/10/05 ###
### Local Variables: ###
### mode:perl ###
### perl-indent-level:2 ###
### perl-continued-statement-offset:0 ###
### perl-brace-offset:0 ###
### perl-label-offset:0 ###
### End: ###


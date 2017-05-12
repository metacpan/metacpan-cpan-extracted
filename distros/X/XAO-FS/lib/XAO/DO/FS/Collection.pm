=head1 NAME

XAO::DO::FS::Collection - Collection class for XAO::FS

=head1 SYNOPSIS

 my $orders=$odb->collection(class => 'Data::Order');

 my $sr=$orders->search('placed_by', 'eq', 'user@host.name');

=head1 DESCRIPTION

Collection class is similar to List object in the sense that it contains
Hash objects joined by some criteria.

All Collection objects are read-only, you can use them to search for
data and to get data objects from them but not to store.

Methods are (alphabetically):

=over

=cut

###############################################################################
package XAO::DO::FS::Collection;
use strict;
use XAO::Utils;
use XAO::Objects;

use base XAO::Objects->load(objname => 'FS::Glue');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Collection.pm,v 2.1 2005/01/14 00:23:54 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

=item container_key ()

Makes no sense for Collection, will throw an error.

=cut

sub container_key () {
    my $self=shift;
    $self->throw("container_key() - makes no sense on Collection object");
}

###############################################################################

=item delete ($)

Makes no sense for Collection, will throw an error.

=cut

sub delete () {
    my $self=shift;
    $self->throw("delete() - makes no sense on Collection object");
}

###############################################################################

=item describe () {

Describes itself, returns a hash reference with at least the following
elements:

 type       => 'collection'
 class      => class name
 key        => key name

=cut

sub describe ($;$) {
    my $self=shift;
    return {
        type    => @_ ? 'hash' : 'collection',
        class   => $$self->{class_name},
        key     => $$self->{key_name},
    };
}

###############################################################################

=item detach ()

Not implemented, but safe to use.

=cut

sub detach ($) {
}

###############################################################################

=item exists ($)

Checks if an object with the given name exists in the collection and
returns boolean value.

=cut

sub exists ($$) {
    my $self=shift;
    my $name=shift;
    $self->_collection_exists($name);
}

###############################################################################

=item get (@)

Retrieves a Hash object from the Collection using the given name.

As a convenience you can pass more then one object name to the get()
method to retrieve multiple Hash references at once.

If an object does not exist an error will be thrown, use exists() method
to check if you really need to.

Note: It does not check if the object still exists in the database! If
you need to be sure that the object does exist use

=cut

sub get ($$) {
    my $self=shift;

    $self->throw("get - at least one ID required") unless @_;

    my @results=map {
        $_ ||
            throw $self "get - no object ID given";
        ref($_) &&
            throw $self "get - should be a scalar, not a ".ref($_)." reference";
        XAO::Objects->new(
            objname         => $$self->{class_name},
            glue            => $self->_glue,
            unique_id       => $_,
            key_name        => $$self->{key_name},
            list_base_name  => $$self->{base_name},
        );
    } @_;

    @_==1 ? $results[0] : @results;
}

###############################################################################

=item get_new ()

Convenience method that returns new empty detached object of the type
that collection operates on.

=cut

sub get_new ($) {
    my $self=shift;
    $self->glue->new(objname => $$self->{class_name});
}

###############################################################################

=item glue ()

Returns the Glue object which was used to retrieve the current object
from.

=cut

# Implemented in Glue

###############################################################################

=item keys ()

Returns unsorted list of all keys for all objects stored in that list.

=cut

sub keys ($) {
    my $self=shift;

    @{$self->_collection_keys()};
}

###############################################################################

=item new (%)

You cannot use this method directly. Use collection() method on Glue to
get a collection reference. Example:

 my $orders=$odb->collection(class => 'Data::Order');

Currently the only supported type of collection is by class name, a
collection that joins together all Hashes of the same class.

=cut

sub new ($%) {
    my $class=shift;
    my $self=$class->SUPER::new(@_);

    my $args=get_args(\@_);
    $$self->{class_name}=$args->{class} || $args->{class_name};

    $self->_collection_setup();

    $self;
}

###############################################################################

=item objtype ()

For all Collection objects always return a string 'Collection'.

=cut

sub objtype ($) {
    'Collection';
}

###############################################################################

=item put ($;$)

Makes no sense on collections. Will throw an error.

=cut

sub put ($$;$) {
    my $self=shift;
    $self->throw("put - you can't store into collections");
}

###############################################################################

=item search (@)

Supports the same syntax as List's search() method. See
L<XAO::DO::FS::List> for reference.

=cut

sub search ($@) {
    my $self=shift;
    $self->_list_search(@_);
}

###############################################################################

=item values ()

Returns a list of all Hash objects in the list.

B<Note:> the order of values is the same as the order of keys returned
by keys() method. At least until you modify the object directly on
indirectly. It is not recommended to use values() method for the reason
of pure predictability.

=cut

# implemented in Glue.pm

###############################################################################

=item uri ($)

Makes no sense on collections, will throw an error.

=cut

sub uri () {
    my $self=shift;
    $self->throw("uri - makes no sense on collections");
}

###############################################################################
1;
__END__

=back

=head1 AUTHORS

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Further reading:
L<XAO::FS>,
L<XAO::DO::FS::Hash> (aka FS::Hash),
L<XAO::DO::FS::List> (aka FS::List).
L<XAO::DO::FS::Glue> (aka FS::Glue).

=cut

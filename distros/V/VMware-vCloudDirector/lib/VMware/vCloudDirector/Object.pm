package VMware::vCloudDirector::Object;

# ABSTRACT: Module to contain an object!

use strict;
use warnings;

our $VERSION = '0.006'; # VERSION
our $AUTHORITY = 'cpan:NIGELM'; # AUTHORITY

use Moose;
use Method::Signatures;
use Ref::Util qw(is_plain_hashref);
use Lingua::EN::Inflexion;
use VMware::vCloudDirector::ObjectContent;

# ------------------------------------------------------------------------


has api => (
    is            => 'ro',
    isa           => 'VMware::vCloudDirector::API',
    required      => 1,
    weak_ref      => 1,
    documentation => 'API we use'
);

has content => (
    is            => 'ro',
    isa           => 'VMware::vCloudDirector::ObjectContent',
    predicate     => 'has_content',
    writer        => '_set_content',
    documentation => 'The underlying content object',
    handles       => [qw( mime_type href type name )],
);

has _partial_object => ( is => 'rw', isa => 'Bool', default => 0 );

# delegates that force a full object to be pulled
method hash () { return $self->inflate->content->hash; }
method links () { return $self->inflate->content->links; }
method id () { return $self->inflate->content->id; }

# ------------------------------------------------------------------------
method BUILD ($args) {

    $self->_set_content(
        VMware::vCloudDirector::ObjectContent->new( object => $self, hash => $args->{hash} ) );
}

# ------------------------------------------------------------------------


method inflate () {
    $self->refetch if ( $self->_partial_object );
    return $self;
}

# ------------------------------------------------------------------------
method refetch () {
    my $hash = $self->api->GET_hash( $self->href );
    $self->_set_content(
        VMware::vCloudDirector::ObjectContent->new( object => $self, hash => $hash ) );
    $self->api->_debug(
        sprintf(
            'Object: %s a [%s]',
            ( $self->_partial_object ? 'Inflated' : 'Refetched' ),
            $self->type
        )
    ) if ( $self->api->debug );
    $self->_partial_object(0);
    return $self;
}

# ------------------------------------------------------------------------


method find_links (:$name, :$type, :$rel) {
    my @matched_links;
    my $links = $self->links;
    foreach my $link ( @{$links} ) {
        if ( not( defined($rel) ) or ( $rel eq ( $link->rel || '' ) ) ) {
            if ( not( defined($type) ) or ( $type eq ( $link->type || '' ) ) ) {
                if ( not( defined($name) ) or ( $name eq ( $link->name || '' ) ) ) {
                    push( @matched_links, $link );
                }
            }
        }
    }
    return @matched_links;
}

# ------------------------------------------------------------------------


method fetch_links (@search_items) {
    my @matched_objects;
    foreach my $link ( $self->find_links(@search_items) ) {
        push( @matched_objects, $link->GET() );
    }
    return @matched_objects;
}

# ------------------------------------------------------------------------
method _create_object ($hash, $type='Thing') {

    # if thing has Link content within it then it is a full object, otherwise it
    # is just a stub
    my $object = VMware::vCloudDirector::Object->new(
        hash => { $type => $hash },
        api  => $self->api,
        _partial_object => ( exists( $hash->{Link} ) ) ? 0 : 1,
    );
    $self->api->_debug(
        sprintf(
            'Object: [%s] instantiated %s for [%s]',
            $self->type, ( $object->_partial_object ? 'a stub' : 'an object' ),
            $object->type
        )
    ) if ( $self->api->debug );
    return $object;
}

# ------------------------------------------------------------------------


method build_sub_objects ($type) {
    my @objects;
    my $container_type = noun($type)->plural;
    return
        unless ( exists( $self->hash->{$container_type} )
        and is_plain_hashref( $self->hash->{$container_type} ) );
    foreach my $thing ( $self->_listify( $self->hash->{$container_type}{$type} ) ) {
        push( @objects, $self->_create_object( $thing, $type ) );
    }
    return @objects;
}

method build_children_objects () {
    my $hash = $self->hash;
    return unless ( exists( $hash->{Children} ) and is_plain_hashref( $hash->{Children} ) );
    my @objects;
    foreach my $key ( keys %{ $hash->{Children} } ) {
        foreach my $thing ( $self->_listify( $self->hash->{Children}{$key} ) ) {
            push( @objects, $self->_create_object( $thing, $key ) );
        }
    }
    return @objects;
}

# ------------------------------------------------------------------------


method DELETE () { return $self->api->GET( $self->href ); }


method GET () { return $self->api->GET( $self->href ); }


method POST ($xml_hash) { return $self->api->GET( $self->href, $xml_hash ); }


method PUT ($xml_hash) { return $self->api->GET( $self->href, $xml_hash ); }

# ------------------------------------------------------------------------
method _listify ($thing) { !defined $thing ? () : ( ( ref $thing eq 'ARRAY' ) ? @{$thing} : $thing ) }

# ------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

VMware::vCloudDirector::Object - Module to contain an object!

=head1 VERSION

version 0.006

=head2 Attributes

=head3 api

A weak link to the API object to be used.

=head3 content

The object content.  This is in a separate container so that partial objects
passed can be inflated at a later stage without having to replace the object
itself.

=head3 hash

A reference to the hash returned from the vCloud XML.  Forces object inflation.

=head3 links

An array references to the links contained in this object.  Forces object
inflation.

=head3 id

The id attribute from the returned vCloud XML.  Forces object inflation.

=head2 Methods

=head3 inflate

If this object is a partial object (ie taken from a link or partial chunk
within a containing object), then this forces a refetch of the content from
vCloud creating a fully populated object.

=head3 refetch

Forces a refetch of this object's content unconditionally.

=head3 find_links

Returns any links found that match the search criteria.  The possible criteria
are:-

=over 4

=item name

The name of the link

=item type

The type of the link (short type, not full MIME type)

=item rel

The rel of the link

=back

The return value is a list of link objects.

=head3 fetch_links

As per L</find_links> except that each link found is fetched and expanded up as
an object.

=head3 build_sub_objects

Given a type (specifically a key used within the current object hash), grabs
the descendants of that key and instantiates them as partial objects (they can
then be inflated into full objects).

Due to the structure of the XML there will always be two layers, the inner
named singular thing, and the outer named as the plural of thing.  Hence this
does magic with the language inflection module.

=head3 DELETE

Make a delete request to the URL of this object.  Returns Objects.  Failure
will generate an exception.  See L<VMware::vCloudDirector::API/DELETE>.

=head3 GET

Make a get request to the URL of this object.  Returns Objects.  Failure will
generate an exception.  See L<VMware::vCloudDirector::API/GET>.

=head3 POST

Make a post request with the specified payload to the URL of this object.
Returns Objects.  Failure will generate an exception.  See
L<VMware::vCloudDirector::API/POST>.

=head3 PUT

Make a put request with the specified payload to the URL of this object.
Returns Objects.  Failure will generate an exception.  See
L<VMware::vCloudDirector::API/PUT>.

=head1 AUTHOR

Nigel Metheringham <nigelm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Nigel Metheringham.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

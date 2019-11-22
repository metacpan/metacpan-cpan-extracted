package VMware::vCloudDirector2::Object;

# ABSTRACT: Module to contain an object!

use strict;
use warnings;

our $VERSION = '0.107'; # VERSION
our $AUTHORITY = 'cpan:NIGELM'; # AUTHORITY

use Moose;
use Method::Signatures;
use MooseX::Types::URI qw(Uri);
use Const::Fast;
use Ref::Util qw(is_plain_hashref is_plain_arrayref);
use VMware::vCloudDirector2::Link;
use VMware::vCloudDirector2::Error;

# ------------------------------------------------------------------------


has api => (
    is            => 'ro',
    isa           => 'VMware::vCloudDirector2::API',
    required      => 1,
    weak_ref      => 1,
    documentation => 'API we use'
);

has mime_type => ( is => 'ro', isa => 'Str', required => 1 );
has href => ( is => 'ro', isa => Uri,   required => 1, coerce => 1 );
has type => ( is => 'ro', isa => 'Str', required => 1 );
has uuid => ( is => 'ro', isa => 'Str', builder  => '_build_uuid', lazy => 1 );
has name =>
    ( is => 'ro', isa => 'Str', predicate => 'has_name', lazy => 1, builder => '_build_name' );
has id => ( is => 'ro', isa => 'Str', predicate => 'has_id', lazy => 1, builder => '_build_id' );

has _partial_object => ( is => 'rw', isa => 'Bool', default => 0 );
has is_json         => ( is => 'rw', isa => 'Bool', default => 0 );

# ------------------------------------------------------------------------
around BUILDARGS => sub {
    my ( $orig, $class, $first, @rest ) = @_;

    my $params = is_plain_hashref($first) ? $first : { $first, @rest };
    if ( $params->{hash} ) {
        my $hash = $params->{hash};

        # copy elements into object attributes
        foreach (qw[href name id]) {
            $params->{$_} = $hash->{$_} if ( exists( $hash->{$_} ) and defined( $hash->{$_} ) );
        }

        # set the object type and mime_type
        if ( exists( $hash->{type} ) ) {
            $params->{mime_type} = $hash->{type};
            $params->{type}      = $1
                if ( $hash->{type} =~ m!^application/vnd\..*\.(\w+)\+(json|xml)$! );
            $params->{is_json} = ( $2 eq 'json' ) ? 1 : 0;
        }

        # if this has a links section it is a complete object, otherwise its partial
        if ( exists( $hash->{link} ) ) {
            $params->{_partial_object} = 0;
            const $params->{hash} => $hash;    # force hash read-only to stop people playing
        }
        else {
            $params->{_partial_object} = 1;
            delete( $params->{hash} );         # do not populate the hash in the partial object
        }
    }
    else {
        # no hash so this must be a partial object
        $params->{_partial_object} = 1;
    }
    return $class->$orig($params);
};

# ------------------------------------------------------------------------
has hash => (
    is      => 'ro',
    traits  => ['Hash'],
    isa     => 'HashRef',
    builder => '_build_hash',
    clearer => '_clear_hash',
    lazy    => 1,
    handles => { get_hash_item => 'get', exists_hash_item => 'exists', }
);

method _build_hash () {

    # fetch object content
    const my $hash => $self->api->GET_hash( $self->href );
    $self->api->_debug(
        sprintf(
            'Object: %s a [%s]',
            ( $self->_partial_object ? 'Inflated' : 'Refetched' ),
            $self->type
        )
    ) if ( $self->api->debug );

    # mark as being a whole object
    $self->_partial_object(0);

    return $hash;
}

method _build_name () { return $self->get_hash_item('name'); }
method _build_id () { return $self->get_hash_item('id'); }

method _build_uuid () {

    # The UUID is in the href - return the first match
    my $path = lc( $self->href->path() );
    return $1
        if ( $path =~ m|\b([0-9a-f]{8}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{12})\b| );
    return;
}

# ------------------------------------------------------------------------

has _links => (
    is      => 'ro',
    traits  => ['Array'],
    isa     => 'ArrayRef[VMware::vCloudDirector2::Link]',
    lazy    => 1,
    builder => '_build_links',
    clearer => '_clear_links',
    handles => { links => 'elements', },
);
has _all_links => (
    is      => 'ro',
    traits  => ['Array'],
    isa     => 'ArrayRef[VMware::vCloudDirector2::Link]',
    lazy    => 1,
    builder => '_build_all_links',
    clearer => '_clear_all_links',
    handles => { all_links => 'elements', },
);

method _build_links () {
    my @links = grep { $_->is_json } $self->all_links;
    return \@links;
}

method _build_all_links () {
    my @links;
    if ( exists( $self->hash->{link} ) ) {
        push( @links, VMware::vCloudDirector2::Link->new( hash => $_, object => $self ) )
            foreach ( $self->_listify( $self->hash->{link} ) );
    }
    return \@links;
}

# ------------------------------------------------------------------------


has is_admin_object => (
    is            => 'ro',
    isa           => 'Bool',
    lazy          => 1,
    builder       => '_build_is_admin_object',
    documentation => 'Is this an admin level object?',
);
method _build_is_admin_object () { return ( $self->href->path() =~ m|/api/admin/| ) ? 1 : 0; }

# ------------------------------------------------------------------------


method inflate () {
    $self->refetch if ( $self->_partial_object );
    return $self;
}

# ------------------------------------------------------------------------
method refetch () {

    # simplest way to force the object to be refetched is to clear the hash
    # and then request it which forces a lazy eval
    $self->_clear_hash;
    $self->_clear_links;
    $self->_clear_all_links;
    $self->hash;

    return $self;
}

# ------------------------------------------------------------------------


method find_links (:$name, :$type, :$rel) {
    my @matched_links;
    foreach my $link ( $self->links ) {
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


method find_link (@criteria) {
    my @matched_links = $self->find_links(@criteria);
    unless ( scalar(@matched_links) ) {
        VMware::vCloudDirector2::Error->throw(
            {   message => sprintf( "No links matching criteria: %s", join( ', ', @criteria ) ),
                object  => $self
            }
        );
    }
    return $matched_links[0];
}
method fetch_link (@search_items) { return $self->find_link(@search_items)->GET(); }

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
    my $object = VMware::vCloudDirector2::Object->new(
        hash            => $hash,
        api             => $self->api,
        _partial_object => ( exists( $hash->{link} ) ) ? 0 : 1,
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

    return unless ( exists( $self->hash->{$type} ) );
    foreach my $thing ( $self->_listify( $self->hash->{$type} ) ) {
        push( @objects, $self->_create_object( $thing, $type ) );
    }
    return @objects;
}

method build_sub_sub_objects ($type, $subtype) {
    my @objects;

    return unless ( exists( $self->hash->{$type} ) and is_plain_hashref( $self->hash->{$type} ) );
    return unless ( exists( $self->hash->{$type}{$subtype} ) );
    foreach my $thing ( $self->_listify( $self->hash->{$type}{$subtype} ) ) {
        push( @objects, $self->_create_object( $thing, $subtype ) );
    }
    return @objects;
}

method build_children_objects () {
    my $hash = $self->hash;
    return unless ( exists( $hash->{children} ) and is_plain_hashref( $hash->{children} ) );
    my @objects;
    foreach my $key ( keys %{ $hash->{children} } ) {
        foreach my $thing ( $self->_listify( $self->hash->{children}{$key} ) ) {
            push( @objects, $self->_create_object( $thing, $key ) );
        }
    }
    return @objects;
}

# ------------------------------------------------------------------------


method DELETE () { return $self->api->DELETE( $self->href ); }


method GET () { return $self->api->GET( $self->href ); }
method GET_hash () { return $self->api->GET_hash( $self->href ); }


method POST ($hash) { return $self->api->POST( $self->href, $hash, $self->mime_type ); }


method PUT ($hash) { return $self->api->PUT( $self->href, $hash, $self->mime_type ); }

# ------------------------------------------------------------------------


method fetch_admin_object ($subpath?) {
    if ( $self->is_admin_object and not( defined($subpath) ) ) {
        return $self;
    }
    else {
        my $uri  = $self->href;
        my $path = $uri->path;
        $path =~ s|^/api/|api/admin/|;
        $path .= '/' . $subpath if ( defined($subpath) );
        return $self->api->GET($path);
    }
}

# ------------------------------------------------------------------------
method _listify ($thing) { !defined $thing ? () : ( ( ref $thing eq 'ARRAY' ) ? @{$thing} : $thing ) }

# ------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

VMware::vCloudDirector2::Object - Module to contain an object!

=head1 VERSION

version 0.107

=head2 Attributes

=head3 api

A weak link to the API object to be used.

=head3 content

The object content.  This is in a separate container so that partial objects
passed can be inflated at a later stage without having to replace the object
itself.

=head3 hash

A reference to the hash returned from the vCloud API.  Forces object inflation.

=head3 links

Returns L<VMware::vCloudDirector2::Link> objects for each of the JSON targetted
links contained in this object.  Forces object inflation.

=head3 all_links

Returns L<VMware::vCloudDirector2::Link> objects for each of the links
contained in this object.  Will typically return two links per thing - one to
the XML version, one to the JSON version.  Forces object inflation.

=head3 id

The id attribute from the returned vCloud JSON.  Forces object inflation.

=head3 is_admin_object

This determines, based on the href path, whether or not this is an admin
object.

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

=head3 find_link

Finds and returns one link that matches the search criteria, exactly as
L<find_links>, except that if no links are found an exception is thrown.  If
multiple links match then the first one returned (normally the first one back
from the API) would be returned.

The return value is a single link object.

=head3 fetch_link

As per L</find_link> except that the link found is fetched and expanded up as
an object.

=head3 fetch_links

As per L</find_links> except that each link found is fetched and expanded up as
an object.

=head3 build_sub_objects

Given a type (specifically a key used within the current object hash), grabs
the descendants of that key and instantiates them as partial objects (they can
then be inflated into full objects).

=head3 build_sub_sub_objects

Similar to L<build_sub_objects>, but builds objects from two levels down.

=head3 build_children_objects

Similar to L<build_sub_objects>, but builds objects from within a children hash

=head3 DELETE

Make a delete request to the URL in this link.  Returns Objects.  Failure will
generate an exception.  See L<VMware::vCloudDirector2::API/DELETE>.

=head3 GET

Make a get request to the URL in this link.  Returns Objects.  Failure will
generate an exception.  See L<VMware::vCloudDirector2::API/GET>.

=head3 GET_hash

Make a get request to the URL in this link.  Returns a decoded hash.  Failure
will generate an exception.  See L<VMware::vCloudDirector2::API/GET_hash>.

=head3 POST

Make a post request with the specified payload to the URL in this link. Returns
Objects.  Failure will generate an exception.  See
L<VMware::vCloudDirector2::API/POST>.

=head3 PUT

Make a put request with the specified payload to the URL in this link.  Returns
Objects.  Failure will generate an exception.  See
L<VMware::vCloudDirector2::API/PUT>.

=head3 fetch_admin_object

If this is already an admin object (ie C<is_admin_object> is true), then this
object is returned.

Otherwise, the path is modified to point to the admin API object and the object
is fetched.  Since this only exists for a subset of objects there is a
reasonable chance that just attempting this will lead to an exception  being
thrown due to a non-existant object being requested.

=head1 AUTHOR

Nigel Metheringham <nigelm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Nigel Metheringham.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

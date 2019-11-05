package VMware::vCloudDirector2::Link;

# ABSTRACT: Link within the vCloud

use strict;
use warnings;

our $VERSION = '0.106'; # VERSION
our $AUTHORITY = 'cpan:NIGELM'; # AUTHORITY

use Moose;
use Method::Signatures;
use MooseX::Types::URI qw(Uri);
use Ref::Util qw(is_plain_hashref);
use VMware::vCloudDirector2::Error;

# ------------------------------------------------------------------------

has object => (
    is            => 'ro',
    isa           => 'VMware::vCloudDirector2::Object',
    required      => 1,
    weak_ref      => 1,
    documentation => 'Parent object of link'
);

has mime_type => ( is => 'ro', isa => 'Str', predicate => 'has_mime_type' );
has href => ( is => 'ro', isa => Uri,   required  => 1, coerce => 1 );
has rel  => ( is => 'ro', isa => 'Str', required  => 1 );
has name => ( is => 'ro', isa => 'Str', predicate => 'has_name' );
has type => ( is => 'ro', isa => 'Str' );
has is_json => ( is => 'ro', isa => 'Bool' );

# ------------------------------------------------------------------------
around BUILDARGS => sub {
    my ( $orig, $class, $first, @rest ) = @_;

    my $params = is_plain_hashref($first) ? $first : { $first, @rest };

    if ( $params->{hash} ) {
        my $hash = delete $params->{hash};
        $params->{href} = $hash->{href} if ( exists( $hash->{href} ) and defined( $hash->{href} ) );
        $params->{rel}  = $hash->{rel}  if ( exists( $hash->{rel} )  and defined( $hash->{rel} ) );
        $params->{name} = $hash->{name} if ( exists( $hash->{name} ) and defined( $hash->{name} ) );
        if ( exists( $hash->{type} ) and defined( $hash->{type} ) ) {
            my $type = $hash->{type};
            $params->{mime_type} = $type;
            if ( $type =~ m!^application/vnd\..*\.(\w+)\+(json|xml)$! ) {
                $params->{type}    = $1;
                $params->{is_json} = ( $2 eq 'json' ) ? 1 : 0;
            }
        }
    }

    return $class->$orig($params);
};

# ------------------------------------------------------------------------


method DELETE () { return $self->object->api->DELETE( $self->href ); }


method GET () { return $self->object->api->GET( $self->href ); }
method GET_hash () { return $self->object->api->GET_hash( $self->href ); }


method POST ($hash) { return $self->object->api->POST( $self->href, $hash, $self->mime_type ); }


method PUT ($hash) { return $self->object->api->PUT( $self->href, $hash, $self->mime_type ); }

# ------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

VMware::vCloudDirector2::Link - Link within the vCloud

=head1 VERSION

version 0.106

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

=head1 AUTHOR

Nigel Metheringham <nigelm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Nigel Metheringham.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

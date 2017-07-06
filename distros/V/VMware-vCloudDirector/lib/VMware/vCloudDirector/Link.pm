package VMware::vCloudDirector::Link;

# ABSTRACT: Link within the vCloud

use strict;
use warnings;

our $VERSION = '0.006'; # VERSION
our $AUTHORITY = 'cpan:NIGELM'; # AUTHORITY

use Moose;
use Method::Signatures;
use MooseX::Types::URI qw(Uri);
use Ref::Util qw(is_plain_hashref);
use VMware::vCloudDirector::Error;

# ------------------------------------------------------------------------

has object => (
    is            => 'ro',
    isa           => 'VMware::vCloudDirector::Object',
    required      => 1,
    weak_ref      => 1,
    documentation => 'Parent object of link'
);

has mime_type => ( is => 'ro', isa => 'Str', predicate => 'has_mime_type' );
has href => ( is => 'ro', isa => Uri, required => 1, coerce => 1 );
has rel  => ( is => 'ro', isa => 'Str', required  => 1 );
has name => ( is => 'ro', isa => 'Str', predicate => 'has_name' );
has type => ( is => 'ro', isa => 'Str' );

# ------------------------------------------------------------------------
around BUILDARGS => sub {
    my ( $orig, $class, $first, @rest ) = @_;

    my $params = is_plain_hashref($first) ? $first : { $first, @rest };

    if ( $params->{hash} ) {
        my $hash = delete $params->{hash};
        $params->{href} = $hash->{-href} if ( exists( $hash->{-href} ) );
        $params->{rel}  = $hash->{-rel}  if ( exists( $hash->{-rel} ) );
        $params->{name} = $hash->{-name} if ( exists( $hash->{-name} ) );
        if ( exists( $hash->{-type} ) ) {
            my $type = $hash->{-type};
            $params->{mime_type} = $type;
            $params->{type} = $1 if ( $type =~ m|^application/vnd\..*\.(\w+)\+xml$| );
        }
    }

    return $class->$orig($params);
};

# ------------------------------------------------------------------------


method DELETE () { return $self->object->api->GET( $self->href ); }


method GET () { return $self->object->api->GET( $self->href ); }


method POST ($xml_hash) { return $self->object->api->GET( $self->href, $xml_hash ); }


method PUT ($xml_hash) { return $self->object->api->GET( $self->href, $xml_hash ); }

# ------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

VMware::vCloudDirector::Link - Link within the vCloud

=head1 VERSION

version 0.006

=head3 DELETE

Make a delete request to the URL in this link.  Returns Objects.  Failure will
generate an exception.  See L<VMware::vCloudDirector::API/DELETE>.

=head3 GET

Make a get request to the URL in this link.  Returns Objects.  Failure will
generate an exception.  See L<VMware::vCloudDirector::API/GET>.

=head3 POST

Make a post request with the specified payload to the URL in this link. Returns
Objects.  Failure will generate an exception.  See
L<VMware::vCloudDirector::API/POST>.

=head3 PUT

Make a put request with the specified payload to the URL in this link.  Returns
Objects.  Failure will generate an exception.  See
L<VMware::vCloudDirector::API/PUT>.

=head1 AUTHOR

Nigel Metheringham <nigelm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Nigel Metheringham.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

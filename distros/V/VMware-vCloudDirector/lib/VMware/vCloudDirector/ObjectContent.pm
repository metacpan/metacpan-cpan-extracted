package VMware::vCloudDirector::ObjectContent;

# ABSTRACT: A vCloud Object content

use strict;
use warnings;

our $VERSION = '0.006'; # VERSION
our $AUTHORITY = 'cpan:NIGELM'; # AUTHORITY

use Moose;
use Method::Signatures;
use MooseX::Types::URI qw(Uri);
use Const::Fast;
use Ref::Util qw(is_plain_hashref);
use VMware::vCloudDirector::Link;

# ------------------------------------------------------------------------

has object => (
    is            => 'ro',
    isa           => 'VMware::vCloudDirector::Object',
    required      => 1,
    weak_ref      => 1,
    documentation => 'Parent object'
);

has mime_type => ( is => 'ro', isa => 'Str', required => 1 );
has href => ( is => 'ro', isa => Uri, required => 1, coerce => 1 );
has type => ( is => 'ro', isa => 'Str',     required  => 1 );
has hash => ( is => 'ro', isa => 'HashRef', required  => 1, writer => '_set_hash' );
has name => ( is => 'ro', isa => 'Str',     predicate => 'has_name' );
has id   => ( is => 'ro', isa => 'Str',     predicate => 'has_id' );

# ------------------------------------------------------------------------

has links => (
    is      => 'ro',
    isa     => 'ArrayRef[VMware::vCloudDirector::Link]',
    lazy    => 1,
    builder => '_build_links'
);

method _build_links () {
    my @links;
    if ( exists( $self->hash->{Link} ) ) {
        push( @links, VMware::vCloudDirector::Link->new( hash => $_, object => $self->object ) )
            foreach ( $self->_listify( $self->hash->{Link} ) );
    }
    return \@links;
}

# ------------------------------------------------------------------------
around BUILDARGS => sub {
    my ( $orig, $class, $first, @rest ) = @_;

    my $params = is_plain_hashref($first) ? $first : { $first, @rest };
    if ( $params->{hash} ) {
        my $top_hash = $params->{hash};

        my $hash;
        if ( scalar( keys %{$top_hash} ) == 1 ) {
            my $type = ( keys %{$top_hash} )[0];
            $hash = $top_hash->{$type};
            $params->{type} = $type;
        }
        else {
            $hash = $top_hash;
        }
        const $params->{hash} => $hash;    # force hash read-only to stop people playing

        $params->{href} = $hash->{-href} if ( exists( $hash->{-href} ) );
        $params->{rel}  = $hash->{-rel}  if ( exists( $hash->{-rel} ) );
        $params->{name} = $hash->{-name} if ( exists( $hash->{-name} ) );
        $params->{id}   = $hash->{-id}   if ( exists( $hash->{-id} ) );
        if ( exists( $hash->{-type} ) ) {
            my $type = $hash->{-type};
            $params->{mime_type} = $type;
            $params->{type} = $1 if ( $type =~ m|^application/vnd\..*\.(\w+)\+xml$| );
        }
    }
    return $class->$orig($params);
};

# ------------------------------------------------------------------------
method _listify ($thing) { !defined $thing ? () : ( ( ref $thing eq 'ARRAY' ) ? @{$thing} : $thing ) }

# ------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

VMware::vCloudDirector::ObjectContent - A vCloud Object content

=head1 VERSION

version 0.006

=head1 AUTHOR

Nigel Metheringham <nigelm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Nigel Metheringham.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

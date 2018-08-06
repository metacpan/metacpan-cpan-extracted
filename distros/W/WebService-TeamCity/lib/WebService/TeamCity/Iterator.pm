package WebService::TeamCity::Iterator;

use v5.10;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.04';

use Types::Standard qw( ArrayRef HashRef InstanceOf Int Str );

use Moo;

has client => (
    is       => 'ro',
    isa      => InstanceOf ['WebService::TeamCity'],
    required => 1,
);

has class => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has items_key => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has _next_href => (
    is        => 'rw',
    isa       => Str,
    init_arg  => 'next_href',
    predicate => '_has_next_href',
    clearer   => '_clear_next_href',
);

has _items => (
    is       => 'ro',
    isa      => ArrayRef [HashRef],
    init_arg => 'items',
    required => 1,
);

has _i => (
    is      => 'rw',
    isa     => Int,
    default => 0,
);

## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub next {
    my $self = shift;

    my $items = $self->_items;
    my $i     = $self->_i;

    if ( $i >= @{$items} ) {
        $self->_fetch_more
            or return undef;
    }
    my $obj = $self->class->new(
        client => $self->client,
        %{ $items->[$i] },
    );
    $self->_i( $i + 1 );

    return $obj;
}
## use critic

sub _fetch_more {
    my $self = shift;

    return 0 unless $self->_has_next_href;

    my $raw = $self->client->decoded_json_for(
        uri => $self->client->base_uri . $self->_next_href );

    push @{ $self->_items }, @{ $raw->{ $self->items_key } };

    if ( $raw->{next_href} ) {
        $self->_next_href( $raw->{next_href} );
    }
    else {
        $self->_clear_next_href;
    }

    return 1;
}

1;

# ABSTRACT: Generic object iterator for paged results from the TeamCity REST API

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::TeamCity::Iterator - Generic object iterator for paged results from the TeamCity REST API

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    my $builds = $client->builds;
    while ( my $build = $builds->next ) { ... }

=for Pod::Coverage class client items_key

=head1 API

This class offers one public method:

=head2 $iterator->next

This returns the next object from the result set. If necessary, it will fetch
the next page of results from the server. It returns C<undef> when there are
no more objects to fetch.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/WebService-TeamCity/issues>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package WWW::Metalgate::Artist;

use warnings;
use strict;

use Moose;
use MooseX::Types::URI qw(Uri FileUri DataUri);
use Web::Scraper;
use WWW::Metalgate::ReviewIndex;
use WWW::Metalgate::Review;
use List::Util qw(first);

=head1 NAME

WWW::Metalgate::Artist

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 FUNCTIONS

=head2 uri

=head2 year

=head2 html

=cut

has 'uri'  => (is => 'rw', isa => Uri, coerce  => 1);
has 'name' => (is => 'rw', isa => 'Str', required => 1);

with 'WWW::Metalgate::Role::Html';

=head2 BUILD

=cut

sub BUILD {
    my $self = shift;

    unless ($self->uri) {
        my @artists = WWW::Metalgate::ReviewIndex->new->artists;
        my $artist  = first { lc($_->name) eq lc($self->name) } @artists;
        die sprintf("Artist %s is not found.", $self->name) unless $artist;
        $self->name( $artist->name );
        $self->uri( $artist->uri );
    }
}

=head2 review

=cut

sub review {
    my $self = shift;
    WWW::Metalgate::Review->new( artist => $self );
}

=head1 AUTHOR

Tomohiro Hosaka, C<< <bokutin at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Tomohiro Hosaka, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

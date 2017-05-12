package WWW::Metalgate::ReviewIndex;

use warnings;
use strict;

use Moose;
use MooseX::Types::URI qw(Uri FileUri DataUri);
use Web::Scraper;
use WWW::Metalgate::Artist;

=head1 NAME

WWW::Metalgate::ReviewIndex

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 FUNCTIONS

=head2 uri

=head2 html

=cut

has 'uri'  => (is => 'rw', isa => Uri, coerce  => 1, default => "http://www.metalgate.jp/reviewindex.htm");

with 'WWW::Metalgate::Role::Html';

=head2 artists

=cut

sub artists {
    my $self = shift;

    #<a href="R_accept.htm">ACCEPT</a>
    my $artist_link = sub {
        my $node = shift;
        return () unless $node->attr('href') =~ m/^R_/;
        return {
            name => $node->string_value,
            href => URI->new_abs( $node->attr('href'), $self->uri ),
        };
    };
    my $artists = scraper {
        process 'td>a',
            'links[]' => $artist_link;
    };

    my $data = $artists->scrape( $self->html );

    my @artists;
    for (@{$data->{links}}) {
        my $artist = WWW::Metalgate::Artist->new( name => $_->{name}, uri => $_->{href} );
        push @artists, $artist;
    }

    return @artists;
}

=head1 AUTHOR

Tomohiro Hosaka, C<< <bokutin at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Tomohiro Hosaka, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

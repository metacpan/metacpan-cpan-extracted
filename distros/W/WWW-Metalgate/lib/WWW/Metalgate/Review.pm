package WWW::Metalgate::Review;

use warnings;
use strict;

use Moose;
use Moose::Util::TypeConstraints;
use Web::Scraper;
use WWW::Metalgate::Artist;
use Text::Trim;

=head1 NAME

WWW::Metalgate::Review

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

subtype 'Artist'
    => as 'Object'
      => where { $_->isa('WWW::Metalgate::Artist') };

coerce 'Artist'
    => from 'Str'
        => via { WWW::Metalgate::Artist->new( name => $_ ) };

=head1 FUNCTIONS

=head2 artist

=cut

has 'artist' => (is => 'rw', isa => 'Artist', coerce => 1, required => 1);

=head2 albums

=cut

sub albums {
    my $self = shift;

    my $album = sub {
        my $node = shift;
        return () unless $node->content_list == 4;

        my @children = $node->content_list;
        return {
            artist     => trim($children[0]->as_text),
            album      => trim($children[1]->address(".0")->as_text),
            point      => trim($children[1]->address(".1")->as_text),
            album_kana => trim($children[2]->as_text),
        };
    };
    my $albums = scraper {
        process 'table',
            'albums[]', $album;
    };
    my $data_albums = $albums->scrape( $self->artist->html );

    my $body = sub {
        my $node = shift;
        if ($node->find_by_attribute(class => 'line20')) {
            return $node->as_text;
        }
        eles {
            return ();
        }
    };
    my $bodies = scraper {
        process 'table',
            'bodies[]', $body;
    };
    my $data_bodies = $bodies->scrape( $self->artist->html );

    my @albums;
    for (0 .. $#{ $data_albums->{albums} }) {
        push @albums, {
            %{$data_albums->{albums}[$_]},
            body => $data_bodies->{bodies}[$_],
        };
    }

    return @albums;
}

=head1 AUTHOR

Tomohiro Hosaka, C<< <bokutin at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Tomohiro Hosaka, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

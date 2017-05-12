package WWW::BBC::TrackListings;

use Moose;
use namespace::autoclean;

use Web::Scraper;
use URI;
use FindBin::libs;

use WWW::BBC::Track;

# ABSTRACT: Get track listings for BBC radio programmes
our $VERSION = '0.01'; # VERSION

has 'url' => (
    is => 'ro',
    isa => 'Str',
);

has 'tracks' => (
    is => 'rw',
    isa => 'ArrayRef[WWW::BBC::Track]',
    traits => ['Array'],
    handles => {
        all_tracks => 'elements',
    },
    builder => '_build_tracks',
    lazy => 1,
);

sub _build_tracks {
    my ( $self ) = @_;

    my $tracks = scraper {
        process "li.track", "tracks[]" => scraper {
            process ".artist", artist => 'TEXT';
            process ".title", title => 'TEXT';
        };
    };

    my $res = $tracks->scrape( URI->new( $self->url ) );

    my @tracks;
    for my $track ( @{ $res->{tracks} } ) {
        push @tracks, WWW::BBC::Track->new({
            artist => $track->{artist},
            title => $track->{title},
        });
    }

    return \@tracks;
}

__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

WWW::BBC::TrackListings - Get track listings for BBC radio programmes

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  my $listings = WWW::BBC::TrackListings->new({ url => 'http://www.bbc.co.uk/programmes/b03c8l9l' });

  for my $track ( $listings->all_tracks ) {
    say $track->artist;
    say $track->title;
  }

=head1 DESCRITPION

Scrape of BBC radio programme pages to generate track listings.

=head1 METHODS

=head2 all_tracks

Returns all L<WWW::BBC::Track> listings of this programme.

=head1 ATTRIBUTES

=head2 url

=head1 AUTHOR

Adam Taylor <ajct@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Adam Taylor.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


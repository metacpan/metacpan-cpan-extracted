package WebService::Audioscrobbler::SimilarArtist;
use warnings;
use strict;
use CLASS;

use base 'WebService::Audioscrobbler::Artist';

=head1 NAME

WebService::Audioscrobbler::SimilarArtist - An object-oriented interface to the Audioscrobbler WebService API

=cut

our $VERSION = '0.08';

# object accessors
CLASS->mk_accessors(qw/match related_to/);

=head1 SYNOPSIS

This is a subclass of L<WebService::Audioscrobbler::Artist> which implements some
aditional fields that cover similarity aspects between two artists.

    use WebService::Audioscrobbler;

    my $artist = WebService::Audiocrobbler->artist('Foo');

    for my $similar ($artist->similar_artists) {
        print $similar->name . ": " . $similar->match . "\% similar\n";
    }

=head1 FIELDS

=head2 C<related_to>

The related artist from which this C<SimilarArtist> object has been constructed from.

=head2 C<match>

The similarity index between this artist and the related artist. It's returned 
as a number between 0 (not similar) and 100 (very similar).

=cut

=head1 AUTHOR

Nilson Santos Figueiredo Junior, C<< <nilsonsfj at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 Nilson Santos Figueiredo Junior, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of WebService::Audioscrobbler::SimilarArtist

use strict;
use warnings;

package WebService::IMDBAPI::Result;
{
  $WebService::IMDBAPI::Result::VERSION = '1.130150';
}

# ABSTRACT: Represents a result

# Assessors
# alphabetically, case insensitive
use Object::Tiny qw(
  actors
  also_known_as
  country
  directors
  episodes
  film_locations
  genres
  imdb_id
  imdb_url
  language
  plot
  plot_simple
  poster
  rated
  rating
  rating_count
  release_date
  runtime
  title
  type
  writers
  year
);

1;



=pod

=head1 NAME

WebService::IMDBAPI::Result - Represents a result

=head1 VERSION

version 1.130150

=head1 DESCRIPTION

See L<http://imdbapi.org/#fields> for details of the attributes contained in this object.

Note that the presence and contents of some of these attributes can differ depending on the options passed to the search.

=head1 ATTRIBUTES

=head2 actors

=head2 also_known_as

=head2 country

=head2 directors

=head2 episodes

=head2 film_locations

=head2 genres

=head2 imdb_id

=head2 imdb_url

=head2 language

=head2 plot

=head2 plot_simple

=head2 poster

=head2 rated

=head2 rating

=head2 rating_count

=head2 release_date

=head2 runtime

=head2 title

=head2 type

=head2 writers

=head2 year

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


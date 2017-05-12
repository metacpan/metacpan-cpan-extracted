package WWW::Search::Coveralia::Result::Artist;

use 5.014000;
use strict;
use warnings;
use parent qw/WWW::SearchResult/;

our $VERSION = '0.001';

use HTML::TreeBuilder;
use List::MoreUtils qw/pairwise/;
use WWW::Search;
use WWW::Search::Coveralia::Result::Album;

sub new{
	my ($class, $obj, $id, $name) = @_;
	my $self = $class->SUPER::new;
	$self->{id} = $id;
	$self->{obj} = $obj;

	$self->title($name);
	$self->add_url("http//www.coveralia.com/autores/$id.php");
	$self
}

sub albums{
	my ($self) = @_;
	unless ($self->{albums}) {
		my $id = $self->{id};
		my $tree = HTML::TreeBuilder->new_from_url("http://www.coveralia.com/caratulas-de/$id.php");
		my @albums = $tree->look_down(class => 'artista');
		my @cover_lists = $tree->look_down(class => qr/\blista_normal\b/);

		$self->{albums} = [pairwise {
			my ($album, $cover_list) = ($a, $b);
			my ($year) = $album->find('span') && ($album->find('span')->as_text =~ /^\((\d+)/);
			$year = $year || undef;
			$album = $album->find('a');
			my $title = $album->as_text;
			my $url = $self->{obj}->absurl('', $album->attr('href'));
			my %covers = map {lc $_->as_text => $self->{obj}->absurl('', $_->attr('href'))} $cover_list->find('a');
			WWW::Search::Coveralia::Result::Album->new($self->{obj}, $url, $title, $self->title, $year, \%covers);
		} @albums, @cover_lists];
	}

	@{$self->{albums}}
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::Search::Coveralia::Result::Artist - an artist found by WWW::Search::Coveralia::Artists

=head1 SYNOPSIS

  my $result = $search->next_result;
  say 'URL: ', $result->url;
  say 'Name: ', $result->name;
  my @albums = $result->albums;
  # @albums is an array of WWW::Search::Coveralia::Result::Album objects

=head1 DESCRIPTION

WWW::Search::Coveralia::Result::Artist is the result of a WWW::Search::Coveralia::Artists search.

Useful methods:

=over

=item B<url>

Returns a link to the artist page on coveralia.

=item B<title>

Returns the name of the artist.

=item B<albums>

Returns a list of albums (L<WWW::Search::Coveralia::Result::Album> objects) belonging to this artist. Calls B<parse_page> if not called already.

=item B<parse_page>

Downloads the covers page and extracts the albums. It is called automatically by B<albums> when necessary.

=back

=head1 SEE ALSO

L<WWW::Search::Coveralia::Artists>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

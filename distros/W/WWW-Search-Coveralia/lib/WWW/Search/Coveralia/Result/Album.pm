package WWW::Search::Coveralia::Result::Album;

use 5.014000;
use strict;
use warnings;
use parent qw/WWW::SearchResult/;

our $VERSION = '0.001';

use HTML::TreeBuilder;
use PerlX::Maybe;

sub artist { shift->_elem(artist => @_) }
sub year   { shift->_elem(year   => @_) }

sub new{
	my ($class, $obj, $url, $title, $artist, $year, $covers) = @_;
	my $self = $class->SUPER::new;
	$self->{obj} = $obj;
	$self->{covers} = $covers if $covers;

	$self->title($title);
	$self->artist($artist);
	$self->year($year);
	$self->add_url($url);
	$self
}

sub parse_page{
	my ($self) = @_;
	my $tree = HTML::TreeBuilder->new_from_url($self->url);
	my $cover_list = $tree->look_down(class => 'lista_normal');
	my @covers = grep { ($_->find('img')->attr('class') // '') ne 'sprites_enviax' } $cover_list->find('a');
	$self->{covers} = {map {lc $_->as_text => $self->{obj}->absurl('', $_->attr('href'))} @covers};
	my @songs = $tree->look_down(id => 'pagina_disco_lista')->find('tr');
	$self->{songs} = [map {
		my ($nr, $title, @extra) = $_->find('td');
		my %ret = (id => $nr->as_text, name => $title->as_text);
		for (@extra) {
			next if ($_->attr('class') // '') eq 'letrano';
			$ret{lyrics} = $self->{obj}->absurl('', $_->find('a')->attr('href')) if $_->as_text =~ /letra/i;
			$ret{video} = $self->{obj}->absurl('', $_->find('a')->attr('href')) if $_->as_text =~ /video/i;
			$ret{tab} = $self->{obj}->absurl('', $_->find('a')->attr('href')) if $_->as_text =~ /acorde/i;
		}
		\%ret
	} @songs]
}

sub covers{
	my ($self) = @_;
	$self->parse_page unless $self->{covers};
	%{$self->{covers}}
}

sub cover{
	my ($self, $cover) = @_;
	$self->parse_page unless $self->{covers};
	$self->{covers}{$cover}
}

sub songs{
	my ($self) = @_;
	$self->parse_page unless $self->{songs};
	@{$self->{songs}}
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::Search::Coveralia::Result::Album - an album found by WWW::Search::Coveralia::Albums

=head1 SYNOPSIS

  my $result = $search->next_result;
  say 'URL: ', $result->url;
  say 'Name: ', $result->name;
  my @albums = $result->albums;
  # @albums is an array of WWW::Search::Coveralia::Result::Album objects

=head1 DESCRIPTION

WWW::Search::Coveralia::Result::Album is the result of a WWW::Search::Coveralia::Albums search.

Useful methods:

=over

=item B<url>

Returns a link to the album page on coveralia.

=item B<title>

Returns the name of the album.

=item B<artist>

Returns the name of the artist of this album.

=item B<year>

Returns the year when this album was released, or undef if the year is not known.

=item B<covers>

Returns a hash of cover art, with the kind of cover art as key and the link to the cover art page as value. This will change for the first stable version.

Typical keys:

=over

=item frontal

Front cover

=item trasera

Back cover

=item cd/cd1/cd2/dvd/dvd1/dvd2/...

CD/DVD art

=item interior1 / interior frontal

Interior frontal cover.

=item interior2 / interior trasera

Interior back cover.

=back

=item B<cover>($type)

Convenience method. Returns a link to the cover art of a particular type. This will change for the first stable version.

=item B<songs>

Returns a list of songs in this album. Each song is a hashref with the following keys:

=over

=item id

The track number of this song.

=item name

The name of this song.

=item lyrics

Optional. A link to the lyrics of this song. Will likely change for the first stable version.

=item video

Optional. A link to the music video of this song. Will likely change for the first stable version.

=item tab

Optional. A link to the tab of this song. Will likely change for the first stable version.

=back

=item B<parse_page>

Downloads the covers page and extracts the albums. It is called automatically by other methods when necessary.

=back

=head1 SEE ALSO

L<WWW::Search::Coveralia::Albums>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

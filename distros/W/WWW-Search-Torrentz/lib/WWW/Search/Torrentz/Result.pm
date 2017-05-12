package WWW::Search::Torrentz::Result;

use 5.014000;
use strict;
use warnings;
use parent qw/WWW::SearchResult/;

our $VERSION = '0.002';

use HTML::TreeBuilder;
use URI::Escape qw/uri_escape/;

sub new{
	my ($class, %args) = @_;
	my $self = $class->SUPER::new(@_);
	$self->{parsed} = 0;

	$self->_elem($_ => $args{$_}) for qw/title verified age size seeders leechers infohash/;
	$self->{ua} = $args{ua};
	$self->add_url("https://torrentz.eu/$args{infohash}");
	$self
}

sub infohash { shift->_elem(infohash => @_) }
sub verified { shift->_elem(verified => @_) }
sub age { shift->_elem(age => @_) }
sub size { shift->_elem(size => @_) }
sub seeders { shift->_elem(seeders => @_) }
sub leechers { shift->_elem(leechers => @_) }

sub magnet{
	my ($self, $full) = @_;
	my $infohash = $self->infohash;
	my $title = uri_escape $self->title;
	my $uri = "magnet:?xt=urn:btih:$infohash&dn=$title";

	$uri .= join '', map { "&tr=$_"} map { uri_escape $_ } $self->trackers if $full;

	$uri
}

sub parse_page {
	my $self = $_[0];
	my $tree = HTML::TreeBuilder->new;
	$tree->utf8_mode(1);
	$tree->parse($self->{ua}->get($self->url)->content);
	$tree->eof;

	my $trackers = $tree->look_down(class => 'trackers');
	$self->{trackers} //= [];
	for my $tracker ($trackers->find('dl')) {
		push @{$self->{trackers}}, $tracker->find('a')->as_text;
	}

	my $files = $tree->look_down(class => 'files');
	$self->{files} //= [];
	$self->parse_directory(scalar $files->find('li'), '');

	$self->{parsed} = 1;
}

sub parse_directory{
	my ($self, $directory, $prefix) = @_;
	$prefix .= $directory->as_text . '/';
	my $contents_ul = $directory->right->find('ul');
	return unless defined $contents_ul; # Empty directory
	my @children = $contents_ul->content_list;
	my $skip = 0;
	for my $child (@children) {
		if ($skip) {
			$skip = 0;
			next;
		}

		if (defined $child->attr('class') && $child->attr('class') eq 't') {
			$self->parse_directory($child, $prefix);
			$skip = 1;
		} else {
			$child->objectify_text;
			my ($filename, $size) = $child->find('~text');
			push @{$self->{files}}, +{
				path => $prefix.$filename->attr('text'),
				size => $size->attr('text')
			}
		}
	}
}

sub trackers{
	my $self = $_[0];
	$self->parse_page unless $self->{parsed};
	@{$self->{trackers}}
}

sub files{
	my $self = $_[0];
	$self->parse_page unless $self->{parsed};
	@{$self->{files}}
}

sub torrent{
	my $self = $_[0];
	my $torrage = 'http://torrage.com/torrent/' . uc $self->infohash . '.torrent';
	my $torrent = $self->{ua}->get($torrage)->content;

	$torrent; # TODO: if this is undef, download metadata with magnet link
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::Search::Torrentz::Result - [DEPRECATED] a result of a WWW::Search::Torrentz search

=head1 SYNOPSIS

  my $result = $search->next_result;
  say 'URL: ' . $result->url;
  say 'Title: ' . $result->title;
  say 'Infohash: ' . $result->infohash;
  say 'Verified: ' . $result->verified;
  say 'Age: ' . $result->age;
  say 'Size: ' . $result->size;
  say 'Seeders: ' . $result->seeders;
  say 'Leechers: ' . $result->leechers;
  say 'Magnet link: ' . $result->magnet;
  say 'Magnet link with trackers: ' . $result->magnet(1);
  my @tracker_list = $result->trackers;
  my @file_list = $result->files;
  my $torrent_file = $result->torrent;

=head1 DESCRIPTION

WWW::Search::Torrentz::Result is the result of a WWW::Search::Torrentz search.

Useful methods:

=over

=item B<url>

Returns a link to the torrent details page.

=item B<title>

Returns the torrent's title.

=item B<infohash>

Returns the infohash of the torrent, a 40 character hex string.

=item B<verified>

Returns the verification level of this torrent, or 0 if the torrent not verified. Higher is better.

=item B<age>

Returns the torrent's age, as returned by Torrentz. Usually a string such as '4 days', 'yesterday', 'today', '2 months'.

=item B<size>

Returns the torrent's size, as returned by Torrentz. A string such as '151 MB', '25 GB'.

=item B<seeders>

Returns the number of seeders this torrent has, as returned by Torrentz.

=item B<leechers>

Returns the number of leechers this torrent has, as returned by Torrentz.

=item B<magnet>([I<include_trackers>])

Returns a magnet link that describes this torrent.

If I<include_trackers> is true, the magnet link will include the tracker list. This calls B<parse_page> if not called already.

=item B<trackers>

Returns a list of trackers for this torrent. Calls B<parse_page> if not called already.

=item B<files>

Returns a list of files this torrent includes. Calls B<parse_page> if not called already.

Each element is a hashref with two keys. C<path> is the file path and C<size> is the file size, as returned by Torrentz.

=item B<parse_page>

Downloads the details page for this torrent and extracts the tracker and file list. It is called automatically by other methods when necessary, you shouldn't have to call it yourself.

=item B<torrent>

Downloads this torrent file from Torrage. If found, it returns the contents of the torrent file. Otherwise it returns undef.

=back

=head1 SEE ALSO

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

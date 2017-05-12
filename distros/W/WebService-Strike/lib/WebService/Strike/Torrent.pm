package WebService::Strike::Torrent;

use 5.014000;
use strict;
use warnings;
use parent qw/Class::Accessor::Fast/;

our $VERSION = 0.006;

use JSON::MaybeXS qw/decode_json/;
use MIME::Base64;
use URI::Escape;
use WebService::Strike;

__PACKAGE__->mk_ro_accessors(qw/torrent_hash torrent_title torrent_category sub_category seeds leeches file_count size upload_date uploader_username file_info file_names file_lengths imdb_id/);

BEGIN {
	*hash     = *torrent_hash;
	*title    = *torrent_title;
	*category = *torrent_category;
	*count    = *file_count;
	*date     = *upload_date;
	*uploader = *uploader_username;
	*names    = *file_names;
	*lengths  = *file_lengths;
};

sub magnet{
	my ($self) = @_;
	my $hash = uri_escape $self->hash; # uri_escape is not exactly needed here
	my $title = uri_escape $self->title;
	"magnet:?xt=urn:btih:$hash&dn=$title"
}

sub new{
	my ($self, @args) = @_;
	$self = $self->SUPER::new(@args);
	$self->{torrent_hash} = uc $self->hash;
	if ($self->file_info) {
		$self->{file_names} = $self->file_info->{file_names};
		$self->{file_lengths} = $self->file_info->{file_lengths};
	}
	$self->{imdb_id} = $self->{imdbid} if $self->{imdbid};
	$self
}

sub torrent{
	die "This API call was removed in Strike API V2.1\n"
}

sub description{
	my ($self) = @_;
	return $self->{description} if $self->{description};
	my $url = $WebService::Strike::BASE_URL . '/torrents/descriptions/?hash=' . $self->hash;
	my $ht = WebService::Strike::_ht(); ## no critic (ProtectPrivate)
	my $response = $ht->get($url);
	return unless $response->{success};
	$self->{description} = decode_base64 $response->{content}
}

sub imdb {
	my ($self) = @_;
	return if !$self->imdb_id || $self->imdb_id eq 'none';
	$self->{imdb} //= WebService::Strike::strike_imdb ($self->imdb_id)
}

1;
__END__

=encoding utf-8

=head1 NAME

WebService::Strike::Torrent - [OBSOLETE] Class representing information about a torrent

=head1 SYNOPSIS

  use WebService::Strike;
  my $t = strike 'B425907E5755031BDA4A8D1B6DCCACA97DA14C04';
  say $t->hash;             # B425907E5755031BDA4A8D1B6DCCACA97DA14C04
  say $t->title;            # Arch Linux 2015.01.01 (x86/x64)
  say $t->category;         # Applications
  say $t->sub_category;     # '' (empty string)
  say $t->seeds;
  say $t->leeches;
  say $t->count;            # 1
  say $t->size;             # 615514112
  say $t->date;             # 1420502400
  say $t->uploader;         # The_Doctor-
  say @{$t->names};         # archlinux-2015.01.01-dual.iso
  say @{$t->lengths};       # 615514112
  say $t->magnet;           # magnet:?xt=urn:btih:B425907E5755031BDA4A8D1B6DCCACA97DA14C04&dn=Arch%20Linux%202015.01.01%20%28x86%2Fx64%29
  say $t->description;      # <HTML fragment describing Arch Linux>

  $t = strike 'ED70C185E3E3246F30B2FDB08D504EABED5EEA3F';
  say $t->title;                          # The Walking Dead S04E15 HDTV x264-2HD
  say $t->imdb_id;                        # tt1520211
  my $i = $t->imdb;
  say $i->{title}, ' (', $i->{year}, ')'; # The Walking Dead (2010)
  say $i->{genre};                        # Drama, Horror, Thriller

=head1 DESCRIPTION

B<The API was discontinued. The code in this module remains, but it
does not achieve any useful purpose.>

WebService::Strike::Torrent is a class that represents information
about a torrent.

Methods:

=over

=item B<hash>, B<torrent_hash>

The info_hash of the torrent.

=item B<title>, B<torrent_title>

The title of the torrent.

=item B<category>, B<torrent_category>

The category of the torrent.

=item B<sub_category>

The subcategory of the torrent.

=item B<seeds>

The number of seeders.

=item B<leeches>

The number of leechers.

=item B<count>, B<file_count>

The number of files contained in the torrent.

=item B<size>

The total size of the files in the torrent in bytes.

=item B<date>, B<upload_date>

Unix timestamp when the torrent was uploaded, with precision of one day.

=item B<uploader>, B<uploader_username>

Username of the user who uploaded the torrent.

=item B<file_names>

Arrayref of paths of files in the torrent.

=item B<file_lengths>

Arrayref of lengths of files in the torrent, in bytes.

=item B<magnet>, B<magnet_uri>

Magnet link for the torrent.

=item B<torrent>([I<$filename>])

B<THIS METHOD WAS REMOVED IN STRIKE API V2.1>. Therefore, it simply
dies. Below is the previous documentation of the method.

Downloads the torrent from Strike. With no arguments, returns the
contents of the torrent file. With an argument, stores the torrent in
I<$filename>.

Both forms return a true value for success and false for failure.

=item B<description>

The description of the torrent. This method sends an extra request to
Strike. Successful responses are cached.

=item B<imdb_id>

The IMDB ID of the torrent, or undef if the torrent has no associated
IMDB ID.

=item B<imdb>

Calls B<strike_imdb> from L<WebService::Strike> on B<imdb_id>. Caches
the response. Returns undef if the torrent has no associated IMDB ID.

=back

=head1 SEE ALSO

L<WebService::Strike>, L<https://getstrike.net/api/>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015-2016 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.2 or,
at your option, any later version of Perl 5 you may have available.


=cut

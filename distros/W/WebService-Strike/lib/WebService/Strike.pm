package WebService::Strike;

use 5.014000;
use strict;
use warnings;
use parent qw/Exporter/;

our @EXPORT    = qw/strike strike_search strike_imdb/;
our @EXPORT_OK = (@EXPORT, 'strike_query');
our $VERSION = '0.006';
our $BASE_URL = 'https://getstrike.net/api/v2';

use JSON::MaybeXS qw/decode_json/;
use HTTP::Tiny;
use Sort::ByExample qw/sbe/;
use WebService::Strike::Torrent;

sub _ht { HTTP::Tiny->new(agent => "WebService-Strike/$VERSION", verify_SSL => 1) }

sub _query {
	my ($url) = @_;

	my $ht = _ht;
	my $response = $ht->get($url);
	die $response unless $response->{success}; ## no critic (RequireCarping)
	$response = decode_json $response->{content};

	map { WebService::Strike::Torrent->new($_) } @{$response->{torrents}};
}

sub strike_query {
	my (@hashes) = @_;
	if (@hashes > 50) {
		return strike_query (@hashes[0 .. 49]), strike_query (@hashes[50 .. $#hashes]);
	}
	my $url = "$BASE_URL/torrents/info/?hashes=" . join ',', map { uc } @hashes;

	my $sorter = sbe(\@hashes, {xform => sub { $_[0]->hash }});
	my @torrents = $sorter->(_query $url);
	wantarray ? @torrents : $torrents[0]
}

sub strike_search {
	my ($query, $full, %args) = @_;
	$args{phrase} = $query;
	my $url = "$BASE_URL/torrents/search/?" . HTTP::Tiny->www_form_urlencode(\%args);

	my @torrents = _query $url;
	@torrents = $torrents[0] unless wantarray;
	@torrents = strike_query map { $_->hash } @torrents if $full;
	wantarray ? @torrents : $torrents[0]
}

sub strike_imdb {
	my ($id) = @_;
	my $url = "$BASE_URL/media/imdb/?imdbid=$id";
	my $response = _ht->get($url);
	return unless $response->{success};
	my %imdb = %{decode_json $response->{content}};
	$imdb{lc $_} = delete $imdb{$_} for keys %imdb; ## no critic (ProhibitUselessTopic)
	\%imdb
}

BEGIN { *strike = \&strike_query }

1;
__END__

=encoding utf-8

=head1 NAME

WebService::Strike - [OBSOLETE] Get torrent info from the now-discontinued getstrike.net API

=head1 SYNOPSIS

  use WebService::Strike;
  my $t = strike 'B425907E5755031BDA4A8D1B6DCCACA97DA14C04';
  say $t->title;               # Arch Linux 2015.01.01 (x86\/x64)
  say $t->magnet;              # Returns a magnet link
  my $torrent = $t->torrent;   # Returns the torrent file
  $t->torrent('file.torrent'); # Downloads the torrent file to 'file.torrent'

  my @debian = strike_search 'Debian';
  say 'Found ' . @debian . ' torrents matching "Debian"';
  say 'First torrent has info hash ' . $debian[0]->hash;

  my $mp = strike_search 'Modern perl', 1, category => 'Books';
  say 'Torrent has ' . $mp->count . ' files. They are:';
  say join ' ', @{$mp->file_names};

  my $info = strike_imdb 'tt1520211';
  say 'IMDB ID ', $info->{imdbid}, ' is ', $info->{title}, ' (', $info->{year}, ')';
  say 'Plot (short): ', $info->{shortplot};

=head1 DESCRIPTION

B<The API was discontinued. The code in this module remains, but it
does not achieve any useful purpose.>

Strike API is a service for getting information about a torrent given
its info hash. WebService::Strike is a wrapper for this service.

=over

=item B<strike>(I<@info_hashes>)

Returns a list of L<WebService::Strike::Torrent> objects in list
context or the first such object in scalar context. Dies in case of
error.

=item B<strike_query>

Alias for B<strike>. Not exported by default.

=item B<strike_search>(I<$phrase>, [I<$full>, [ key => value ... ]])

Searches for torrents given a phrase. Returns a list of
L<WebService::Strike::Torrent> objects in list context or the first
such object in scalar context.

If I<$full> is false (default), the returned objects will be
incomplete: their B<file_names> and B<file_lengths> accessors will
return undef.

If I<$full> is true, B<strike> will be called with the info hashes of
the found torrents, thus obtaining complete objects.

You can filter the search by appending key => value pairs to the call.
For example:

  strike_search 'windows', 0, category => 'Applications', sub_category => 'Windows';

=item B<strike_imdb>(I<$imdb_id>)

Get informaton about a movie from IMDB. Takes an IMDB ID and returns a
hashref of unspecified format. All keys are lowercased.

=back

=head1 SEE ALSO

L<WebService::Strike::Torrent>, L<https://getstrike.net/api/>, L<WWW::Search::Torrentz>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015-2016 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.2 or,
at your option, any later version of Perl 5 you may have available.


=cut

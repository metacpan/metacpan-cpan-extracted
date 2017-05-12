package XML::FeedPP::Plugin::AddMP3;

=head1 NAME

XML::FeedPP::Plugin::AddMP3 - FeedPP Plugin for adding MP3 as item.

=head1 SYNOPSIS

    use XML::FeedPP;
    my $feed = XML::FeedPP->new( 'index.rss' );
    $feed->call(AddMP3 => './mp3/test.mp3');
    $feed->to_file('rss.xml');

=head1 DESCRIPTION

This plugin generate new feed item for specified MP3 file.

    $feed->call(AddMP3 => './mp3/test.mp3');

And set default value for the item's title, author, enclosure url, 
enclosure length, enclosure type with MP3 TAGs and INFOs.

If use_itune option is specified, xmlns:itunes is added to feed.
And additional default value for itunes:author, itunes:subtitle, 
itunes:duration, itunes:keywords are set.

Returns added item, or undef.

B<NOTE:> If those values includes non-UTF-8 characters, it tries to
convert with Encode, or Jcode module. When both of them are avaliable,
It calls Carp::carp, and continues process.

=head1 OPTIONS

This plugin allows some optoinal arguments following:

=over 4

=item base_dir

By default, url attribute of enclosure tag is set to file argument.
If base_dir is specified, url attribute is converted to relative path from base_dir.

=item base_url

If base_url is specified, url attribute is converted as relative path from base_url.

=item link_url

By default, link value is set to the feed's link value.
If link_url is specified, link value is set to link_url.

=item use_itunes

Use itunes name space, and add tags in the name space.
See also http://www.apple.com/itunes/store/podcaststechspecs.html

=back

For example,

    my %opt = (
        base_dir   => './mp3'
        base_url   => 'http://example.com/podcast/files',
        link_url   => 'http://example.com/podcast',
        use_itunes => 1,
    );
    $feed->call(AddMP3 => './mp3/test.mp3');

At first, URL is set to './mp3/test.mp3'.
Then, base_dir is specified in this case, URL is chenged to 'test.mp3'.
Alos base_url is specified in this case, so URL is chenged to 'http://example.com/podcast/files/test.mp3'.

=head1 MODULE DEPENDENCIES

L<XML::FeedPP>, L<Path::Class>, L<MP3::Info>

=head1 MODULE RECOMMENDED

L<Encode>, or L<Jcode> (for Japanese users)

=head1 SEE ALSO

L<XML::FeedPP>

http://www.apple.com/itunes/store/podcaststechspecs.html (Podcast specification)

=head1 AUTHOR

Makio Tsukamoto <tsukamoto@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Makio Tsukamoto. All rights reserved.
This program is free software; you can redistribute it 
and/or modify it under the same terms as Perl itself.

=cut

use strict;
use vars qw( @ISA );
@ISA = qw( XML::FeedPP::Plugin );

use vars qw( $VERSION );
$VERSION = "0.02";

use Carp;
use MP3::Info;
use Path::Class;

my $re_utf8 = qr/(?:[\x00-\x7f]|[\xC0-\xDF][\x80-\xBF]|[\xE0-\xEF][\x80-\xBF]{2}|[\xF0-\xF7][\x80-\xBF]{3})/;
my $use_encode = undef;
my $use_jcode = undef;

sub run {
	my $class = shift;
	my $feed = shift;
	&add_mp3( $feed, @_ );
}

sub add_mp3 {
	my $feed = shift;
	my $file = shift;
	my %opt  = @_;
	# check link
	my $link = ($opt{'link_url'}) ? $opt{'link_url'} : $feed->link;
	return unless (defined($link) and length($link));
	# check file and get its information
	my $path = Path::Class::file($file);
	Carp::croak "File not exists - $file" if (not -f $path);
	my $stat = File::stat::stat("$path")       or Carp::croak "Failed to get file stat - $file";
	my $tags = MP3::Info::get_mp3tag("$path")  or Carp::croak "Failed to get mp3 tags - $file";
	my $info = MP3::Info::get_mp3info("$path") or Carp::croak "Failed to get mp3 info - $file";
	# define url
	my $url = Path::Class::file($file);
	$url = $url->relative($opt{'base_dir'}) if ($opt{'base_dir'});
	$url = $url->as_foreign('Unix')->stringify;
	if ($opt{'base_url'}) {
		my $base_url = $opt{'base_url'};
		$base_url =~ s/\/$//;
		$url =~ s/^\///;
		$url = "$base_url/$url";
	}
	# add item
	my $item = $feed->add_item($link);
	$item->guid($url);
	$item->pubDate($stat->mtime);
	my $podcast = {
		'title'             => $tags->{'TITLE'},
		'author'            => $tags->{'ARTIST'},
		'description'       => '',                # CDATA is allowed
		'enclosure@url'     => $url,
		'enclosure@length'  => $stat->size,
		'enclosure@type'    => 'audio/mpeg',
	};
	foreach my $key (%{$podcast}) {
		my $value = &rewrite_value($podcast->{$key});
		if (defined($value)) {
			if (my $error = &is_invalid($value)) {
				Carp::carp "$error - $file->$key, '$value'";
			}
			$item->set($key => $value);
		}
	}
	# for itunes
	if ($opt{'use_itunes'}) {
		$feed->xmlns('xmlns:itunes' => 'http://www.itunes.com/DTDs/Podcast-1.0.dtd');
		my $itunes  = {
			'itunes:author'     => $tags->{'ARTIST'},
			'itunes:subtitle'   => [$tags->{'ALBUM'}, $tags->{'TRACKNUM'}],
			'itunes:summary'    => '',                # CDATA is disallowed
			'itunes:duration'   => $info->{'TIME'},
			'itunes:keywords'   => [$tags->{'ARTIST'}, $tags->{'YEAR'}],
		};
		foreach my $key (%{$itunes}) {
			my $value = &rewrite_value($itunes->{$key});
			$item->set($key => $value) if (defined($value));
		}
	}
	return $item;
}

sub is_invalid {
	my $value = shift;
	return "Not utf8 character, ignored" unless ($value =~ /^(?:$re_utf8)*$/);
	return;
}

sub rewrite_value {
	my $value = shift;
	if (UNIVERSAL::isa($value, 'ARRAY')) {
		my @values = map { s/^\s+//s; s/\s+$//s; $_ } @{$value}; #}
		@values = map { &encode_value($_) } grep { length($_) } @values;
		$value = join(', ', @values);
	} else {
		$value = &encode_value($value);
	}
	return (defined($value) and length($value)) ? $value : undef;
}

sub encode_value {
	my $value = shift;
	return $value if (defined($use_encode) and defined($use_jcode) and not ($use_encode or $use_jcode)); # Can't encode (already tried).
	return $value if (not defined($value));         # $value is null.
	return $value if ($value =~ /^(?:$re_utf8)*$/); # $value is utf8.
	# try Encode
	if (not defined($use_encode)) {
		eval { use Encode; };
		$use_encode = $@ ? 0 : 1;
	}
	return encode_utf8($value) if ($use_encode);
	# try Jcode
	if (not defined($use_jcode)) {
		eval { use Jcode; };
		$use_jcode = $@ ? 0 : 1;
	}
	return Jcode->new($value)->utf8 if ($use_jcode);
	# can't encode
	return $value;
}

1;

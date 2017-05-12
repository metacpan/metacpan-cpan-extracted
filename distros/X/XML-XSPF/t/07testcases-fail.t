use Test::More 'tests' => '52';

BEGIN {
	use_ok('XML::XSPF');
};

my @files = qw(
	playlist-baddate.xspf
	playlist-badversion.xspf
	playlist-containshtml-annotation.xspf
	playlist-containshtml-creator.xspf
	playlist-containshtml-title.xspf
	playlist-invalidnamespace.xspf
	playlist-missingnamespace.xspf
	playlist-missingtracklist.xspf
	playlist-missingversion.xspf
	playlist-noturi-attribution-identifier.xspf
	playlist-noturi-attribution-location.xspf
	playlist-noturi-extension.xspf
	playlist-noturi-identifier.xspf
	playlist-noturi-image.xspf
	playlist-noturi-info.xspf
	playlist-noturi-license.xspf
	playlist-noturi-link-content.xspf
	playlist-noturi-link-rel.xspf
	playlist-noturi-location.xspf
	playlist-noturi-meta.xspf
	playlist-toomany-annotation.xspf
	playlist-toomany-attribution.xspf
	playlist-toomany-creator.xspf
	playlist-toomany-date.xspf
	playlist-toomany-identifier.xspf
	playlist-toomany-image.xspf
	playlist-toomany-info.xspf
	playlist-toomany-license.xspf
	playlist-toomany-location.xspf
	playlist-toomany-title.xspf
	playlist-toomany-tracklist.xspf
	track-badint-duration.xspf
	track-badint-tracknum.xspf
	track-markup-album.xspf
	track-markup-annotation.xspf
	track-markup-creator.xspf
	track-markup-title.xspf
	track-noturi-extension.xspf
	track-noturi-identifier.xspf
	track-noturi-image.xspf
	track-noturi-info.xspf
	track-noturi-link-rel.xspf
	track-noturi-link.xspf
	track-noturi-location.xspf
	track-noturi-meta-rel.xspf
	track-toomany-album.xspf
	track-toomany-annotation.xspf
	track-toomany-creator.xspf
	track-toomany-duration.xspf
	track-toomany-image.xspf
	track-toomany-info.xspf
	track-toomany-title.xspf
	track-toomany-tracknum.xspf
);

for my $file (@files) {

	# XXXX - no extensions yet.
	if ($file =~ /extension/) {
		next;
	}

	my $xspf = eval { XML::XSPF->parse("data/testcase/fail/$file") };

	ok(!defined $xspf, "XML::XSPF failed to parse bogus playlist $file");
}

#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use Test::Trap;
use List::Util qw/max/;
use File::Slurp;
use JSON;
use Encode;
use Data::Dumper;
use lib 't/lib';

$Data::Dumper::Indent = 1;

my @REF_FILES;
BEGIN { @REF_FILES = glob('t/data/ref/*.json') }

my %ALIASES;
BEGIN {
	open my $fh, '<', 't/data/aliases.json' or
		die "Could not open t/data/aliases.json: $!";
	my $blob = do { local $/=''; <$fh> };
	close $fh;
	%ALIASES = %{decode_json($blob)};
}

BEGIN {
	my $video_tests_n = 27; # n tests performed in video_tests() (recursive)
	plan tests => (1 + (@REF_FILES + keys %ALIASES) * $video_tests_n);
	use_ok('WWW::SVT::Play::Video')
}

sub get_number {
	my $f = shift;
	my ($n) = $f =~ m|([^/]+)\.json$|;
	return $n;
}

sub load_testdata {
	my %ref;
	my $json = JSON->new->utf8;

	for my $file (@REF_FILES) {
		my $n = get_number($file);
		my $data = read_file($file);
		$ref{$n} = $json->decode(encode('utf8', $data));
	}

	return %ref;
}

sub video_tests {
	my $url = shift;
	my($n, $ref) = @_;
	note("Tests for $url ($n)");

	my $svtp = new_ok('WWW::SVT::Play::Video', [$ref->{url}]);

	is($svtp->url, $ref->{url}, '->url()');
	is($svtp->title, $ref->{title}, '->title()');
	is($svtp->duration, $ref->{duration}, '->duration()');

	SKIP: {
		skip 'RTMP specific tests', 10 unless $ref->{has}->{rtmp};
		ok $svtp->has_rtmp, "has rtmp streams";

		my %ref_streams = map {
			$_->{bitrate} => $_->{url}
		} grep {
			$_->{type} eq 'rtmp'
		} @{$ref->{streams}};

		is_deeply(
			[sort {$a <=> $b } $svtp->rtmp_bitrates],
			[sort {$a <=> $b } keys %ref_streams],
			'->bitrates() in list context'
		);

		my $max = max $svtp->rtmp_bitrates;
		is(
			scalar $svtp->rtmp_bitrates,
			$max,
			'->bitrates() in scalar context'
		);

		my %rtmp_streams = $svtp->stream(protocol => 'rtmp');
		is_deeply(
			[ sort { $a <=> $b } keys %rtmp_streams ],
			[ sort { $a <=> $b } keys %ref_streams ],
			'expected rtmp stream bitrates'
		);

		# We got one RTMP test case, with 3 bitrates
		for my $bitrate (keys %rtmp_streams) {
			ok exists $ref_streams{$bitrate}, "expected bitrate";
			my $stream = $svtp->stream(
				protocol => 'rtmp',
				bitrate => $bitrate
			);

			is $stream->url, $ref_streams{$bitrate},
				"expected url for rtmp bitrate $bitrate";
		}
	}

	SKIP: {
		skip 'HLS specific tests', 2 unless $ref->{has}->{hls};
		ok $svtp->has_hls, "has hls streams";
		my ($hls_ref) = grep { $_->{type} eq 'hls' } @{$ref->{streams}};
		is $svtp->stream(protocol => 'hls')->url, $hls_ref->{url},
			"expected HLS url";
	}

	SKIP: {
		skip 'HDS specific tests', 2 unless $ref->{has}->{hds};
		ok $svtp->has_hds, "has hds streams";
		my ($hds_ref) = grep { $_->{type} eq 'hds' } @{$ref->{streams}};
		is $svtp->stream(protocol => 'hds')->url, $hds_ref->{url},
			"expected HDS url";
	}

	SKIP: {
		skip 'HTTP specific tests', 2 unless $ref->{has}->{http};
		ok $svtp->has_http, "has http streams";
		my ($http_ref) = grep {
			$_->{type} eq 'http'
		} @{$ref->{streams}};
		is $svtp->stream(protocol => 'http')->url, $http_ref->{url},
			"expected HTTP url";
	}

	test_filename($ref, $svtp);

	is($svtp->duration, $ref->{duration}, '->duration()');

	# The trivial case where no subtitle is available
	is_deeply(
		[$svtp->subtitles],
		$ref->{subtitles},
		'->subtitles() in list context (no subs)'
	);
	is(
		$svtp->subtitles,
		$ref->{subtitles}->[0],
		'->subtitles() in scalar context (no subs)'
	);
}

sub test_filename {
	my $ref = shift;
	my $svtp = shift;

	is($svtp->filename, $ref->{filename}, '->filename (no format)');

	is(
		$svtp->filename('rtmp'),
		"$ref->{filename}.rtmp",
		'filename method: called with type rtmp'
	);

	is(
		$svtp->filename('hds'),
		"$ref->{filename}.flv",
		'filename method: called with type hds'
	);

	is(
		$svtp->filename('hls'),
		"$ref->{filename}.mp4",
		'filename method: called with type hls'
	);

}

my %testcases = load_testdata();
for my $case (keys %testcases) {
	video_tests($testcases{$case}->{url}, $case, $testcases{$case});
}

for my $alias (keys %ALIASES) {
	video_tests($alias, $ALIASES{$alias}, $testcases{$ALIASES{$alias}});
}

#!/usr/bin/perl
use 5.014;
use warnings FATAL => 'all';
use HTML::TreeBuilder;
use Encode;
use JSON;
use Data::Dumper;
use Getopt::Long;
use URI;
use URI::QueryParam;
use URI::Escape;
use LWP::Simple;
$Data::Dumper::Indent = 1;

my $dumper;
GetOptions(
	'dumper'   => \$dumper,
);

sub load_aliases {
	open my $fh, '<', 'aliases.json' or
		die("Could not open 'aliases.json': $!");
	my $blob = do { local $/=''; <$fh> };
	close $fh;
	return decode_json($blob);
}

sub dump_aliases {
	my $aliases = shift;
	dump_json("aliases.json", $aliases);
	say "Updated list of aliases";
}

sub process_url {
	my $url = URI->new(shift);
	$url->query_param('output', 'json');
	return "$url";
}

sub dump_json {
	my $fname = shift;
	my $data = shift;

	open my $fh, '>', $fname or die "Could not open $fname: $!";
	my $json = JSON->new->allow_nonref;
	say $fh $json->pretty->encode($data);
	close $fh;
}

sub dump_ref_json {
	my $n = shift;
	my $data = shift;
	dump_json("ref/$n.json", $data);
	say "Wrote JSON with test reference data to ref/$n.json";
}

sub gen_url {
	my $data = shift;
	return sprintf "http://www.svtplay.se/video/%d/", $data->{videoId};
}

my $aliases = load_aliases();

my $url = shift or die("Need url\n");
my $ppurl = process_url($url);
my $jsonblob = get($ppurl);
my $jsonenc = encode('utf-8', $jsonblob);
my $data = decode_json($jsonenc);
my $n = $data->{videoId} // die "Could not extract videoId from json";

my $file = "$n.json";
say "Wrote raw JSON from SVT Play to $file";
open my $fh, '>', $file or die("Could not open $file: $!");
print $fh $jsonblob;
close $fh;

if ($dumper) {
	say Dumper $data;
	exit 0;
}
# Otherwise, prepare the data for the test format.

my $output;

my $canon_url = gen_url($data);
if ($url =~ /^\Q$canon_url\E/) {
	$canon_url = $url;
} else {
	my ($alias) = URI->new($url)->path =~ m(/([^/]+)$);
	$aliases->{$alias} = $data->{videoId};
}

$output->{url} = gen_url($data);
$output->{ppurl} = $ppurl;

$output->{duration} = $data->{video}->{materialLength};
$output->{subtitles} = [map {
	values $_
} @{$data->{video}->{subtitleReferences}}];
$output->{title} = $data->{context}->{title};
$output->{filename} = uri_unescape(
	URI->new($data->{statistics}->{statisticsUrl})->query
);

$output->{streams} = [map {
	#say Dumper $_;
	my $plt = $_->{playerType};
	my $btr = $_->{bitrate};
	my $url = URI->new($_->{url});
	my $out = {};
	my $type;

	if ($plt eq 'flash') {
		if (lc $url->scheme eq 'http') {
			if ($btr == 0) {
				$type = 'hds'
			} else {
				$type = 'http'
			}
		} else {
			$type = 'rtmp'; # XXX: A bit blunt...
		}
	} elsif ($plt eq 'ios') {
		$type = 'hls'
	} else {
		$type = $plt
	}

	$out->{type} = $type;
	$out->{url} = "$url";
	$out;
} @{$data->{video}->{videoReferences}}];

dump_ref_json($n, $output);
dump_aliases($aliases);

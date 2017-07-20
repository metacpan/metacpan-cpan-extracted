package WWW::Wikipedia::LangTitles;
use warnings;
use strict;
use Carp;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/get_wiki_titles make_wiki_url/;
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
our $VERSION = '0.04';

use LWP::UserAgent;
use URI::Escape 'uri_escape_utf8';
use JSON::Parse 'parse_json';

sub make_wiki_url
{
    my ($name, $lang) = @_;
    if (! $lang) {
	# Defaults to English.
	$lang = 'en';
    }
    # Have to say "enwiki" or "jawiki" in the URL, since it can be
    # "enquote" or something.
    if ($lang !~ /wiki$/) {
	$lang .= 'wiki';
    }
    my $safe_name = $name;
    $safe_name = uri_escape_utf8 ($safe_name);
    # The URL to get the information from.
    my $url = "https://www.wikidata.org/w/api.php?action=wbgetentities&sites=$lang&titles=$safe_name&props=sitelinks/urls|datatype&format=json";
    return $url;
}

sub get_wiki_titles
{
    my ($name, %options) = @_;
    my $lang = $options{lang};
    my $verbose = $options{verbose};
    my $url = make_wiki_url ($name, $lang);
    if ($verbose) {
	print "Getting $name from '$url'.\n";
    }
    my $ua = LWP::UserAgent->new ();
    # Tell the server from what software this request originates, in
    # case this module turns out to be problematic for them somehow.
    my $agent = __PACKAGE__;
    $ua = LWP::UserAgent->new (agent => $agent);
    $ua->default_header (
	'Accept-Encoding' => scalar HTTP::Message::decodable()
    );
    my $response = $ua->get ($url);
    if (! $response->is_success ()) {
	carp "Get $url failed: " . $response->status_line ();
	return;
    }
    if ($verbose) {
	print "$name data was retrieved successfully.\n";
    }
    my $json = $response->decoded_content ();
    my $data = parse_json ($json);
    my $array = $data->{entities};
    my %lang2title;
    for my $k (keys %$array) {
	my $sitelinks = $array->{$k}->{sitelinks};
	for my $k (keys %$sitelinks) {
	    my $lang = $k;
	    # Reject these?  This is a legacy of the script that this
	    # used to be, it might be more useful for the CPAN module
	    # not to reject these.
	    if ($lang =~ /wikiversity|simple|commons|wikiquote|wikibooks/) {
		next;
	    }
	    $lang =~ s/wiki$//;
	    $lang2title{$lang} = $sitelinks->{$k}->{title};
	}
    }
    if ($verbose) {
	print "$name operations complete.\n";
    }
    return \%lang2title;
}

1;

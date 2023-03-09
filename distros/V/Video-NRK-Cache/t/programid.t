#!perl
use v5.36;
use lib qw(./lib t/lib);

use Mock::MonkeyPatch;
use Test::More 0.94;
use Test::Warnings 0.009 qw(:no_end_test);
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';


use Video::NRK::Cache::ProgramId;

plan tests => 11 + $no_warnings;

my $p;

sub nrk_url_re ($prf) { qr<https://.*\bnrk\.no/.*\b\Q$prf\E\b>i }
sub monkey_patch ($method, %http_tiny_response) {
	my %res = (
		url => 'https://...nrk.no/0',
		status => 200,
		success => 1,
		content => '',
		%http_tiny_response,
	);
	return Mock::MonkeyPatch->patch("HTTP::Tiny::$method" => sub {+{%res}});
}


subtest 'direct id' => sub {
	plan tests => 2;
	my $prf = 'MSUS08000119';
	$p = Video::NRK::Cache::ProgramId->new( parse => $prf );
	is $p->id, $prf, 'id';
	like $p->url, nrk_url_re($prf), 'url';
};


subtest 'head header' => sub {
	plan tests => 4;
	my $prf = 'MSUS08000120';
	my $mock = monkey_patch head => (
		headers => { 'x-nrk-program-id' => $prf },
	);
	my $url = 'http://234.192.0.2:14/foofoo';
	$p = Video::NRK::Cache::ProgramId->new( parse => $url );
	is $p->id, $prf, 'id';
	is $p->url, $url, 'url';
	
	# quick path: looks like NRK URL, so network req may not be necessary
	$p = Video::NRK::Cache::ProgramId->new( parse => "https://tv.nrk.no/program/$prf" );
	is $p->id, $prf, 'quick id';
	like $p->url, nrk_url_re($prf), 'quick url';
};


subtest 'get header' => sub {
	plan tests => 2;
	my $prf = 'MSUS08000121';
	my $mock = monkey_patch get => (
		url => my $url = 'https://...nrk.no/1',
		headers => { 'x-nrk-program-id' => $prf },
	);
	$p = Video::NRK::Cache::ProgramId->new( parse => 1 );
	is $p->id, $prf, 'id';
	is $p->url, $url, 'url';
};


subtest 'body meta' => sub {
	plan tests => 2;
	my $mock = monkey_patch get => content => <<END;
<meta property="nrk:program-id" content="MSUS08000122"/> 
<header data-psapi-base-url="https://...nrk.no/base">
END
	$p = Video::NRK::Cache::ProgramId->new( parse => 1 );
	is $p->id, 'MSUS08000122', 'id';
	is $p->psapi_base, 'https://...nrk.no/base', 'psapi changed base';
};


subtest 'body div' => sub {
	plan tests => 2;
	my $mock = monkey_patch get => content => '<div id="series-program-id-container" data-program-id="MSUS08000123"></div>';
	$p = Video::NRK::Cache::ProgramId->new( parse => 1 );
	is $p->id, 'MSUS08000123', 'id';
	is $p->psapi_base, 'https://psapi.nrk.no', 'psapi default base';
};


subtest 'body initial prfId' => sub {
	plan tests => 1;
	my $mock = monkey_patch get => content => '__NRK_TV_SERIES_INITIAL_DATA_V2__ = ...,"prfId":"MSUS08000124",';
	$p = Video::NRK::Cache::ProgramId->new( parse => 1 );
	is $p->id, 'MSUS08000124', 'id';
};


subtest 'body initial prf:' => sub {
	plan tests => 1;
	my $mock = monkey_patch get => content => '__NRK_TV_SERIES_INITIAL_DATA_V2__ = ...,"dimension1":"prf:MSUS08000125",';
	$p = Video::NRK::Cache::ProgramId->new( parse => 1 );
	is $p->id, 'MSUS08000125', 'id';
};


subtest 'body trying harder: word boundary' => sub {
	plan tests => 1;
	no warnings;
	my $mock = monkey_patch get => content => 'foo/MSUS08000126-bar';
	$p = Video::NRK::Cache::ProgramId->new( parse => 1 );
	is $p->id, 'MSUS08000126', 'id';
};


subtest 'body trying harder: JSON-escaped slash' => sub {
	plan tests => 1;
	no warnings;
	my $mock = monkey_patch get => content => 'tv\u002FMSUS08000127?list';
	$p = Video::NRK::Cache::ProgramId->new( parse => 1 );
	is $p->id, 'MSUS08000127', 'id';
};


subtest 'body trying harder: URL-escaped slash' => sub {
	plan tests => 1;
	no warnings;
	my $mock = monkey_patch get => content => '%2FMSUS08000128,';
	$p = Video::NRK::Cache::ProgramId->new( parse => 1 );
	is $p->id, 'MSUS08000128', 'id';
};


subtest 'body trying harder: last ditch' => sub {
	plan tests => 1;
	no warnings;
	my $mock = monkey_patch get => content => 'abcMSUS08000129.';
	$p = Video::NRK::Cache::ProgramId->new( parse => 1 );
	is $p->id, 'MSUS08000129', 'id';
};


done_testing;

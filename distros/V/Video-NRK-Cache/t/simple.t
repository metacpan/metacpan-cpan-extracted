#!perl
use v5.36;
use lib qw(./lib t/lib);

use Mock::MonkeyPatch;
use Test::More 0.94;
use Test::Warnings 0.009 qw(:no_end_test);
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';


use Video::NRK::Cache;
use Video::NRK::Cache::Store;

plan tests => 3 + $no_warnings;

my ($c, $s);


my $url   = 'https://tv.nrk.no/program/NNFA91022023';
my $title = 'bwaaak';
my $desc  = 'xyz';


subtest 'cache object' => sub {
	plan tests => 3;
	
	my $mock_head = Mock::MonkeyPatch->patch("HTTP::Tiny::head" => sub {die});
	my $mock_get = Mock::MonkeyPatch->patch("HTTP::Tiny::get" => sub {die});
	
	# With these parameters, there ought not to be any network traffic.
	isa_ok $c = Video::NRK::Cache->new(
		url => $url,
		meta => { title => $title, desc => $desc },
		options => { quality => 0 },
	), 'Video::NRK::Cache', 'cache object created';
	
	is $c->url, $url, 'cache url method';
	is $c->program_id, 'NNFA91022023', 'cache program_id method';
};


subtest 'store object' => sub {
	plan tests => 1 + 6 + 3;
	
	isa_ok $s = $c->store, 'Video::NRK::Cache::Store', 'store object created';
	
	is $s->url, $url, 'store url method';
	is $s->program_id, 'NNFA91022023', 'store program_id method';
	is $s->meta_title, $title, 'store meta_title method';
	is $s->meta_desc, $desc, 'store meta_desc method';
	is $s->nice, 1, 'store nice method';
	is $s->quality, 0, 'store quality method';
	
	isa_ok $s->dir, 'Path::Tiny', 'store dir method';
	isa_ok $s->file, 'Path::Tiny', 'store file method';
	cmp_ok $s->rate, '>', 0, 'store rate method';
};


subtest 'store create' => sub {
	plan tests => 1;
	
	my $mock_mk = Mock::MonkeyPatch->patch("Path::Tiny::mkpath" => sub {});
	$Video::NRK::Cache::Store::DRY_RUN = 1;
	
	$s->create;
	pass 'store create method lived';
};


done_testing;

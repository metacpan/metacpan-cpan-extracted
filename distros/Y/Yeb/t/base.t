#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Path::Tiny qw( path );

use FindBin qw($Bin);
use lib "$Bin/lib";

$ENV{YEB_ROOT} = $Bin;

use_ok('WebTest');

my $app = WebTest->new;

my @tests = (
	[ '', 'root' ],
	[ 'nomistadontshoot', qr/i am out of here/, 500 ],
	[ 'a/', qr/i am out of here/, 500 ],
	[ 'a/bla', 'export a stash a single b a single c a bla' ],
	[ 'b/bla', 'export b stash b single a b single c b bla' ],
	[ 'images/notfound', undef, 404 ],
	[ 'images/test.jpg', path($Bin,'htdocs','images','test.jpg')->slurp, 200 ],
	[ 'robots.txt', 'robots.txt' ],
	[ 'js/test.js', 'js/test.js' ],
	[ 'subdir/test.js', 'subdir/test.js' ],
	[ 'other/other', 'other and other', 200 ],
	[ 'other/', 'other root', 200 ],
	[ 'post', 'stash post ""' ],
	[ [], 'post', 'stash post "test"' ],
	[ 'postparam', 'paramstash post ""' ],
	[ [ testparam => 1 ], 'postparam', 'paramstash post "1"' ],
);

for (@tests) {
	my $post;
	if (ref $_->[0] eq 'ARRAY') {
		$post = shift @{$_};
	}
	my $path = shift @{$_};
	my $url = "http://localhost/".$path;
	my $test = shift @{$_};
	my $want_code = shift @{$_};
	my $code = defined $want_code ? $want_code : 200;
	ok(my $res = $app->run_test_request( $post ? 'POST' : 'GET', $url, $post ? ($post) : () ), 'response on /'.$path);
	cmp_ok($res->code, '==', $code, 'Status '.$code.' on /'.$path);
	if (ref $test eq 'Regexp') {
		like($res->content, $test, 'Expected content on /'.$path);
	} elsif (defined $test) {
		cmp_ok($res->content, 'eq', $test, 'Expected content on /'.$path);
	}
}

done_testing;

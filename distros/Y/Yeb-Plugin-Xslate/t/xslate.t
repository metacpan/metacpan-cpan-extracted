#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Path::Tiny;

use FindBin qw($Bin);
use lib "$Bin/lib";

SKIP: {
	eval {
		require Text::Xslate;
		require JSON;
		require Plack::Middleware::Session;
	};

	skip "Text::Xslate, JSON or Plack::Middleware::Session is not installed", 1 if $@;

	JSON->import;

	$ENV{YEB_ROOT} = $Bin;

	use_ok('WebXslate');

	my $app = WebXslate->new;

	my @tests = (
		[ '', qr!index page_include\[page\[root\]\]! ],
		[ 'test', qr!index/test page_include\[page\[test\]\]! ],
		[ 'images/notfound', undef, 404 ],
		[ 'images/test.jpg', path($Bin,'htdocs','images','test.jpg')->slurp, 200 ],
		[ 'robots.txt', 'robots.txt' ],
		[ 'js/test.js', 'js/test.js' ],
		[ 'subdir/test.js', 'subdir/test.js' ],
		[ 'no_default_handler_error', qr/i am out of here/, 500 ],
		[ 'other/other', 'other and xslate', 200 ],
		[ 'other/', 'other root', 200 ],
	);

	for (@tests) {
		my $path = $_->[0];
		my $url = "http://localhost/".$path;
		note($url);
		my $test = $_->[1];
		my $code = defined $_->[2] ? $_->[2] : 200;
		ok(my $res = $app->run_test_request( GET => $url ), 'response on /'.$path);
		cmp_ok($res->code, '==', $code, 'Status '.$code.' on /'.$path);
		my $ctn = 'Expected content on /'.$path;
		if (ref $test eq 'Regexp') {
			like($res->content, $test, $ctn);
		} elsif (ref $test eq 'HASH') {
			my $data = from_json($res->content);
			is_deeply($data,$test, $ctn);
		} elsif (defined $test) {
			cmp_ok($res->content, 'eq', $test, $ctn);
		}
	}
}


done_testing;

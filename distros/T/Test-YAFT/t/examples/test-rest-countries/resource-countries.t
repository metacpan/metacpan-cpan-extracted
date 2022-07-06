#!/usr/bin/env perl

use v5.14;
use warnings;

use require::relative "test-helper.pl";

subtest "resource /countries/:continent provides alphabetical sorted list countries on the continent" => sub {
	act { GET "/countries/$_[0]" } 'continent';

	it "should list North America continental countries"
		=> with_continent => 'north-america'
		=> expect         =>
			& expect_http_success
			& expect_json_content_type
			& expect_json_content {
				countries => [
					'Canada',
					'Mexico',
					'USA',
				]
			}
		;

	it "should list Australia continental countries"
		=> with_continent => 'australia'
		=> expect         =>
			& expect_http_success
			& expect_json_content_type
			& expect_json_content {
				countries => [
					'Australia',
				]
			}
		;

	it "should list no country in Antarctica"
		=> with_continent => 'antarctica'
		=> expect         =>
			& expect_http_success
			& expect_json_content_type
			& expect_json_content {
				countries => [
				]
			}
		;
};


had_no_warnings;

done_testing;

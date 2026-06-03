#!/usr/bin/env perl

use v5.14;
use warnings;

use require::relative q (test-helper.pl);

subtest q (resource /countries/:continent provides alphabetical sorted list countries on the continent) => sub {
	act { GET qq (/countries/$_[0]) } q (continent);

	it q (should list North America continental countries)
		=> with_continent => q (north-america)
		=> expect         =>
			& expect_http_success
			& expect_json_content_type
			& expect_json_content {
				countries => [
					q (Canada),
					q (Mexico),
					q (USA),
				]
			}
		;

	it q (should list Australia continental countries)
		=> with_continent => q (australia)
		=> expect         =>
			& expect_http_success
			& expect_json_content_type
			& expect_json_content {
				countries => [
					q (Australia),
				]
			}
		;

	it q (should list no country in Antarctica)
		=> with_continent => q (antarctica)
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

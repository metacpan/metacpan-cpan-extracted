use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok('Text::Index') };

can_ok('Text::Index', qw(
	new
	add_page
	add_pages
	add_keyword
	add_keywords
	pages
	keywords
	find_keyword
	generate_index
));




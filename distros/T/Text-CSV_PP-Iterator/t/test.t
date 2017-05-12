use strict;
use warnings;

use Test::More tests => 18;

# ------------------------

{
	# Can't use BEGIN{use_ok...} because then new() does not return
	# an empty object each time it is called. WTF? Rather, the column_names
	# set in this first scope persist thru all succeeding scopes.
	# Hence the kludge of require .. delete $INC.
	#
	# (1) Test getting headings from the first line of the file.

	require 'Text/CSV_PP/Iterator.pm';

	my($parser_1) = Text::CSV_PP::Iterator -> new
	({
		file_name	=> './t/heading.in.file.csv',
		sep_char	=> '^',
	});

	ok(defined $parser_1, 'new(...) returned an object for the file with the header');
	ok($parser_1 -> isa('Text::CSV_PP::Iterator'), "The object's class is ok");

	my($hashref) = $parser_1 -> fetchrow_hashref();

	ok(defined $hashref, 'fetchrow_hashref() returned ok');
	is(ref $hashref, 'HASH', 'fetchrow_hashref() returned a hashref');
	is($$hashref{'One'}, 'a1', "fetchrow_hashref() returned the right value 'a1' for key 'One'");
	is($$hashref{'Two'}, 'a2', "fetchrow_hashref() returned the right value 'a2' for key 'Two'");

	delete $INC{'Text/CSV_PP/Iterator.pm'};
}

{
	# (2) Test passing headings in via the constructor.

	require 'Text/CSV_PP/Iterator.pm';

	my($parser_2) = Text::CSV_PP::Iterator -> new
	({
		column_names	=> [qw/One Two Three Four Five/],
		file_name		=> './t/no.heading.in.file.csv',
		sep_char		=> '^',
	});

	ok(defined $parser_2, 'new(...) returned an object for the header-less file');
	ok($parser_2 -> isa('Text::CSV_PP::Iterator'), "The object's class is ok");

	my($hashref) = $parser_2 -> fetchrow_hashref();

	ok(defined $hashref, 'fetchrow_hashref() returned ok');
	is(ref $hashref, 'HASH', 'fetchrow_hashref() returned a hashref');
	is($$hashref{'Four'}, 'a4', "fetchrow_hashref() returned the right value 'a4' for key 'Four'");
	is($$hashref{'Five'}, 'a5', "fetchrow_hashref() returned the right value 'a5' for key 'Five'");

	# This 'while' just demonstrates the recommended way of using these parsers.
	# We know there is only 1 record left in the file.
	# Hence we know that 3 more tests will be executed.

	while ($hashref = $parser_2 -> fetchrow_hashref() )
	{
		ok(defined $hashref, 'fetchrow_hashref() returned ok');
		is(ref $hashref, 'HASH', 'fetchrow_hashref() returned a hashref');
		is($$hashref{'Three'}, 'b3', "fetchrow_hashref() returned the right value 'b3' for key 'Three'");
	}

	delete $INC{'Text/CSV_PP/Iterator.pm'};
}

{
	# (3) Test throwing and catching exceptions.

	require 'Text/CSV_PP/Iterator.pm';

	my($parser_3) = Text::CSV_PP::Iterator -> new
	({
		file_name => './t/empty.file.csv',
	});

	ok(defined $parser_3, 'new(...) returned an object for the header-less file');
	ok($parser_3 -> isa('Text::CSV_PP::Iterator'), "The object's class is ok");

	# This line necessarily fails, because an empty file does not contain headers.

	eval{my($hashref) = $parser_3 -> fetchrow_hashref()};

	is(Iterator::X::NoHeadingsInFile -> caught(), "No headings in empty file. \n", 'Throw exception when trying to get headers from an empty file');

	delete $INC{'Text/CSV_PP/Iterator.pm'};
}

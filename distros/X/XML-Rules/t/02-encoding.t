#!perl -T

use strict;
use warnings;
use utf8;
use Test::More tests => 18;
use Data::Dumper;
use Encode qw(encode);

use XML::Rules;

my $data_utf8 = "P\x{159}\x{ed}li\x{17e} \x{17e}lu\x{b4}tou\x{10d}k\x{fd} k\x{fa}\x{148} \x{fa}p\x{11b}l \x{161}\x{ed}len\x{e9} \x{f3}dy.";
	# in case you wonder ... The crazy looking stuff above is a Czech sentence commonly used to test the encodings. It contains all accentuated characters used in Czech and still kinda makes sense.
	# It translates as "Too yellow horse moaned crazy odes." I did say "kinda" ;-)
my $data_windows = encode( 'windows-1250', $data_utf8);
my $data_latin2 = encode( 'ISO-8859-2', $data_utf8);

#content
{
	my $xml_utf8 = <<"*END*";
<?xml version = "1.0" encoding= "utf-8"?>
<data>$data_utf8</data>
*END*

	my $xml_windows = <<"*END*";
<?xml version = "1.0" encoding= "windows-1250"?>
<data>$data_windows</data>
*END*

	my $xml_latin2 = <<"*END*";
<?xml version = "1.0" encoding= "ISO-8859-2"?>
<data>$data_latin2</data>
*END*

	{ #1-3
		my $parser = XML::Rules->new(
			rules => {_default => 'content'},
		);

		my $res_utf8 = $parser->parse($xml_utf8);
#		print Dumper($res_utf8);
		is($res_utf8->{data}, $data_utf8, "Parse XML in utf8");

		my $res_windows = $parser->parse($xml_windows);
#		print Dumper($res_windows);
		is($res_windows->{data}, $data_utf8, "Parse XML in windows-1250");

		my $res_latin2 = $parser->parse($xml_latin2);
#		print Dumper($res_latin2);
		is($res_latin2->{data}, $data_utf8, "Parse XML in latin2");
	}

	{ #4-6
		my $parser = XML::Rules->new(
			rules => {_default => 'content'},
			encode => 'windows-1250',
		);

		my $res_utf8 = $parser->parse($xml_utf8);
#		print Dumper($res_utf8);
		is($res_utf8->{data}, $data_windows, "Parse XML in utf8, return in windows-1250");

		my $res_windows = $parser->parse($xml_windows);
#		print Dumper($res_windows);
		is($res_windows->{data}, $data_windows, "Parse XML in windows-1250, return in windows-1250");

		my $res_latin2 = $parser->parse($xml_latin2);
#		print Dumper($res_latin2);
		is($res_latin2->{data}, $data_windows, "Parse XML in latin2-1250, return in windows-1250");
	}

	{ #5-9
		my $parser = XML::Rules->new(
			rules => {_default => 'content'},
			encode => 'ISO-8859-2',
		);

		my $res_utf8 = $parser->parse($xml_utf8);
#		print Dumper($res_utf8);
		is($res_utf8->{data}, $data_latin2, "Parse XML in utf8, return in ISO-8859-2");

		my $res_windows = $parser->parse($xml_windows);
#		print Dumper($res_windows);
		is($res_windows->{data}, $data_latin2, "Parse XML in windows-1250, return in ISO-8859-2");

		my $res_latin2 = $parser->parse($xml_latin2);
#		print Dumper($res_latin2);
		is($res_latin2->{data}, $data_latin2, "Parse XML in ISO-8859-2, return in ISO-8859-2");
	}
}

# attributes
{
	my $xml_utf8 = <<"*END*";
<?xml version = "1.0" encoding= "utf-8"?>
<data str="$data_utf8"></data>
*END*

	my $xml_windows = <<"*END*";
<?xml version = "1.0" encoding= "windows-1250"?>
<data str="$data_windows"></data>
*END*

	my $xml_latin2 = <<"*END*";
<?xml version = "1.0" encoding= "ISO-8859-2"?>
<data str="$data_latin2"></data>
*END*

	{ #1-3
		my $parser = XML::Rules->new(
			rules => {data => sub {data => $_[1]->{str}}},
		);

		my $res_utf8 = $parser->parse($xml_utf8);
#		print Dumper($res_utf8);
		is($res_utf8->{data}, $data_utf8, "Parse XML in utf8");

		my $res_windows = $parser->parse($xml_windows);
#		print Dumper($res_windows);
		is($res_windows->{data}, $data_utf8, "Parse XML in windows-1250");

		my $res_latin2 = $parser->parse($xml_latin2);
#		print Dumper($res_latin2);
		is($res_latin2->{data}, $data_utf8, "Parse XML in latin2");
	}

	{ #4-6
		my $parser = XML::Rules->new(
			rules => {data => sub {data => $_[1]->{str}}},
			encode => 'windows-1250',
		);

		my $res_utf8 = $parser->parse($xml_utf8);
#		print Dumper($res_utf8);
		is($res_utf8->{data}, $data_windows, "Parse XML in utf8, return in windows-1250");

		my $res_windows = $parser->parse($xml_windows);
#		print Dumper($res_windows);
		is($res_windows->{data}, $data_windows, "Parse XML in windows-1250, return in windows-1250");

		my $res_latin2 = $parser->parse($xml_latin2);
#		print Dumper($res_latin2);
		is($res_latin2->{data}, $data_windows, "Parse XML in latin2-1250, return in windows-1250");
	}

	{ #5-9
		my $parser = XML::Rules->new(
			rules => {data => sub {data => $_[1]->{str}}},
			encode => 'ISO-8859-2',
		);

		my $res_utf8 = $parser->parse($xml_utf8);
#		print Dumper($res_utf8);
		is($res_utf8->{data}, $data_latin2, "Parse XML in utf8, return in ISO-8859-2");

		my $res_windows = $parser->parse($xml_windows);
#		print Dumper($res_windows);
		is($res_windows->{data}, $data_latin2, "Parse XML in windows-1250, return in ISO-8859-2");

		my $res_latin2 = $parser->parse($xml_latin2);
#		print Dumper($res_latin2);
		is($res_latin2->{data}, $data_latin2, "Parse XML in ISO-8859-2, return in ISO-8859-2");
	}
}

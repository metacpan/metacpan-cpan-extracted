#!/usr/bin/perl

use strict;
use warnings;
use Benchmark qw(cmpthese);
use Text::TNetstrings qw(:all);

cmpthese(-10, {
	'null' => sub{decode_tnetstrings(encode_tnetstrings(undef))},
	'string' => sub{decode_tnetstrings(encode_tnetstrings("hello"))},
	'number' => sub{decode_tnetstrings(encode_tnetstrings(42))},
	'float' => sub{decode_tnetstrings(encode_tnetstrings(3.14))},
	'array' => sub{decode_tnetstrings(encode_tnetstrings(["hello", "world"]))},
	'hash' => sub{decode_tnetstrings(encode_tnetstrings({"hello" => "world"}))},
});


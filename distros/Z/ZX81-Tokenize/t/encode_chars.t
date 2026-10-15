use Modern::Perl;
use Test::More;
use Test::HexDifferences; 

BEGIN { use_ok 'ZX81::Tokenize', 'encode_chars' }

eq_or_dump_diff(encode_chars(""), "", "empty string");
eq_or_dump_diff(encode_chars(" % "), pack("C*", 0x00, 0x80), "space");
eq_or_dump_diff(encode_chars("\n"), pack("C*", 0x76), "newline");

eq_or_dump_diff(encode_chars("\\  ".
							 "\\' ".
							 "\\ '".
							 "\\''".
							 "\\. ".
							 "\\: ".
							 "\\.'".
							 "\\:'".
							 "\\##".
							 "\\,,".
							 "\\~~".
							 "\\::".
							 "\\.:".
							 "\\:.".
							 "\\..".
							 "\\':".
							 "\\ :".
							 "\\'.".
							 "\\ .".
							 "\\@@".
							 "\\;;".
							 "\\!!"),
	pack("C*",	0x00,
				0x01,
				0x02,
				0x03,
				0x04,
				0x05,
				0x06,
				0x07,
				0x08,
				0x09,
				0x0a,
				0x80,
				0x81,
				0x82,
				0x83,
				0x84,
				0x85,
				0x86,
				0x87,
				0x88,
				0x89,
				0x8a),
	"graphic characters");

my $text = "";
my $bin = "";
for (0..0xff) {
	$text .= sprintf("\\%02X", $_);
	$bin .= chr($_);
}
eq_or_dump_diff(encode_chars($text), $bin, "hex encoding");

eq_or_dump_diff(encode_chars("\"".
							 "#".
							 "\$".
							 ":".
							 "?".
							 "(".
							 ")".
							 ">".
							 "<".
							 "=".
							 "+".
							 "-".
							 "*".
							 "/".
							 ";".
							 ",".
							 "."),
	pack("C*", 	0x0b,
				0x0c,
				0x0d,
				0x0e,
				0x0f,
				0x10,
				0x11,
				0x12,
				0x13,
				0x14,
				0x15,
				0x16,
				0x17,
				0x18,
				0x19,
				0x1a,
				0x1b),
	"punctuation");

eq_or_dump_diff(encode_chars("%\"".
							 "%#".
							 "%\$".
							 "%:".
							 "%?".
							 "%(".
							 "%)".
							 "%>".
							 "%<".
							 "%=".
							 "%+".
							 "%-".
							 "%*".
							 "%/".
							 "%;".
							 "%,".
							 "%."),
	pack("C*", 	0x80 + 0x0b,
				0x80 + 0x0c,
				0x80 + 0x0d,
				0x80 + 0x0e,
				0x80 + 0x0f,
				0x80 + 0x10,
				0x80 + 0x11,
				0x80 + 0x12,
				0x80 + 0x13,
				0x80 + 0x14,
				0x80 + 0x15,
				0x80 + 0x16,
				0x80 + 0x17,
				0x80 + 0x18,
				0x80 + 0x19,
				0x80 + 0x1a,
				0x80 + 0x1b),
	"inverted punctuation");

$text = "";
$bin = "";
for (0..9) {
	$text .= "$_%$_";
	$bin .= pack("CC", 0x1c + $_, 0x80 + 0x1c + $_);
}
eq_or_dump_diff(encode_chars($text), $bin, "digits");

$text = "";
$bin = "";
for (0..25) {
	$text .= chr(ord('a')+$_).chr(ord('A')+$_).
			'%'.chr(ord('a')+$_).'%'.chr(ord('A')+$_);
	$bin .= pack("CCCC", 0x26 + $_, 0x26 + $_, 0x80 + 0x26 + $_, 0x80 + 0x26 + $_);
}
eq_or_dump_diff(encode_chars($text), $bin, "letters");

eval { encode_chars('@'); };
like $@, qr/cannot encode/, "error";

done_testing;

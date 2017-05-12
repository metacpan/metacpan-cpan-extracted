
use strict;
use warnings;
BEGIN { $| = 1; print "1..57\n"; }

use Unicode::Regex::Set qw(parse);

my $count = 0;
sub ok ($;$) {
    my $r = shift;
    my $p = @_ == 0 ? $r : $r eq shift;
    print $p ? "ok" : "not ok", ' ', ++$count, "\n";
}

ok(1);

ok(parse('[A-Z]'),
	 '[A-Z]');

ok(parse('[a-z A-Z]'),
	 '[a-zA-Z]');

########

# reference -> modification

my $regex = '[A-Z]foobar';

ok(parse(\$regex), '[A-Z]');

ok($regex, 'foobar');

########

ok(parse('[a-z | A-Z]'),
	 '[a-zA-Z]');

ok(parse('[a-z A-Z 0-9]'),
	 '[a-zA-Z0-9]');

ok(parse('[a-z | A-Z | 0-9]'),
	 '[a-zA-Z0-9]');

ok(parse('[a-z  A-Z | 0-9]'),
	 '[a-zA-Z0-9]');

ok(parse('[a-z [A-Z] 0-9]'),
	 '(?:[a-z]|[A-Z]|[0-9])');

ok(parse('[a-z - A-Z]'),
	 '(?:(?![A-Z])[a-z])');

ok(parse('[a-z - A-Z \r \n]'),
	 '(?:(?![A-Z\r\n])[a-z])');

ok(parse('[a-z - A-Z - \r - \n]'),
	 '(?:(?![A-Z\r\n])[a-z])');

ok(parse('[a-z xyz0-9 - A-Z - \r\n]'),
	'(?:(?![A-Z\r\n])[a-zxyz0-9])');

ok(parse('[\p{Latin} - [A-Z - \p{Vowel}]]'),
	'(?:(?!(?:(?![\p{Vowel}])[A-Z]))[\p{Latin}])');

ok(parse('[A-Z & \p{Latin}]'),
	'(?:(?=[\p{Latin}])[A-Z])');

ok(parse('[A-Z & \p{Latin} 0-9]'),
	'(?:(?:(?=[\p{Latin}])[A-Z])|[0-9])');

ok(parse('[A-Z & C-Q & K-S]'),
	'(?:(?=[C-Q])(?=[K-S])[A-Z])');

ok(parse('[\p{A} [\p{B} A-Z] - \p{C} \p{D}]'),
	'(?:(?![\p{C}\p{D}])(?:[\p{A}]|[\p{B}A-Z]))');

ok(parse('[A-Z & [ABC L-Q] & [K-S - QRS]]'),
	'(?:(?=[ABCL-Q])(?=(?:(?![QRS])[K-S]))[A-Z])');

ok(parse('[\p{Latin} & \p{L&} - \p{ASCII}]'),
	'(?:(?![\p{ASCII}])(?:(?=[\p{L&}])[\p{Latin}]))');

ok(parse('[ \[-\] & abc\ xyz ]'),
	'(?:(?=[abc\ xyz])[\[-\]])');

ok(parse('[^ A-Z]'),
	'(?:(?![A-Z])(?s:.))');

ok(parse('[ ^A-Z PERL]'),
	'(?:[^A-Z]|[PERL])');

ok(parse('[^ a-z A-Z 0-9]'),
	'(?:(?![a-zA-Z0-9])(?s:.))');

ok(parse('[^A-Z a-z 0-9]'),
	'(?:(?![A-Za-z0-9])(?s:.))');

ok(parse('[^[A-Z a-z 0-9]]'),
	'(?:(?![A-Za-z0-9])(?s:.))');

ok(parse('[^B-Z & A-D]'),
	'(?:(?!(?:(?=[A-D])[B-Z]))(?s:.))');

ok(parse('[^A-Z - PERL]'),
	'(?:(?!(?:(?![PERL])[A-Z]))(?s:.))');

ok(parse('[A-Z - [^ PERL]]'),
	'(?:(?!(?:(?![PERL])(?s:.)))[A-Z])');

ok(parse('[A-Z & [^JUNK]]'),
	'(?:(?=(?:(?![JUNK])(?s:.)))[A-Z])');

ok(parse('[^ A-Z - [^pqr] ]'),
	'(?:(?!(?:(?!(?:(?![pqr])(?s:.)))[A-Z]))(?s:.))');

ok(parse('[\] \-\ 	 ]'),
	 '[\]\-\ ]');

ok(parse('[\p{letter} \p{decimal number}]'),
	'[\p{letter}\p{decimal number}]');

ok(parse('[\p{alnum} - \P{decimal number}]'),
	'(?:(?![\P{decimal number}])[\p{alnum}])');

ok(parse('[\p{Greek} - \N{GREEK SMALL LETTER ALPHA}]'),
	'(?:(?![\N{GREEK SMALL LETTER ALPHA}])[\p{Greek}])');

ok(parse('[\p{Assigned} - \p{Decimal Digit Number} - a-f A-F]'),
	'(?:(?![\p{Decimal Digit Number}a-fA-F])[\p{Assigned}])');

ok(parse('[\x00-\x7F - ^\p{Latin}]'),
	'(?:(?![^\p{Latin}])[\x00-\x7F])');

ok(parse('[\x00-\x7F ^\p{Latin}]'),
	'(?:[\x00-\x7F]|[^\p{Latin}])');

ok(parse('[\x00-\x7F ^[:alpha:]]'),
	'(?:[\x00-\x7F]|[^[:alpha:]])');

ok(parse('[\x00-\x7F -A-Z]'),
	'(?:[\x00-\x7F]|[-A-Z])');

ok(parse('[0-9 -TEST]'),
	'(?:[0-9]|[-TEST])');

ok(parse('[0- TEST]'),
	'(?:[0-]|[TEST])');

ok(parse('[0\- TEST]'),
	'(?:[0\-]|[TEST])');

ok(parse('[0\c[]'),
	'[0\c[]');

ok(parse('[\c]\c\]'),
	'[\c]\c\]');

ok(parse('[\x00-\x7F - [:gc=Lu:] A-Z]'),
	'(?:(?![[:gc=Lu:]A-Z])[\x00-\x7F])');

ok(parse('[\x00-\x7F - [:^gc=Lu:] A-Z]'),
	'(?:(?![[:^gc=Lu:]A-Z])[\x00-\x7F])');

ok(parse('[\x00-\x7F - [:gc:Lu:] A-Z]'),
	'(?:(?![[:gc:Lu:]A-Z])[\x00-\x7F])');

ok(parse('[\x00-\x7F - [:^gc:Lu:] A-Z]'),
	'(?:(?![[:^gc:Lu:]A-Z])[\x00-\x7F])');

ok(parse('[\x00-\x7F - \p{gc=Lu} A-Z]'),
	'(?:(?![\p{gc=Lu}A-Z])[\x00-\x7F])');

ok(parse('[\x00-\x7F - \p{^gc=Lu} A-Z]'),
	'(?:(?![\p{^gc=Lu}A-Z])[\x00-\x7F])');

ok(parse('[\x00-\x7F - \p{gc:Lu} A-Z]'),
	'(?:(?![\p{gc:Lu}A-Z])[\x00-\x7F])');

ok(parse('[\x00-\x7F - \p{^gc:Lu} A-Z]'),
	'(?:(?![\p{^gc:Lu}A-Z])[\x00-\x7F])');

ok(parse('[^^a]'),
	'(?:(?![^a])(?s:.))');

ok(parse('[^ ^a]'),
	'(?:(?![^a])(?s:.))');

ok(parse('[ ^^a]'),
	'[^^a]');


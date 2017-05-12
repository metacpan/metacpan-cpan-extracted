# -*- perl -*-
# -*- coding: utf-8 -*-
#
# 00GraphemeBreakTest.t - Test suite provided by Unicode Consortium.
#
# - Passed by GraphemeBreakTest-6.1.0.txt (2011-12-07, 17:54:39 UTC), except
#   50 surrogate cases.
# - Passed by GraphemeBreakTest-6.2.0d4.txt (2012-06-02, 23:25:40 UTC), except
#   58 surrogate cases.  [sombok-2.3.0beta1]
# - Passed by GraphemeBreakTest-6.2.0d6.txt (2012-08-14, 17:54:56 UTC), except
#   54 surrogate cases.  [sombok-2.3.0gamma1]
# - Passed by GraphemeBreakTest-6.2.0d8.txt (2012-08-22, 12:41:15 UTC), except
#   54 surrogate cases.  [sombok-2.3.0]
# - Passed by GraphemeBreakTest-6.3.0d1.txt (2012-12-20, 22:18:29 UTC), except
#   54 surrogate cases.  [sombok-2.3.1b]
# - Passed by GraphemeBreakTest-7.0.0d13.txt (2013-11-27, 09:54:39 UTC), except
#   surrogate cases.  [sombok-2.3.2beta1]
# - Passed by GraphemeBreakTest-8.0.0.txt (2015-02-13, 13:47:15 UTC), except
#   surrogate cases.  [sombok-2.4.0]
#
# Note: Legacy-CM feature is enabled.
#

use strict;
use Test::More;
use Encode qw(decode is_utf8);
use Unicode::GCString;

BEGIN {
    my $tests = 0;
    if (open IN, 'test-data/GraphemeBreakTest.txt') {
	my $desc = '';
	while (<IN>) {
	    s/\s*#\s*(.*)//;
	    if ($. <= 2) {
		$desc .= " $1";
		chomp $desc;
	    }
	    next unless /\S/;
	    $tests++;
	}
	close IN;
	if ($tests) {
	    plan tests => $tests;
	    diag $desc;
	} else {
	    plan skip_all => 'test-data/GraphemeBreakTest.txt is empty.';
	}
    } else {
	plan skip_all => 'test-data/GraphemeBreakTest.txt found at '.
	    'http://www.unicode.org/Public/ is required.';
    }
}

my @opts = (LegacyCM => 'YES', ViramaAsJoiner => 'NO');

open IN, 'test-data/GraphemeBreakTest.txt';

while (<IN>) {
    chomp $_;
    s/\s*#\s*(.*)$//;
    my $desc = $1;
    next unless /\S/;

    SKIP: {
	skip "subtests including surrogate", 1
	    if /\bD[89AB][0-9A-F][0-9A-F]\b/;

	s/\s*÷$//;
	s/^÷\s*//;

	my $s = join '',
	    map {
		$_ = chr hex "0x$_";
		$_ = decode('iso-8859-1', $_) unless is_utf8($_);
		$_;
	    }
	    split /\s*(?:÷|×)\s*/, $_;

	is join(' ÷ ',
	    map {
		 join ' × ',
		 map { sprintf '%04X', ord $_ }
		 split //, $_->as_string;
	    }
	    @{Unicode::GCString->new($s, @opts)}
	  ), $_, $desc;
    }
}

close IN;


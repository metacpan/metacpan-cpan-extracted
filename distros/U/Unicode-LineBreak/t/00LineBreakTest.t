# -*- perl -*-
# -*- coding: utf-8 -*-
#
# 00LineBreakTest.t - Test suite provided by Unicode Consortium.
#
# - Passed by LineBreakTest-6.0.0.txt (2010-08-30, 21:08:43 UTC).
# - Passed by LineBreakTest-6.1.0d12.txt (2011-09-16, 22:24:58 UTC).
# - Passed by LineBreakTest-6.1.0d19.txt (2011-12-07, 01:05:50 UTC).
# - 29 subtests failed by LineBreakTest-6.2.0d4.txt (2012-06-02, 23:25:41 UTC).
#   [sombok-2.3.0beta1]
# - Passed by LineBreakTest-6.2.0d6.txt (2012-08-14, 17:54:58 UTC).
#   [sombok-2.3.0gamma1]
# - Passed by LineBreakTest-6.2.0d8.txt (2012-08-22, 12:41:17 UTC).
#   [sombok-2.3.0]
# - Passed by LineBreakTest-6.3.0d1.txt (2012-12-20, 22:18:30 UTC).
#   [sombok-2.3.1b]
# - Passed by LineBreakTest-7.0.0d30.txt (2014-02-19, 15:51:25 UTC). 
#   [sombok-2.3.2beta1]
# - Passed by LineBreakTest-8.0.0.txt (2015-04-30, 09:40:15 UTC).
#   [sombok-2.4.0]
#
# Note: Legacy-CM feature is disabled.
#

use strict;
use Test::More;
use Encode qw(decode is_utf8);
use Unicode::LineBreak qw(:all);

BEGIN {
    my $tests = 0;
    if (open IN, 'test-data/LineBreakTest.txt') {
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
	    plan skip_all => 'test-data/LineBreakTest.txt is empty.';
	}
    } else {
	plan skip_all => 'test-data/LineBreakTest.txt found at '.
	    'http://www.unicode.org/Public/ is required.';
    }
}

my $lb = Unicode::LineBreak->new(
				 BreakIndent => 'NO',
				 ColMax => 1,
				 EAWidth => [[1..65532] => EA_N],
				 Format => undef,
				 LegacyCM => 'NO',
			      );

open IN, 'test-data/LineBreakTest.txt';

while (<IN>) {
    chomp $_;
    s/\s*#\s*(.*)$//;
    my $desc = $1;
    next unless /\S/;

    s/\s*÷$//;
    s/^×\s*//;

    my $s = join '',
	    map {
		$_ = chr hex "0x$_";
		$_ = decode('iso-8859-1', $_) unless is_utf8($_);
		$_;
	    }
	    split /\s*(?:÷|×)\s*/, $_;

    my $got = join(' ÷ ',
	    map {
		 join ' × ',
		 map { sprintf '%04X', ord $_ }
		 split //, $_;
	    }
	    $lb->break($s)
       );

    SKIP: {
	#XXX # Tentative check
	#XXX my $t = $got;
	#XXX if ($t =~ s/ × 200D\b/ ÷ 200D/ and $t eq $_) {
	#XXX     diag "Skipped: $desc";
	#XXX     skip "subtests including debatable ZJ behavior", 1;
	#XXX }

	is $got, $_, $desc;
    }
}

close IN;


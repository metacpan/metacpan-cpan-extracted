#!/pro/bin/perl

use strict;
use warnings;

use Test::More;
use Tie::Array::DBD;

require "./t/util.pl";

sub arraytests {
    my ($DBD, $str) = @_;

    my @array;
    cleanup ($DBD);

    $str ||= "";
    eval { tie @array, "Tie::Array::DBD", dsn ($DBD), { str => $str } };

    unless (tied @array) {
	note ("$DBD with serializer $str not functional");
	return;
	}

    ok (tied @array,					"Array tied with $str");

    # insert
    ok ($array[1] = 1,					"1 =  1");
    is ($array[1],  1,					"1 == 1");
    ok ($array[2] = 1,					"2 =  1");
    is ($array[2],  1,					"2 == 1");
    ok ($array[3] = 3,					"3 =  3");
    is ($array[3],  3,					"3 == 3");

    ok ( exists $array[1],				"Exists 1");
    ok (!exists $array[4],				"Exists 4");

    # update
    ok ($array[2] = 2,					"2 =  2");
    is ($array[2],  2,					"2 == 2");

    is_deeply (\@array,		[ undef, 1..3 ],	"Array");

    is ($array[0] = 0, 0,				"0 = 0");

    # negative indices
    is ($array[-1],  3,					"-1 == 3");
    is ($array[-2],  2,					"-2 == 2");

    # push
    is (push (@array, 4),	5,			"Push single");
    is_deeply (\@array,		[ 0..4 ],		"Array");
    is (push (@array, 5, 6),	7,			"Push multi");
    is_deeply (\@array,		[ 0..6 ],		"Array");

    # delete
    is (pop @array,		6,			"Pop 6");
    is_deeply (\@array,		[ 0..5 ],		"Array");

    $] >= 5.011 and eval q{ # keys, values
	is_deeply ([ sort keys   @array ], [ 0..5 ],	"Keys");
	is_deeply ([ sort values @array ], [ 0..5 ],	"Values");
	};

    # Scalar/count
    is (      $#array,		5,			"Scalar index");
    is (scalar @array,		6,			"Scalar op");

    is (delete $array[4],	4,			"Delete 4");
    is_deeply (\@array,		[ 0..3, undef, 5 ],	"Array");

    # Binary data
    unless ($str eq "XML::Dumper") {
	my $anr = pack "sss", 102, 102, 025;
	ok ($array[4] = $anr,				"Binary value set");
	is ($array[4],  $anr,				"Binary value get");
	}

    ok ($#array = 3,					"Truncate");
    is_deeply (\@array,		[ 0..3 ],		"Array");

    # shift/unshift
    is (shift @array,		0,			"Shift");
    is_deeply (\@array,		[ 1..3 ],		"Array");
    is (unshift (@array, "c"),	4,			"Unshift single");
    is (unshift (@array, "a", "b"), 6,			"Unshift multi");
    is_deeply (\@array,		[ "a".."c", 1..3 ],	"Array");

    ok (@array = (1..3),				"Bulk");
    is_deeply (\@array,		[ 1..3 ],		"Array");

    # clear
    @array = ();
    is_deeply (\@array,		[],			"Clear");

    # splice @array
    ok (@array = (0..9),				"Set for splice");
    is_deeply (\@array,			[ 0..9 ],	"content");
    is_deeply ([splice @array],		[ 0..9 ],	"splice \@array");
    is_deeply (\@array,			[],		".. leftover");
    ok (@array = (0..9),				"Set for splice");
    is_deeply (\@array,			[ 0..9 ],	"content");
    is (scalar splice (@array),		9,		"splice \@array (scalar context)");
    is_deeply (\@array,			[],		".. leftover");

    # splice @array, off
    eval { splice @array, -6 };
    like ($@, qr/^Modification of non-creatable/,	"Croak on negative offset");

    ok (@array = (0..9),				"Set for splice");
    is_deeply (\@array,			[ 0..9 ],	"content");
    is_deeply ([splice @array, 7],	[ 7..9 ],	"splice \@array, off");
    is_deeply (\@array,			[ 0..6 ],	".. leftover");
    is_deeply ([splice @array, 8],	[],		"splice \@array, off (past end of array)");
    is_deeply (\@array,			[ 0..6 ],	".. leftover");
    ok (@array = (0..9),				"Set for splice");
    is_deeply (\@array,			[ 0..9 ],	"content");
    is (scalar splice (@array, 4),	9,		"scalar splice \@array, off (scalar context)");
    is_deeply (\@array,			[ 0..3 ],	".. leftover");

    # splice @array, off, len
    ok (@array = (0..9),				"Set for splice");
    is_deeply (\@array,			[ 0..9 ],	"content");
    is_deeply ([splice @array, 12, 4],	[],		"splice \@array, off, len (past end of array)");
    is_deeply (\@array,			[ 0..9 ],	"content");
    is_deeply ([splice @array, 2,  4],	[ 2..5 ],	"splice \@array, off, len");
    is_deeply (\@array,			[ 0..1, 6..9 ],	".. leftover");
    is_deeply ([splice @array, 2, -2],	[ 6..7 ],	"splice \@array, off, -len");
    is_deeply (\@array,			[ 0..1, 8..9 ],	".. leftover");
    is (scalar splice (@array, 2,  1),	8,		"scalar splice \@array, off, len");
    is_deeply (\@array,			[ 0..1, 9 ],	".. leftover");

    # splice @array, off, len, @new
    ok (@array = (0..9),				"Set for splice");
    is_deeply (\@array,			[ 0..9 ],	"content");
    is_deeply ([splice @array, 12, 4,],	[],		"splice \@array, off, len,    (past end of array)");
    is_deeply ([splice @array, 12, 4, ()],	[],	"splice \@array, off, len, () (past end of array)");
    is_deeply (\@array,			[ 0..9 ],	"content");
    is_deeply ([splice @array, 2, 0, ()],	[],	"splice \@array, off, len, ()");
    is_deeply ([splice @array, 2, 2, 3, 2], [ 2,3 ],	"splice \@array, off, len, ..");
    is_deeply (\@array,		[ 0..1,3,2,4..9 ],	".. leftover");
    is_deeply ([splice @array, 4, -2, 25], [ 4..7 ],	"splice \@array, off, -len");
    is_deeply (\@array,		[ 0,1,3,2,25,8,9 ],	".. leftover");

    is ((tied @array)->readonly (), 0,			"RW");
    is ((tied @array)->readonly (1), 1,			"RO 1");
    my @w;
    eval { $SIG{__WARN__} = sub { push @w => @_; }; $array[42] = 42; };
    is ($array[42], undef,				"FAIL");
    like ($w[0], qr{cannot store},			"Error message");
    is ((tied @array)->readonly (2), 2,			"RO 2");
    eval { $array[42] = 42; };
    like ($@, qr{cannot store},				"Error message");
    is ($array[42], undef,				"FAIL");
    is ((tied @array)->readonly (0), 0,			"RW again");
    eval { $array[42] = 42; };
    is ($array[42], 42,					"PASS");

    untie @array;
    cleanup ($DBD);
    } # arraytest

1;

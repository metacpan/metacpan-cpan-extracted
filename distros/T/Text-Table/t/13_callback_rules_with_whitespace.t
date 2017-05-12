#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use List::Util qw(sum);
use Text::Table;

# Standard Perl Cookbook function.
sub commify {
	my $text = reverse $_[0];
	$text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
	return scalar reverse $text;
}

my $colsep = "  ";		# Use no-pixel column separators.

# Make up some data.
my @names = ("some stuff that's kind of long", "short", "weird negative thing", "the last thing");
my @dur = (123456, 1234.567890, -123456, 123.456);
my @calls = (4082, 477, 91, 45);
my $sumdur = sum(@dur);
my $N = scalar(@names);

# Define table columns, and load the table header.
my %sep = ( is_sep => 1, title => $colsep, body => $colsep );
my $tb = Text::Table->new(
	{ title => "FIRST",		align_title => "left",	align => "left"	},	\%sep,
	{ title => "SECOND",	align_title => "right",	align => "num"	},	\%sep,
	{ title => "%",			align_title => "right",	align => "num"	},	\%sep,
	{ title => "FOUR",		align_title => "right",	align => "num", sample => "123,456,789" },
);

# Load the table body.
for (0 .. $N - 1) {
	$tb->load([
		$names[$_],
		commify((sprintf "%.6f", $dur[$_])),
		sprintf("%.1f%%", $dur[$_]/$sumdur * 100),
		commify($calls[$_]),
	]);
}

# Load the table footer.
$tb->load([
	"TOTAL ($N)",
	commify(sprintf "%.6f", $sumdur),
	sprintf("%.1f%%", 100),
	commify(sum(@calls)),
]);

# Print the table.
my $rule = $tb->rule(
	sub {
		my ($i, $l) = @_;
        # printf "\n1: i=%d l=%d\n", $i, $l;
		return "-" x $l;
	},
	sub {
		my ($i, $l) = @_;
        # printf "\n2: i=%d l=%d\n", $i, $l;
		return " " x $l;
	}
);

my $output =
$tb->title .
$rule .
join('', map { $tb->body($_) } (0 .. $N-1)) .
$rule .
$tb->body($N);

# TEST
is($output, <<'EOF', 'Spaces are handled correctly in rules.');
FIRST                                    SECOND         %         FOUR
------------------------------  ---------------  --------  -----------
some stuff that's kind of long   123,456.000000   9090.9%        4,082
short                              1,234.567890     90.9%          477
weird negative thing            -123,456.000000  -9090.9%           91
the last thing                       123.456000      9.1%           45
------------------------------  ---------------  --------  -----------
TOTAL (4)                          1,358.023890    100.0%        4,695
EOF

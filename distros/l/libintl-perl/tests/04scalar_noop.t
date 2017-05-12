#! /usr/local/bin/perl -w

# vim: syntax=perl
# vim: tabstop=4

use strict;

use Test;

use constant NUM_TESTS => 5;

use Locale::TextDomain;
use POSIX;

BEGIN {
	plan tests => NUM_TESTS;
}

# When called in scalar context, N__() should return its argument,
# not a list.  On the other hand, the other noop functions should
# simply returns their arguments, see
# https://rt.cpan.org/Ticket/Display.html?id=46471 for more.

my $scalar;

$scalar = scalar N__"foobar";
ok 'foobar' eq $scalar;

($scalar) = scalar N__"foobar";
ok 'foobar' eq $scalar;

$scalar = scalar N__n"one", "two", 4;
ok 3 eq $scalar;

$scalar = scalar N__p"ctx", "foobar";
ok 2 eq $scalar;

$scalar = scalar N__np"ctx", "one", "two", 5;
ok 4 eq $scalar;

__END__

Local Variables:
mode: perl
perl-indent-level: 4
perl-continued-statement-offset: 4
perl-continued-brace-offset: 0
perl-brace-offset: -4
perl-brace-imaginary-offset: 0
perl-label-offset: -4
cperl-indent-level: 4
cperl-continued-statement-offset: 2
tab-width: 4
End:

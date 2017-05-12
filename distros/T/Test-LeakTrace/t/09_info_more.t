#!perl -w

use strict;
use Test::More tests => 7;

use Test::LeakTrace qw(:all);
use autouse 'Data::Dumper' => 'Dumper';

my @info = leaked_info{
	my %a = (foo => 42);
	my %b;

	$b{bar} = 3.14;

	{
		$b{a} = \%a;
	}
	$a{b} = \%b;
};

cmp_ok(scalar(@info), '>', 2)
	or diag(Dumper \@info);

is_deeply [grep{ eq_array [$_->[0]], [\42]   } @info], [ [\42,   __FILE__, 10] ];
is_deeply [grep{ eq_array [$_->[0]], [\3.14] } @info], [ [\3.14, __FILE__, 13] ];

my(@x) = grep{ my $r = $_->[0]; ref($r) eq 'REF' && ref(${$r}) eq 'HASH' && exists ${$r}->{b} } @info;

is scalar(@x), 1 or diag(Dumper \@x);
is $x[0][2], 16; # line

(@x) = grep{ my $r = $_->[0]; ref($r) eq 'REF' && ref(${$r}) eq 'HASH' && exists ${$r}->{a} } @info;

is scalar(@x), 1 or diag(Dumper \@x);
is $x[0][2], 18; # line

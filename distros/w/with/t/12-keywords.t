#!perl -T

package main;

use strict;
use warnings;

use Test::More tests => 10;

use with \bless {}, 'with::Mock';

my $c = 0;
++$c for 1 .. 10;
is $c, 10, 'for';

$c = 0;
while ($c < 5) { ++$c; }
is $c, 5, 'while';

$c = undef;
is !defined($c), 1, 'undef, defined';

my @a = (1, 2);

my $x = pop @a;
my $y = shift @a;
push @a, $y;
unshift @a, $x;
is_deeply \@a, [ 2, 1 ], 'pop/shift/push/unshift';

@a = reverse @a;
is_deeply \@a, [ 1, 2 ], 'reverse';

open my $fh, '<', $0 or die "$!";
my $d = do { local $/; <$fh> };
$d =~ s/^(\S+).*/$1/s;
is $d, '#!perl', 'open/do/local';

@a = map { $_ + 1 } 0 .. 5;
is_deeply \@a, [ 1 .. 6 ], 'map';

@a = grep { $_ > 2 } 0 .. 5;
is_deeply \@a, [ 3 .. 5 ], 'grep';

my %h = (foo => 1, bar => 2);
@a = sort { $h{$a} <=> $h{$b} } keys %h;
is_deeply \@a, [ 'foo', 'bar' ], 'sort/keys';

print STDERR "# boo" if 0;
$y = "foo\n";
chomp $y;
is $y, 'foo', 'chomp';

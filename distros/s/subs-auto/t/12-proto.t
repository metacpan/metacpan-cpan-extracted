#!perl -T

use strict;
use warnings;

use Test::More tests => 11;

my $foo;
sub foo ($) { $foo = $_[0] };

my $baz;
eval q|
 use warnings qw<FATAL redefine prototype>;
 sub main::baz ($) { $baz = $_[0] }
|;
like($@, qr/Prototype\s+mismatch\s*:\s+sub\s+main::baz\s*:\s+none\s+vs\s+\(\$\)/, 'baz appears as prototyped');

use subs::auto;

eval { my @x = (1, 5); foo @x };
is($@, '', 'foo was compiled ok');
is($foo, 2, 'foo was called with the right arguments');

eval { my @x = (1, 5); &foo(@x) };
is($@, '', '&foo was compiled ok');
is($foo, 1, '&foo was called with the right arguments');

my $bar;
sub bar (\@) { $bar = 0; $bar += $_ for grep defined, @{$_[0]}  }

eval { my @x = (2, 3, 4); bar @x };
is($@, '', 'bar was compiled ok');
is($bar, 9, 'bar was called with the right arguments');

eval { my @x = ([2, 3], 4); &bar(@x) };
is($@, '', '&bar was compiled ok');
is($bar, 5, '&bar was called with the right arguments');

eval { baz 5 };
like($@, qr/^Undefined\s+subroutine\s+&?main::baz/,'baz couldn\'t be compiled');
is($baz, undef, 'baz can\'t be called because of the prototype mismatch');

no subs::auto;

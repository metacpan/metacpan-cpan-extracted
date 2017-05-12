# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 6;    # last test to print

use vars::global create => qw( $foo @bar %baz );

my $lexfoo    = 'ciao';
my @lexbar    = qw( a tutti );
my %lexbaz    = map { $_ => "value-$_" } @lexbar;
my $lexstring = join '/', $lexfoo, @lexbar, reverse(sort keys %lexbaz),
  sort(values %lexbaz);

eval {
   $foo = $foo = $lexfoo;
   @bar = @bar = @lexbar;
   %baz = %baz = map { $_ => "value-$_" } @bar;
};
is($@, '', 'set of declared variables');

package Whatever;

use vars::global qw( $foo @bar %baz );
*is = \&main::is;
eval {
   my $string = join '/', $foo, @bar, reverse(sort keys %baz),
     sort(values %baz);
   is($string, $lexstring, 'values are catched correctly');
};
is($@, '', 'usage of declared variables');

eval {
   $foo = 'whatever';    # set some different value for $foo
};
is($@,                 '',         'usage of declared variables');
is($vars::global::foo, 'whatever', 'global is *really* global');
is($main::foo,         'whatever', 'global is *really* global');

# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 3;    # last test to print

use vars::global create => qw( $foo @bar %baz );

my $lexfoo    = 'ciao';
my @lexbar    = qw( a tutti );
my %lexbaz    = map { $_ => "value-$_" } @lexbar;
my $lexstring = join '/', $lexfoo, @lexbar, reverse(sort keys %lexbaz),
  sort(values %lexbaz);

eval {
   $foo = $lexfoo;
   @bar = @lexbar;
   %baz = map { $_ => "value-$_" } @bar;
};
is($@, '', 'usage of declared variables');

package Whatever;
use vars::global ':all';
*is = \&main::is;
eval {
   my $string = join '/', $foo, @bar, reverse(sort keys %baz),
     sort(values %baz);
   is($string, $lexstring, 'all variables imported ok');
};
is($@, '', 'usage of declared variables');

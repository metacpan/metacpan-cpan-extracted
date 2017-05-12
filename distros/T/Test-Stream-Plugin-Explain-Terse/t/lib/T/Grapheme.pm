use 5.006;    #our
use strict;
use warnings;

package T::Grapheme;

# ABSTRACT: Generate Pronouncable letter pairs for testing

# AUTHORITY

use Test::Stream::Exporter qw/import default_export/;

default_export qw/grapheme_str/;

my (@CONS) = qw( B C D F G H J K L M N P Q R S T V W X Y Z );
my (@VOLS) = qw( a e i o u );

sub mk_grapheme {
  $CONS[ int( rand() * $#CONS ) ] . $VOLS[ int( rand() * $#VOLS ) ];
}

sub grapheme_str {
  substr scalar( join q[], map { mk_grapheme } 0 .. ( ( $_[0] + 1 ) / 2 ) ), 0, $_[0];
}
1;

=head1 DESCRIPTION

This utility exists for testing because Data::Dump is actually too smart about
compressing strings and will detect anyone using the `x` operator and reverse
the resulting string back into the form

  ( "Str" x $n )

So this utility creates long strings of random but visually easy to check
strings to throw code at.

use strict;
use Test::More 0.98;
use utf8;

use Text::ANSI::Fold;

my $fold = Text::ANSI::Fold->new;

sub chops {
    my $obj = shift;
    [ $fold->chops(@_) ];
}

$fold->configure(text => "1234567890" x 5, width => 10);
is_deeply(chops($fold),
	  [ ("1234567890") x 5 ],
	  "chops");

$fold->configure(text => "1234567890", width => 5);
is_deeply(chops($fold),
	  [ "12345", "67890" ],
	  "array");

$fold->configure(text => "122333444455555", width => [ 1..3 ]);
is_deeply(chops($fold),
	  [ "1", "22", "333" ],
	  "array (short)");

$fold->configure(text => "122333444455555", width => [ 1, 0, 2, 0, 3 ]);
is_deeply(chops($fold),
	  [ "1", "", "22", "", "333" ],
	  "array 0-width (short)");

$fold->configure(text => "122333444455555", width => [ 1..5 ]);
is_deeply(chops($fold),
	  [ "1", "22", "333", "4444", "55555" ],
	  "array (exact)");

$fold->configure(text => "122333444455555", width => [ 1..4, -1 ]);
is_deeply(chops($fold),
	  [ "1", "22", "333", "4444", "55555" ],
	  "array (negative)");

$fold->configure(text => "122333444455555", width => [ 1, 2, 3, -1, 5 ]);
is_deeply(chops($fold),
	  [ "1", "22", "333", "444455555" ],
	  "array (negative in the middle)");

$fold->configure(text => "1223334444555556", width => [ 1..10 ]);
is_deeply(chops($fold),
	  [ "1", "22", "333", "4444", "55555", "6" ],
	  "array (long)");

$fold->text("1223334444555556");
is_deeply(chops($fold, width => [ 1..10 ]),
	  [ "1", "22", "333", "4444", "55555", "6" ],
	  "call with 'width' parameter");

$fold->configure(text => "", width => 10);
is_deeply(chops($fold),
	  [ ],
	  "chops (empty)");

$fold->configure(text => "12233344", width => [ 1..5 ], padding => 1);
is_deeply(chops($fold),
	  [ "1", "22", "333", "44  ", ],
	  "array (padding)");

$fold->configure(text => "12233344", width => [ 1, 2, 3, -1 ], padding => 1);
is_deeply(chops($fold),
	  [ "1", "22", "333", "44", ],
	  "array (padding + -1)");

$fold->configure(text => "", width => 10, padding => 1);
is_deeply(chops($fold),
	  [ " " x 10 ],
	  "chops (empty, padding)");

$fold->configure(text => "", width => 10, padding => 1, padchar => 'x');
is_deeply(chops($fold),
	  [ 'x' x 10 ],
	  "chops (empty, padding, padchar)");

$fold->configure(text => "> 111222333444555", width => 5, prefix => '> ');
is_deeply(chops($fold),
	  [ "> 111", "> 222", "> 333", "> 444", "> 555", ],
	  "prefix");

$fold->configure(text => "01: 111222333444555", width => 7,
		 prefix => do { my $n = 2; sub { sprintf "%02d: ", $n++ } });
is_deeply(chops($fold),
	  [ "01: 111", "02: 222", "03: 333", "04: 444", "05: 555", ],
	  "prefix sub");

# length: visual width of each chop
{
    my $f = Text::ANSI::Fold->new;
    my @c = $f->text("aaあい\e[31mb\e[m")->chops(width => 4, length => \my @l);
    is_deeply([ \@c, \@l ], [ [ "aaあ", "い\e[31mb\e[m" ], [ 4, 3 ] ], "chops length");
    @c = $f->text("1223334444")->chops(width => [ 1, 0, -2, 3 ], length => \my @m);
    is_deeply(\@m, [ 1, 0, 9 ], "chops length (multiple width)");
    $f->configure(padding => 1);
    @c = $f->text("aaa bbbb")->chops(width => 6, length => \my @n);
    is_deeply([ \@c, \@n ], [ [ "aaa bb", "bb    " ], [ 6, 2 ] ], "chops length (padding is not included)");
}

done_testing;

use strict;
use Test::More 0.98;
use utf8;

use Text::ANSI::Fold;

my $fold = new Text::ANSI::Fold;

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

$fold->configure(text => "122333444455555", width => [ 1..5 ]);
is_deeply(chops($fold),
	  [ "1", "22", "333", "4444", "55555" ],
	  "array (exact)");

$fold->configure(text => "1223334444555556", width => [ 1..10 ]);
is_deeply(chops($fold),
	  [ "1", "22", "333", "4444", "55555", "6" ],
	  "array (long)");

$fold->text("1223334444555556");
is_deeply(chops($fold, width => [ 1..10 ]),
	  [ "1", "22", "333", "4444", "55555", "6" ],
	  "call with 'width' parameter");

done_testing;

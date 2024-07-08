#! perl

use Test::More tests => 1;
use Text::Template::Tiny;

my $ctl =
  { one => "two",
    two => "three",
    three => { four => "five",
	       five => { six => "seven" } }
  };

my $data = <<EOD;
There's a
[% one %]
[% two %]
[% three %]
[% three.four %]
[% three.five %]
[% three.five.six %]
[% three.five.seven %]
EOD

my $xp = <<EOD;
There's a
two
three
[% three %]
five
[% three.five %]
seven
[% three.five.seven %]
EOD

my $x = Text::Template::Tiny->new( %$ctl );
is( $x->expand($data), $xp, "ok" );

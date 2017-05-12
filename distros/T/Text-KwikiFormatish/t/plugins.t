#!perl -w

use Test::More tests => 8;

use_ok( 'Text::KwikiFormatish' );

my ( $i, $o ); # output and input

$i = <<_EOF;
[&icon test1.png]

[&img test2.png] [&img test3.png named image]

A [&glyph test4.png] B
C [&glyph test5.png named glyph] D
_EOF

eval {
    $o = Text::KwikiFormatish::format( $i );
};
is( $@, '', 'format subroutine' );
isnt( length($o), 0, 'output produced' );

# plugins
like( $o, qr#<img src="test1.png"#, "icon" );
like( $o, qr#<img\s+src="test2.png"#, "img" );
like( $o, qr#<img\s+src="test3.png"\s+alt="[^"]+"\s+title="named image"#, "named img" );
TODO: {
    local $TODO = 'glyph plugin not finished';
    like( $o, qr#A <img\s+src="test4.png"\s+alt="\*"[^>]*> B#, "glyph" );
    like( $o, qr#C <img\s+src="test5.png"\s+alt="named glyph"[^>]*> B#, "named glyph" );
}


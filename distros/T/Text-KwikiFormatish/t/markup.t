#!perl -w

use Test::More tests => 25;

use_ok( 'Text::KwikiFormatish' );

my ( $i, $o ); # output and input

$i = <<_EOF;
= Header 1
== Header 2
=== Header 3
==== Header 4
===== Header 5
====== Header 6
= Header T1 =
= Header T2 ============
= bacon & eggs
<escapeme>
----
##comment1
## comment2
* itemized
0 enumerated
  code
*strong*
//emphasized//
here is an---mdash
| bacon | eggs |
ham & cheese

para

_EOF

eval {
    $o = Text::KwikiFormatish::format( $i );
};
is( $@, '', 'format subroutine' );
isnt( length($o), 0, 'output produced' );

# markup tests
foreach ( 1 .. 6 ) {
    like( $o, qr#<h$_>Header $_</h$_>#, "heading $_" );
}
foreach ( 1 .. 2 ) {
    like( $o, qr#<h1>Header T$_</h1>#, "heading 1 test $_, trailing '='" );
}
like( $o, qr#<h1>bacon &amp; eggs</h1>#, "ampersands in headers" );
like( $o, qr#&lt;escapeme&gt;#, "escape_html" );
like( $o, qr#<hr/>#, "horizontal_line" );
foreach ( 1 .. 2 ) {
    like( $o, qr/<!--\s*comment$_\s*-->/, "comment $_" );
}
foreach ( qw( itemized enumerated ) ) {
    like( $o, qr#<li>$_#, $_ );
}
like( $o, qr#<pre>code#, "code" );
like( $o, qr#<strong>strong</strong>#, "strong" );
like( $o, qr#<em>emphasized</em>#, "emphasized" );
like( $o, qr#an&\#151;mdash#, "mdash" );
like( $o, qr#<p>\npara\n</p>#, "paragraph" );
like( $o, qr#<td>bacon</td>\s*<td>eggs</td>#, "table" );
like( $o, qr#ham &amp; cheese#, "escaping ampersands" );


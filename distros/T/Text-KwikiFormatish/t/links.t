#!perl -w

use Test::More tests => 8;

use_ok( 'Text::KwikiFormatish' );

my ( $i, $o ); # output and input

my $link       = q(http://www.domain.com/dir/page.html);
my $link_regex = q(http://www\.domain\.com/dir/page\.html);

$i = <<_EOF;
SomePage
negated !SomePage
$link
[testlink $link]
user\@domain.com
http://domain.com/image.png
_EOF

eval {
    $o = Text::KwikiFormatish::format( $i );
};
is( $@, '', 'format subroutine' );
isnt( length($o), 0, 'output produced' );

like( $o, qr#<a[^>]+>SomePage</a>#, "link" );
like( $o, qr#<a[^>]+$link_regex[^>]+>$link_regex</a>#, "auto link" );
like( $o, qr#<a[^>]+$link_regex[^>]+>testlink</a>#, "named link" );
like( $o, qr#negated\s+SomePage#, "negated link" );
like( $o, qr#<img src="http://domain\.com/image\.png"#, "image href" );


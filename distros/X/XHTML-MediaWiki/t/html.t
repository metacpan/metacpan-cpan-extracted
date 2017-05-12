use Test::More;
use Test::XML;

BEGIN {
    eval {
	require Test::Exception;
	Test::Exception->import();
    };
    if ($@) {
	plan skip_all => "Test::Exception needed";
    }
}

plan tests => 7;

use XHTML::MediaWiki;

my $mediawiki = XHTML::MediaWiki->new();

my @text;

throws_ok {
$mediawiki->_find_blocks_in_html("x", "x");
} qr/Died/, 'extra';

is(scalar $mediawiki->_find_blocks_in_html(), 0, "empty");
is(@text = $mediawiki->_find_blocks_in_html("\r\n\r\n"), 0, "empty lines 1");
is(@text = $mediawiki->_find_blocks_in_html("\r\n\r\n"), 0, "empty lines 2");


throws_ok {
@text = $mediawiki->_find_blocks_in_html(<<EOP);
This <i/>is a line of text
EOP
} qr/helpme/, "i";

ok(1);
use Data::Dumper;

throws_ok {
@text = $mediawiki->_find_blocks_in_html(<<EOP);
<i>
</i>
EOP
} qr/helpme/, "unknown tag 2";

$XHTML::MediaWiki::DEBUG = 0;
@text = $mediawiki->_find_blocks_in_html(<<EOP);
<div>
<p>
Paragraph
</div>
</div>
</p>
</div>
EOP

$XHTML::MediaWiki::DEBUG = 1;
@text = $mediawiki->_find_blocks_in_html(<<EOP);
<div>
<p>
Paragraph
<span>
<span>
<span>
<span>
</p>
</div>
EOP

@text = $mediawiki->_find_blocks_in_html(<<EOP);
<body>
<p>
<div>
<span>
Paragraph
</body>
EOP

#warn Dumper @text;

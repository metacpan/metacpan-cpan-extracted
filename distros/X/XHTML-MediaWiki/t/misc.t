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

my $text = $mediawiki->get_block();

is($text, "XHTML::MediaWiki::Block::Special", "get_block()");

throws_ok {
    XHTML::MediaWiki::Parser::Block->new( type => 'unordered' );
} qr /internal error/, "test 2";

isa_ok(XHTML::MediaWiki::Parser::Block->new( type => 'unordered', level => 1 ),
    "XHTML::MediaWiki::Parser::Block",
    "Block"
);

my $block = XHTML::MediaWiki::Parser::Block->new( type => "x");

use Data::Dumper;
$block->args();
isa_ok($block->get_line(),
"XHTML::MediaWiki::Parser::Block::Line",
"Line"
);
$block->in_nowiki();
throws_ok {
$block->append_text("text", "extra");
} qr/extra arguments/, "append_text()";

$block->in_nowiki();

$block->get_line();

throws_ok {
$block->set_end_line();
} qr/need count/, "set_end_line() 1";
$block->set_end_line(1);

is( XHTML::MediaWiki::encode(), undef, "encode" );

delete $block->{line};
$block->in_nowiki();


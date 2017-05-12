use strict;
use warnings;
use utf8;
use Test::More;

use Text::Mecabist;

my $parser = Text::Mecabist->new();

my $text = q{
こんにちは  こんにちは
こんにちは　こ
};

my $doc = $parser->parse($text);
is($doc->join('text'), $text);

done_testing();

use strict;
use Test::More;
use Encode;
use utf8;
BEGIN { use_ok("Text::CaboCha") }

my $data = encode(Text::CaboCha::ENCODING, "太郎は次郎が持っている本を花子に渡した。");

my $cabocha = Text::CaboCha->new;
my $tree = $cabocha->parse($data);

my @format = qw(
    CABOCHA_FORMAT_TREE
    CABOCHA_FORMAT_LATTICE
    CABOCHA_FORMAT_TREE_LATTICE
    CABOCHA_FORMAT_XML
    CABOCHA_FORMAT_CONLL
    CABOCHA_FORMAT_NONE
);

for my $fmt (@format) {
    eval "\$tree->tostr(Text::CaboCha::$fmt);";
    ok(!$@, "$fmt tree->tostr() is not ok");
}

done_testing;
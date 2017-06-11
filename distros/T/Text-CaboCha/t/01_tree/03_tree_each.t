use strict;
use Test::More;
use Encode;
use utf8;
BEGIN { use_ok("Text::CaboCha") }

my $data = encode(Text::CaboCha::ENCODING, "太郎は次郎が持っている本を花子に渡した。");

my $cabocha = Text::CaboCha->new;
my $tree = $cabocha->parse($data);

my $tokens = $tree->tokens;
ok(ref $tokens eq 'ARRAY', "tree->tokens is not ARRAYREF");

for my $token (@$tokens) {
    ok(ref $token eq 'Text::CaboCha::Token', "failed to foreach with tree->tokens");
}

my $chunks = $tree->chunks;
ok(ref $tokens eq 'ARRAY', "tree->chunks is not ARRAYREF");

for my $chunk (@$chunks) {
    ok(ref $chunk eq 'Text::CaboCha::Chunk', "failed to foreach with tree->chunks");
}

done_testing;
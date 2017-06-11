use strict;
use Test::More;
use Encode;
use utf8;
BEGIN { use_ok("Text::CaboCha") }

my $data = encode(Text::CaboCha::ENCODING, "太郎は次郎が持っている本を花子に渡した。");

my $cabocha = Text::CaboCha->new;
my $tree = $cabocha->parse($data);
my $chunk_size = $tree->chunk_size;

my @fields = qw(
    link
    head_pos
    func_pos
    token_size
    token_pos
    score
    feature_list
    additional_info
    list_size
);

for (my $i = 0; $i < $chunk_size; $i++) {
    my $chunk = $tree->chunk($i);
    for my $field (@fields) {
        my $p = eval { $chunk->$field };
        if ($@) {
            diag($@);
        }
        ok(!$@, "chunk->$field is not ok (" . (defined $p ? 
            encode_utf8(decode(Text::CaboCha::ENCODING, $p)) : "null") . ")");
        if ($field eq 'feature_list') {
            ok(ref $p eq 'ARRAY', "chunk->feature_list is not ARRAYREF");
        }
    }
}

done_testing;
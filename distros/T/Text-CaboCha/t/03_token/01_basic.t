use strict;
use Test::More;
use Encode;
use utf8;
BEGIN { use_ok("Text::CaboCha") }

my $data = encode(Text::CaboCha::ENCODING, "太郎は次郎が持っている本を花子に渡した。");

my $cabocha = Text::CaboCha->new;
my $tree = $cabocha->parse($data);
my $token_size = $tree->token_size;

my @fields = qw(
    surface
    normalized_surface
    feature
    feature_list
    feature_list_size
    ne
    additional_info
    chunk
);

for (my $i = 0; $i < $token_size; $i++) {
    my $token = $tree->token($i);
    if ($token->chunk) {
        for my $field (@fields) {
            my $p = eval { $token->$field };
            if ($@) {
                diag($@);
            }
            ok(!$@, "token->$field is not ok (" . (defined $p ? 
                encode_utf8(decode(Text::CaboCha::ENCODING, $p)) : "null") . ")");
            if ($field eq 'feature_list') {
                ok(ref $p eq 'ARRAY', "token->feature_list is not ARRAYREF");
            }
        }
    }
}

done_testing;
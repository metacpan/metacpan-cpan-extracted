use strict;
use Encode;
use Test::More;
BEGIN {
    if (!$ENV{TEST_MEMLEAK}) {
        plan skip_all => "\$ENV{TEST_MEMLEAK} is not set";
    }
    use_ok("Text::CaboCha");
}
use Test::Requires 'Test::Valgrind';

my $data = encode(Text::CaboCha::ENCODING, "太郎は次郎が持っている本を花子に渡した。");

subtest "Text::CaboCha->new" => sub {
    Text::CaboCha->new;
};

my $cabocha = Text::CaboCha->new;

subtest "Cabocha->tree" => sub {
    my $tree = $cabocha->parse($data);
    my @methods = qw(size token_size token chunk_size chunk);
    my $size;
    for my $method (@methods) {
        if ($method =~ /size$/) {
            $size = eval { $tree->$method };
        } else {
            eval { $tree->$method($size) };
        }
    }
};

my $tree = $cabocha->parse($data);

subtest "CaboCha->tree->tostr" => sub {
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
    }
};

subtest "CaboCha->tree->chunk" => sub {
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
            $chunk->$field;
        }
    }
};

subtest "CaboCha->tree->token" => sub {
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
                $token->$field;
            }
        }
    }
};

done_testing;
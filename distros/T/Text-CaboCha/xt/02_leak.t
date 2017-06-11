use strict;
use Encode;
use Test::More;
BEGIN {
    if (!$ENV{TEST_LEAKTRACE}) {
        plan skip_all => "\$ENV{TEST_LEAKTRACE} is not set";
    }
    use_ok("Text::CaboCha");
}
use Test::Requires 'Test::LeakTrace';

my $data = encode(Text::CaboCha::ENCODING, "太郎は次郎が持っている本を花子に渡した。");

subtest "Text::CaboCha->new" => sub {
    no_leaks_ok {
        Text::CaboCha->new;
    }, 'Detected memory leak';
};

my $cabocha = Text::CaboCha->new;

subtest "Cabocha->tree" => sub {
    no_leaks_ok {
        $cabocha->parse($data);
    }, 'Detected memory leak';
    
    my $tree = $cabocha->parse($data);
    my @methods = qw(size token_size token chunk_size chunk);
    my $size;
    for my $method (@methods) {
        no_leaks_ok {
            if ($method =~ /size$/) {
                $size = eval { $tree->$method };
            } else {
                eval { $tree->$method($size) };
            }
        }, "Detected memory leak. when tree->$method";
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
        no_leaks_ok {
            eval "\$tree->tostr(Text::CaboCha::$fmt);";
        }, "Detected memory leak. when set $fmt";
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
            no_leaks_ok {
                $chunk->$field;
            }, "Detected memory leak. when chunk->$field";
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
                no_leaks_ok {
                    $token->$field;
                }, "Detected memory leak. when token->$field";
            }
        }
    }
};

subtest "Cabocha->tree->chunks" => sub {
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

    no_leaks_ok {
        for my $chunk (@{ $tree->chunks }) {
            for my $field (@fields) {
                $chunk->$field;
            }
        }
    }, "Detected memory leak. when using tree->chunks";
};

subtest "Cabocha->tree->chunks" => sub {
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

    no_leaks_ok {
        for my $token (@{ $tree->tokens }) {
            for my $field (@fields) {
                $token->$field;
            }
        }
    }, "Detected memory leak. when using tree->tokens";
};

done_testing;
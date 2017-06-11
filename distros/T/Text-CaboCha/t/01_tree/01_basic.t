use strict;
use Test::More;
use Encode;
use utf8;
BEGIN { use_ok("Text::CaboCha") }

my $data = encode(Text::CaboCha::ENCODING, "太郎は次郎が持っている本を花子に渡した。");

my $cabocha = Text::CaboCha->new;
ok($cabocha);

my $tree = $cabocha->parse($data);

my @methods = qw(size token_size token chunk_size chunk);

{
    local $@;

    my $size;
    for my $method (@methods) {
        if ($method =~ /size$/) {
            $size = eval { $tree->$method };
        } else {
            eval { $tree->$method($size) };
        }
        ok(!$@, "$method is not ok");
    }
}

done_testing;
use strict;
use warnings;
use Test::More tests => 6;
use JSON::Syck;

# Build a nested structure of given depth
sub make_nested {
    my $depth = shift;
    my $data = "leaf";
    for (1..$depth) { $data = [$data]; }
    return $data;
}

# 1. Normal structures work fine
{
    my $data = { a => [1, { b => [2, 3] }, "c"] };
    my $json = eval { JSON::Syck::Dump($data) };
    ok( !$@, "shallow structure dumps without error" );
    like( $json, qr/\{/, "produces valid JSON" );
}

# 2. Moderate nesting within default limit works
{
    my $data = make_nested(200);
    my $json = eval { JSON::Syck::Dump($data) };
    ok( !$@, "200-level nesting works with default MaxDepth" );
}

# 3. Deep nesting beyond default limit croaks cleanly
{
    my $data = make_nested(600);
    eval { JSON::Syck::Dump($data) };
    like( $@, qr/MaxDepth/, "600-level nesting croaks with MaxDepth message" );
}

# 4. Increasing MaxDepth allows deeper structures
{
    local $JSON::Syck::MaxDepth = 4096;
    my $data = make_nested(600);
    my $json = eval { JSON::Syck::Dump($data) };
    ok( !$@, "600-level nesting works with MaxDepth=4096" );
}

# 5. After croak, normal dumps still work
{
    my $data = make_nested(600);
    eval { JSON::Syck::Dump($data) };
    my $normal = eval { JSON::Syck::Dump({ hello => "world" }) };
    ok( !$@ && $normal, "emitter recovers after MaxDepth croak" );
}

use strict;
use warnings;
use Test::More tests => 7;
use YAML::Syck;

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
    my $yaml = eval { Dump($data) };
    ok( !$@, "shallow structure dumps without error" );
    like( $yaml, qr/---/, "produces valid YAML" );
}

# 2. Moderate nesting within default limit works
{
    my $data = make_nested(200);
    my $yaml = eval { Dump($data) };
    ok( !$@, "200-level nesting works with default MaxDepth" );
}

# 3. Deep nesting beyond default limit croaks cleanly
{
    my $data = make_nested(600);
    eval { Dump($data) };
    like( $@, qr/MaxDepth/, "600-level nesting croaks with MaxDepth message" );
}

# 4. Increasing MaxDepth allows deeper structures
{
    local $YAML::Syck::MaxDepth = 4096;
    my $data = make_nested(600);
    my $yaml = eval { Dump($data) };
    ok( !$@, "600-level nesting works with MaxDepth=4096" );
}

# 5. MaxDepth croak is catchable (eval traps it)
{
    my $data = make_nested(600);
    eval { Dump($data) };
    ok( $@, "croak is catchable with eval" );
}

# 6. After croak, normal dumps still work
{
    my $data = make_nested(600);
    eval { Dump($data) };
    my $normal = eval { Dump({ hello => "world" }) };
    ok( !$@ && $normal, "emitter recovers after MaxDepth croak" );
}

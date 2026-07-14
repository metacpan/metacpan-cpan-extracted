use strict;
use warnings;
use Test::More;
use JSON::Syck;

# Build a nested Perl structure of given depth
sub make_nested {
    my $depth = shift;
    my $data = "leaf";
    for (1..$depth) { $data = [$data]; }
    return $data;
}

# Build a nested JSON string of given depth
sub make_nested_json {
    my $depth = shift;
    my $json = '{"leaf":"value"}';
    for my $i (1..$depth) {
        $json = '{"l' . $i . '":' . $json . '}';
    }
    return $json;
}

# === Dump-side MaxDepth ===

# 1. Normal structures work fine
{
    my $data = { a => [1, { b => [2, 3] }, "c"] };
    my $json = eval { JSON::Syck::Dump($data) };
    ok( !$@, "Dump: shallow structure dumps without error" );
    like( $json, qr/\{/, "Dump: produces valid JSON" );
}

# 2. Moderate nesting within default limit works
{
    my $data = make_nested(200);
    my $json = eval { JSON::Syck::Dump($data) };
    ok( !$@, "Dump: 200-level nesting works with default MaxDepth" );
}

# 3. Deep nesting beyond default limit croaks cleanly
{
    my $data = make_nested(600);
    eval { JSON::Syck::Dump($data) };
    like( $@, qr/MaxDepth/, "Dump: 600-level nesting croaks with MaxDepth message" );
}

# 4. Increasing MaxDepth allows deeper structures
{
    local $JSON::Syck::MaxDepth = 4096;
    my $data = make_nested(600);
    my $json = eval { JSON::Syck::Dump($data) };
    ok( !$@, "Dump: 600-level nesting works with MaxDepth=4096" );
}

# 5. After croak, normal dumps still work
{
    my $data = make_nested(600);
    eval { JSON::Syck::Dump($data) };
    my $normal = eval { JSON::Syck::Dump({ hello => "world" }) };
    ok( !$@ && $normal, "Dump: emitter recovers after MaxDepth croak" );
}

# === Load-side MaxDepth ===

# 6. Moderate JSON nesting within default limit works
{
    my $json = make_nested_json(50);
    my $data = eval { JSON::Syck::Load($json) };
    ok( !$@, "Load: 50-level nesting works with default MaxDepth" );
}

# 7. Deep JSON beyond default limit croaks
{
    my $json = make_nested_json(600);
    eval { JSON::Syck::Load($json) };
    like( $@, qr/nested too deeply/,
        "Load: 600-level JSON nesting croaks" );
}

# 8. Custom MaxDepth on Load
{
    local $JSON::Syck::MaxDepth = 10;
    my $json_ok = make_nested_json(5);
    my $data = eval { JSON::Syck::Load($json_ok) };
    ok( !$@, "Load: 5-level nesting works with MaxDepth=10" );

    my $json_deep = make_nested_json(20);
    eval { JSON::Syck::Load($json_deep) };
    like( $@, qr/nested too deeply/,
        "Load: 20-level nesting croaks with MaxDepth=10" );
}

# 9. Increasing MaxDepth allows deeper Load
{
    local $JSON::Syck::MaxDepth = 4096;
    my $json = make_nested_json(600);
    my $data = eval { JSON::Syck::Load($json) };
    ok( !$@, "Load: 600-level nesting works with MaxDepth=4096" );
}

# 10. Parser recovers after MaxDepth croak
{
    local $JSON::Syck::MaxDepth = 5;
    eval { JSON::Syck::Load(make_nested_json(20)) };
    my $data = eval { JSON::Syck::Load('{"hello":"world"}') };
    ok( !$@ && ref($data) eq 'HASH' && $data->{hello} eq 'world',
        "Load: parser recovers after MaxDepth croak" );
}

done_testing();

use strict;
use warnings;
use Test::More;
use YAML::Syck;

# Build a nested Perl structure of given depth
sub make_nested {
    my $depth = shift;
    my $data = "leaf";
    for (1..$depth) { $data = [$data]; }
    return $data;
}

# Build a nested YAML string of given depth (block-style mappings)
sub make_nested_yaml {
    my $depth = shift;
    my $yaml = "---\n";
    for my $i (0..$depth-1) {
        $yaml .= ("  " x $i) . "l$i:\n";
    }
    $yaml .= ("  " x $depth) . "leaf: value\n";
    return $yaml;
}

# === Dump-side MaxDepth ===

# 1. Normal structures work fine
{
    my $data = { a => [1, { b => [2, 3] }, "c"] };
    my $yaml = eval { Dump($data) };
    ok( !$@, "Dump: shallow structure dumps without error" );
    like( $yaml, qr/---/, "Dump: produces valid YAML" );
}

# 2. Moderate nesting within default limit works
{
    my $data = make_nested(200);
    my $yaml = eval { Dump($data) };
    ok( !$@, "Dump: 200-level nesting works with default MaxDepth" );
}

# 3. Deep nesting beyond default limit croaks cleanly
{
    my $data = make_nested(600);
    eval { Dump($data) };
    like( $@, qr/MaxDepth/, "Dump: 600-level nesting croaks with MaxDepth message" );
}

# 4. Increasing MaxDepth allows deeper structures
{
    local $YAML::Syck::MaxDepth = 4096;
    my $data = make_nested(600);
    my $yaml = eval { Dump($data) };
    ok( !$@, "Dump: 600-level nesting works with MaxDepth=4096" );
}

# 5. MaxDepth croak is catchable (eval traps it)
{
    my $data = make_nested(600);
    eval { Dump($data) };
    ok( $@, "Dump: croak is catchable with eval" );
}

# 6. After croak, normal dumps still work
{
    my $data = make_nested(600);
    eval { Dump($data) };
    my $normal = eval { Dump({ hello => "world" }) };
    ok( !$@ && $normal, "Dump: emitter recovers after MaxDepth croak" );
}

# === Load-side MaxDepth ===

# 7. Moderate nesting within default limit works
{
    my $yaml = make_nested_yaml(50);
    my $data = eval { Load($yaml) };
    ok( !$@, "Load: 50-level nesting works with default MaxDepth" );
    my $node = $data;
    for my $i (0..49) { $node = $node->{"l$i"}; }
    is( $node->{leaf}, 'value',
        "Load: deeply nested value is correct" );
}

# 8. Deep YAML beyond default limit croaks
{
    my $yaml = make_nested_yaml(600);
    eval { Load($yaml) };
    like( $@, qr/nested too deeply/,
        "Load: 600-level nesting croaks with depth message" );
}

# 9. Custom MaxDepth on Load
{
    local $YAML::Syck::MaxDepth = 10;
    my $yaml_shallow = make_nested_yaml(5);
    my $data = eval { Load($yaml_shallow) };
    ok( !$@, "Load: 5-level nesting works with MaxDepth=10" );

    my $yaml_deep = make_nested_yaml(20);
    eval { Load($yaml_deep) };
    like( $@, qr/nested too deeply/,
        "Load: 20-level nesting croaks with MaxDepth=10" );
}

# 10. Increasing MaxDepth allows deeper Load
{
    local $YAML::Syck::MaxDepth = 4096;
    my $yaml = make_nested_yaml(600);
    my $data = eval { Load($yaml) };
    ok( !$@, "Load: 600-level nesting works with MaxDepth=4096" );
}

# 11. Load croak is catchable
{
    local $YAML::Syck::MaxDepth = 5;
    my $yaml = make_nested_yaml(20);
    eval { Load($yaml) };
    ok( $@, "Load: croak is catchable with eval" );
}

# 12. Parser recovers after MaxDepth croak
{
    local $YAML::Syck::MaxDepth = 5;
    my $yaml_deep = make_nested_yaml(20);
    eval { Load($yaml_deep) };

    my $yaml_ok = "---\nhello: world\n";
    my $data = eval { Load($yaml_ok) };
    ok( !$@ && ref($data) eq 'HASH' && $data->{hello} eq 'world',
        "Load: parser recovers after MaxDepth croak" );
}

# 13. Flow collections also respect MaxDepth
{
    local $YAML::Syck::MaxDepth = 5;
    my $yaml = "---\na: {b: {c: {d: {e: {f: {g: deep}}}}}}\n";
    eval { Load($yaml) };
    like( $@, qr/nested too deeply/,
        "Load: deeply nested flow mapping respects MaxDepth" );
}

done_testing();

use strict;
use warnings;
use Test::More;
use Text::KDL::XS qw(parse_kdl emit_kdl);

# Top-level hashref: each key becomes a node, sorted for determinism.
{
    my $kdl = emit_kdl({
        package => 'kdl-rs',
        version => '1.0',
    });
    my $doc = parse_kdl($kdl);
    is scalar(@{ $doc->nodes }), 2, 'two top-level nodes';
    is $doc->nodes->[0]->name, 'package', 'first node (sorted)';
    is $doc->nodes->[0]->args->[0]->as_string, 'kdl-rs', 'first arg';
    is $doc->nodes->[1]->name, 'version', 'second node';
}

# Nested hashref becomes children block.
{
    my $kdl = emit_kdl({
        meta => {
            license => 'MIT',
            year    => 2026,
        },
    });
    my $doc = parse_kdl($kdl);
    is $doc->nodes->[0]->name, 'meta', 'parent';
    my @kids = @{ $doc->nodes->[0]->children };
    is scalar(@kids), 2, 'two children';
    is $kids[0]->name, 'license', 'child name';
    is $kids[0]->args->[0]->as_string, 'MIT', 'child arg';
    is $kids[1]->args->[0]->as_perl, 2026, 'numeric child arg';
}

# Arrayref of scalars becomes args of the parent node.
{
    my $kdl = emit_kdl({ authors => [ 'Kat', 'Donovan', 'Sam' ] });
    my $doc = parse_kdl($kdl);
    my $n = $doc->nodes->[0];
    is $n->name, 'authors', 'name';
    is scalar(@{ $n->args }), 3, 'three args';
    is $n->args->[1]->as_string, 'Donovan', 'second arg';
}

# Empty arrayref -> bare node, no args.
{
    my $kdl = emit_kdl({ tags => [] });
    my $doc = parse_kdl($kdl);
    is $doc->nodes->[0]->name, 'tags', 'bare node name';
    is scalar(@{ $doc->nodes->[0]->args }),  0, 'no args';
    is scalar(@{ $doc->nodes->[0]->children }), 0, 'no children';
}

# Arrayref of hashrefs -> repeated sibling nodes with the same name.
{
    my $kdl = emit_kdl({
        author => [
            { name => 'Kat', email => 'kat@example.com' },
            { name => 'Sam' },
        ],
    });
    my $doc = parse_kdl($kdl);
    my @authors = grep { $_->name eq 'author' } @{ $doc->nodes };
    is scalar(@authors), 2, 'two sibling author nodes';

    my @first_kids = @{ $authors[0]->children };
    is scalar(@first_kids), 2, 'first author has two children';
    my %h = map { $_->name => $_->args->[0]->as_string } @first_kids;
    is $h{name},  'Kat',             'first author name';
    is $h{email}, 'kat@example.com', 'first author email';
    is scalar(@{ $authors[1]->children }), 1, 'second author has one child';
}

# Top-level arrayref -> series of anonymous "-" nodes.
{
    my $kdl = emit_kdl([ 'apple', 'banana', 'cherry' ]);
    my $doc = parse_kdl($kdl);
    is scalar(@{ $doc->nodes }), 3, 'three top-level nodes';
    is $doc->nodes->[0]->name, '-', 'anonymous "-" name';
    is $doc->nodes->[2]->args->[0]->as_string, 'cherry', 'last value';
}

# Top-level arrayref of hashrefs -> "-" nodes with children.
{
    my $kdl = emit_kdl([
        { id => 1, label => 'one' },
        { id => 2, label => 'two' },
    ]);
    my $doc = parse_kdl($kdl);
    is scalar(@{ $doc->nodes }), 2, 'two anonymous nodes';
    my %k = map { $_->name => $_->args->[0]->as_string } @{ $doc->nodes->[0]->children };
    is $k{label}, 'one', 'first node label';
}

# undef -> #null, plain integer/float/string preservation.
{
    my $kdl = emit_kdl({
        i => 42,
        f => 3.14,
        s => 'hello',
        n => undef,
    });
    my $doc = parse_kdl($kdl, version => '2');
    my %by = map { $_->name => $_->args->[0] } @{ $doc->nodes };
    is $by{i}->as_perl, 42, 'integer round-trips';
    cmp_ok abs($by{f}->as_perl - 3.14), '<', 1e-9, 'float round-trips';
    is $by{s}->as_string, 'hello', 'string round-trips';
    ok $by{n}->is_null, 'undef -> null';
}

# JSON::PP::Boolean coercion -> KDL bool.
SKIP: {
    eval { require JSON::PP; 1 } or skip 'JSON::PP not available', 2;
    my $kdl = emit_kdl({ on => JSON::PP::true(), off => JSON::PP::false() }, version => '2');
    my $doc = parse_kdl($kdl, version => '2');
    my %by = map { $_->name => $_->args->[0] } @{ $doc->nodes };
    ok $by{on}->is_bool && $by{on}->as_perl,  'true bool';
    ok $by{off}->is_bool && !$by{off}->as_perl, 'false bool';
}

# Round-trip: data -> KDL -> as_data sanity (note: data-mode loses array
# vs single-arg distinction, so we re-parse and inspect structure).
{
    my $data = {
        package => 'app',
        deps => [
            { name => 'foo', version => '1.0' },
            { name => 'bar', version => '2.0' },
        ],
    };
    my $kdl = emit_kdl($data);
    my $doc = parse_kdl($kdl);
    is scalar(grep { $_->name eq 'deps' } @{ $doc->nodes }), 2,
        'two deps siblings after round-trip';
    is scalar(grep { $_->name eq 'package' } @{ $doc->nodes }), 1,
        'one package node';
}

# Tree-mode is still reachable via blessed objects.
{
    my $doc = parse_kdl("hello world\n");
    isa_ok $doc, 'Text::KDL::XS::Document';
    my $kdl = emit_kdl($doc);
    like $kdl, qr/hello/, 'Document round-trips through tree mode';
}

# Refusing nonsense: code refs are not serializable.
{
    eval { emit_kdl({ bad => sub { 1 } }) };
    ok $@, 'CODE ref rejected';
    like $@, qr/cannot serialize/, 'with descriptive error';
}

done_testing;

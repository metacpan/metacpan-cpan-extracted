use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use Text::KDL::XS qw(parse_kdl emit_kdl);

sub dies_like (&$$) {
    my ($code, $pattern, $name) = @_;
    my $lived = eval { $code->(); 1 };
    ok !$lived && $@ =~ $pattern, $name or diag $lived ? 'did not die' : $@;
}
# A source callback that hands out the bytes one at a time.
sub byte_source {
    my @bytes = split //, $_[0];
    return sub { shift @bytes };
}

my $e_acute = "\x{e9}";
my $check   = "\x{2713}";

# String sources are character strings.
{
    my $node = parse_kdl("(t$check)caf$e_acute k$check=(u$e_acute)\"v$check\" \"$e_acute\"\n")->nodes->[0];
    is $node->name,            "caf$e_acute", 'node name';
    is $node->type_annotation, "t$check",     'node type annotation';
    is $node->props->[0][0],   "k$check",     'property key';
    is $node->prop("k$check")->value,           "v$check", 'property value';
    is $node->prop("k$check")->type_annotation, "u$e_acute", 'value type annotation';
    is $node->args->[0]->value, $e_acute, 'argument';
}
is parse_kdl("caf\xc3\xa9 1\n")->nodes->[0]->name, "caf\x{c3}\x{a9}", 'a UTF-8 byte string is read as its characters';
{
    my $data = { "caf$e_acute" => [ $check, { "k$e_acute" => "\x{1F600}" } ] };
    is_deeply parse_kdl(emit_kdl($data))->as_data, [
        { name => "caf$e_acute", type => undef, args => [$check], props => {}, children => [] },
        { name => "caf$e_acute", type => undef, args => [], props => {}, children => [
            { name => "k$e_acute", type => undef, args => ["\x{1F600}"], props => {}, children => [] },
        ] },
    ], 'parse_kdl(emit_kdl(...)) round-trips non-ASCII text';
    is parse_kdl(emit_kdl({ n => "caf$e_acute $check" }))->nodes->[0]->args->[0]->value, "caf$e_acute $check",
        'emitted text parses back to the same characters';
}
{
    my ($fh, $path) = tempfile(UNLINK => 1);
    binmode $fh;
    print $fh "caf\xc3\xa9 \"\xe2\x9c\x93\"\n";
    close $fh;
    open my $in, '<:encoding(UTF-8)', $path or die "open: $!";
    my $decoded = do { local $/; <$in> };
    is parse_kdl($decoded)->nodes->[0]->args->[0]->value, $check, 'decoded file content';
}

# Callback sources deliver UTF-8 bytes; a character may span chunks.
is parse_kdl(byte_source("caf\xc3\xa9 \"\xe2\x9c\x93 \xf0\x9f\x98\x80\"\n"))->nodes->[0]->args->[0]->value,
    "$check \x{1F600}", 'one-byte chunks that split characters';

# Input that is not UTF-8, or encodes a surrogate or a code point above
# U+10FFFF, is rejected in every version mode.
my %invalid = (
    'overlong slash'  => "\xC0\xAF",
    'overlong 3-byte' => "\xE0\x80\xAF",
    'surrogate'       => "\xED\xA0\x80",
    'above U+10FFFF'  => "\xF4\x90\x80\x80",
    'truncated'       => "\xE2\x9C",
);
for my $what (sort keys %invalid) {
    for my $version (qw(1 2 detect)) {
        dies_like { parse_kdl(byte_source("n \"a$invalid{$what}b\"\n"), version => $version) }
            qr/KDL parse error: input is not valid UTF-8/, "$what is rejected (version $version)";
    }
}
dies_like { parse_kdl(byte_source("n \"a\xE2\x9C")) } qr/input is not valid UTF-8/, 'input ending inside a character';
for my $version (qw(1 2 detect)) {
    dies_like { parse_kdl(qq{n "\\u{D800}"\n}, version => $version) } qr/KDL parse error/,
        "a surrogate escape is rejected (version $version)";
}
{
    no warnings 'surrogate';
    dies_like { parse_kdl("n \"\x{D800}\"\n") } qr/input is not valid UTF-8/, 'a surrogate in a character string source';
}

# The emitter rejects text that KDL cannot represent instead of writing "".
{
    no warnings qw(surrogate non_unicode);
    for my $bad ("\x{D800}", "\x{110000}") {
        my $label = sprintf 'U+%X', ord $bad;
        dies_like { emit_kdl({ $bad => 1 }) } qr/node name contains a surrogate or a code point above U\+10FFFF/,
            "$label as a node name";
        dies_like { emit_kdl({ n => $bad }) } qr/string value contains a surrogate/, "$label as a string value";
        dies_like { emit_kdl(Text::KDL::XS::Node->new(name => 'n', props => [ [ $bad => 1 ] ])) }
            qr/property key contains a surrogate/, "$label as a property key";
        dies_like { emit_kdl(Text::KDL::XS::Node->new(name => 'n', type_annotation => $bad)) }
            qr/type annotation contains a surrogate/, "$label as a type annotation";
    }
}
ok utf8::valid(emit_kdl({ "caf$e_acute" => [ $check, "\x{1F600}" ] })), 'emitted text is valid UTF-8';

done_testing;

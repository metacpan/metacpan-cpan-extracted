use strict;
use warnings;
use Test::More;
use Text::KDL::XS qw(parse_kdl emit_kdl);

sub dies_like (&$$) {
    my ($code, $pattern, $name) = @_;
    my $lived = eval { $code->(); 1 };
    ok !$lived && $@ =~ $pattern, $name or diag $lived ? 'did not die' : $@;
}

my $nested = { a => { b => 1 } };

# Options are validated.
for my $indent (-1, 65, 'abc', 2.5, '') {
    dies_like { emit_kdl($nested, indent => $indent) } qr/indent must be an integer from 0 to 64/,
        "indent '$indent' dies";
}
for my $escape_mode (0x80, 0xFFFF, '0x20', -1) {
    dies_like { emit_kdl($nested, escape_mode => $escape_mode) }
        qr/escape_mode must be a combination of 0x10, 0x20, 0x40 and 0x170/, "escape_mode '$escape_mode' dies";
}
for my $identifier_mode (3, -1, 'quote') {
    dies_like { emit_kdl($nested, identifier_mode => $identifier_mode) }
        qr/identifier_mode must be an integer from 0 to 2/, "identifier_mode '$identifier_mode' dies";
}
for my $version ('3', '2.0', '') {
    dies_like { emit_kdl($nested, version => $version) } qr/unknown version '\Q$version\E'/, "version '$version' dies";
}
dies_like { emit_kdl($nested, bogus => 1, indnet => 2) } qr/unknown options 'bogus', 'indnet'/, 'unknown options die';
dies_like { emit_kdl($nested, 'indent') } qr/odd number of arguments/, 'an odd option list dies';

# Accepted spellings and values.
is emit_kdl({ a => 1 }, version => $_), "a 1\n", "version '$_' is accepted" for qw(DETECT v1 V2 2);
is emit_kdl($nested, indent => 0), "a {\nb 1\n}\n", 'indent 0 writes no indentation';
is emit_kdl($nested, indent => 2), "a {\n  b 1\n}\n", 'indent 2';
is emit_kdl($nested, indent => undef), "a {\n    b 1\n}\n", 'an undef option means the default';
is emit_kdl({ s => "caf\x{e9}" }, escape_mode => 0x170), qq{s "caf\\u{e9}"\n}, 'escape_mode 0x170 writes ASCII only';

# KDL v2 does not allow a literal newline in a quoted string, so v2 output
# always escapes it; v1 output follows escape_mode.
{
    my $v2 = emit_kdl({ s => "a\nb" }, escape_mode => 0);
    is $v2, qq{s "a\\nb"\n}, 'v2 output escapes newlines even with escape_mode 0';
    is parse_kdl($v2, version => 2)->nodes->[0]->args->[0]->value, "a\nb", 'and parses as KDL v2';
    is emit_kdl({ s => "a\nb" }, escape_mode => 0, version => 1), qq{s "a\nb"\n}, 'v1 output keeps the literal newline';
}

# An empty document is a single newline.
is emit_kdl({}), "\n", 'an empty hash emits a newline';
is emit_kdl(Text::KDL::XS::Document->new), "\n", 'an empty document emits a newline';

done_testing;

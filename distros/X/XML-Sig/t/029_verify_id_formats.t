use Test::Lib;
use Test::XML::Sig;
use Test::Exception;
use utf8;  # so literal Unicode characters in this source file are decoded
use Encode qw(encode_utf8);

my $sig = XML::Sig->new(
    { x509 => 1, key => 't/ecdsa.private.pem', cert => 't/ecdsa.public.pem' });
isa_ok( $sig, 'XML::Sig' );

throws_ok(sub { $sig->sign('<foo ID="123"></foo>') },
    qr/XML ID format is invalid/,
    'ID cannot begin with a number');

throws_ok(sub { $sig->sign('<foo ID="123_foo"></foo>') },
    qr/XML ID format is invalid/,
    'ID cannot begin with a number');

my @invalid = qw/ ! $ % ^ " ( ) * + \/ : ; = > ? @ [ \ ] ^ `` { | } ~/;

foreach my $char (@invalid) {
    throws_ok(sub { $sig->sign("<foo ID=\'123$char\'></foo>") },
        qr/XML ID format is invalid/,
        "ID cannot contain a '$char'");
}

throws_ok(sub { $sig->sign('<foo ID="123#foo<foo"></foo>') },
    qr/unable to parse xml with XML::LibXML/,
    'ID cannot contain a "#"');

throws_ok(sub { $sig->sign('<foo ID="123\'foo<foo"></foo>') },
    qr/unable to parse xml with XML::LibXML/,
    'ID cannot contain a "<"');

throws_ok(sub { $sig->sign('<foo ID="123&foo"></foo>') },
    qr/unable to parse xml with XML::LibXML/,
    'ID cannot contain a "&"');

throws_ok(sub { $sig->sign('<foo ID="123<foo"></foo>') },
    qr/unable to parse xml with XML::LibXML/,
    'ID cannot contain a "<"');

throws_ok(sub { $sig->sign('<foo ID=":123"></foo>') },
    qr/XML ID format is invalid/,
    'ID cannot begin with a colon');

throws_ok(sub { $sig->sign('<foo ID="123,foo"></foo>') },
    qr/XML ID format is invalid/,
    'ID cannot contain a ","');

lives_ok(sub { $sig->sign('<foo ID="_123"></foo>') },
    'ID can begin with an underscore');

lives_ok(sub { $sig->sign('<foo ID="a_123"></foo>') },
    'ID can begin with a lowercase letter');

lives_ok(sub { $sig->sign('<foo ID="Z_123"></foo>') },
    'ID can begin with a uppercase letter');

lives_ok(sub { $sig->sign('<foo ID="Z_123.abYZ-xor"></foo>') },
    'ID can contain "-" and "." characters');

throws_ok(sub { $sig->sign('<foo ID="Z_123~abYZ-xor"></foo>') },
    qr/XML ID format is invalid/,
    'ID cannot contain "~" characters');

throws_ok(sub { $sig->sign('<foo ID="Z_123$-bYZ-xor"></foo>') },
    qr/XML ID format is invalid/,
    'ID cannot contain "$" characters');

# --- Unicode that should be accepted ---

lives_ok (sub { $sig->sign(encode_utf8('<foo ID="café_id"></foo>')) },
    'ID can contain accented Latin (Latin-1 supplement)');

lives_ok (sub { $sig->sign(encode_utf8('<foo ID="ñoño"></foo>')) },
    'ID can begin with an accented Latin character');


lives_ok (sub { $sig->sign(encode_utf8('<foo ID="Москва_42"></foo>')) },
    'ID can contain Cyrillic characters');

lives_ok (sub { $sig->sign(encode_utf8('<foo ID="α_β_γ"></foo>')) },
    'ID can contain Greek characters');

lives_ok (sub { $sig->sign(encode_utf8('<foo ID="日本語_id"></foo>')) },
    'ID can contain CJK characters');

# Combining diacritic (NameChar but NOT NameStartChar) used in middle position
lives_ok (sub { $sig->sign(encode_utf8("<foo ID=\"a\x{0301}foo\"></foo>")) },
    'ID can contain a combining diacritic after a start char');

# Middle dot (\xB7) is NameChar only
lives_ok (sub { $sig->sign(encode_utf8("<foo ID=\"l\x{B7}l\"></foo>")) },
    'ID can contain middle dot in non-start position');

# --- Unicode that should be rejected ---
# Combining diacritic at the start is NameChar but not NameStartChar
throws_ok(sub { $sig->sign(encode_utf8("<foo ID=\"\x{0301}foo\"></foo>")) },
    qr/XML ID format is invalid/,
    'ID cannot begin with a combining diacritic');

# Middle dot at the start is NameChar but not NameStartChar
throws_ok(sub { $sig->sign(encode_utf8("<foo ID=\"\x{B7}foo\"></foo>")) },
    qr/XML ID format is invalid/,
    'ID cannot begin with middle dot');

# Colon is excluded from NCName entirely
throws_ok(sub { $sig->sign(encode_utf8('<foo ID="foo:bar"></foo>')) },
    qr/XML ID format is invalid/,
    'ID cannot contain colon (excluded from NCName)');

# A character that's in no NCName production at all (em dash)
throws_ok(sub { $sig->sign(encode_utf8("<foo ID=\"foo\x{2014}bar\"></foo>")) },
    qr/XML ID format is invalid/,
    'ID cannot contain em dash');

# A character that's in no NCName production at all (a Greek Question Mark)
throws_ok(sub { $sig->sign(encode_utf8("<foo ID=\"foo\x{037E}bar\"></foo>")) },
    qr/XML ID format is invalid/,
    'ID cannot contain a Greek Question Mark');
done_testing();


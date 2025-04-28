use strict;
use warnings;
use Test::More;
use gb64 qw(enc_b64 dec_b64);

# Gebruik MIME::Base64 als referentie-implementatie
use MIME::Base64 qw(encode_base64 decode_base64);

# Test functional interface
subtest 'Functional interface' => sub {
    my @tests = (
        [ "", "Empty string" ],
        [ "f", "Single character" ],
        [ "fo", "Two characters" ],
        [ "foo", "Three characters" ],
        [ "foobar", "Six characters" ],
        [ "Hello World", "Hello World" ],
    );

    for my $test (@tests) {
        my ($input, $desc) = @$test;
        # Gebruik MIME::Base64 voor de verwachte waarden
        my $expected_encoded = encode_base64($input, ''); # Geen newline
        my $expected_decoded = decode_base64($expected_encoded);

        is(enc_b64($input), $expected_encoded, "Encode: $desc");
        is(dec_b64($expected_encoded), $expected_decoded, "Decode: $desc");
    }
};

# Test streaming interface
subtest 'Streaming interface' => sub {
    my $gb64 = gb64->new;
    is($gb64->encode, encode_base64("", ''), "Empty encode");
    is($gb64->decode(""), decode_base64(""), "Empty decode");

    $gb64->add("f");
    is($gb64->encode, encode_base64("f", ''), "Single character encode");
    $gb64 = gb64->new;
    $gb64->add(encode_base64("f", ''));
    is($gb64->decode(), decode_base64(encode_base64("f", '')), "Single character decode");

    $gb64 = gb64->new;
    $gb64->add("fo");
    is($gb64->encode, encode_base64("fo", ''), "Two characters encode");
    $gb64 = gb64->new;
    $gb64->add(encode_base64("fo", ''));
    is($gb64->decode, decode_base64(encode_base64("fo", '')), "Two characters decode");

    $gb64 = gb64->new;
    $gb64->add("foo");
    $gb64->add("bar");
    is($gb64->encode, encode_base64("foobar", ''), "Chunked six characters encode");
    $gb64 = gb64->new;
    $gb64->add(encode_base64("foobar", ''));
    is($gb64->decode, decode_base64(encode_base64("foobar", '')), "Chunked six characters decode");
};

# Test error handling
subtest 'Error handling' => sub {
    is(enc_b64(undef), encode_base64("", ''), "enc_b64 undef input");
    is(dec_b64(undef), decode_base64(""), "dec_b64 undef input");
    my $gb64 = gb64->new;
    eval { $gb64->add(undef); };
    like($@, qr/Input must be defined/, "Streaming add undef input");
    eval { dec_b64("###"); };
    like($@, qr/Invalid Base64 length/, "dec_b64 invalid length throws error");
    eval { dec_b64("Z@=="); };
    like($@, qr/Invalid Base64 character/, "dec_b64 invalid characters throws error");
};

done_testing();
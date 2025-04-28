use strict;
use warnings;
use Test::More;
use gmd5 qw(md5 md5_hex);
use Digest::MD5;

# Note: This test compares gmd5 output against Digest::MD5 to ensure compatibility.

# Test functional interface
subtest 'Functional interface' => sub {
    my @inputs = (
        ["", "Empty string"],
        ["a", "Single character"],
        ["abc", "Standard test vector"],
        ["message digest", "Message digest"],
        ["The quick brown fox jumps over the lazy dog", "Fox string"],
    );

    for my $input (@inputs) {
        my ($data, $desc) = @$input;
        my $expected = Digest::MD5::md5_hex($data);
        my $got = md5_hex($data);
        is($got, $expected, $desc);
    }

    my $binary = md5("abc");
    my $expected_binary = Digest::MD5::md5("abc");
    is(unpack("H*", $binary), unpack("H*", $expected_binary), "Binary output");
};

# Test streaming interface
subtest 'Streaming interface' => sub {
    my $md5 = gmd5->new;
    is($md5->hexdigest, Digest::MD5::md5_hex(""), "Empty digest");

    $md5->add("a");
    is($md5->hexdigest, Digest::MD5::md5_hex("a"), "Single character");

    $md5->reset;
    $md5->add("ab");
    $md5->add("c");
    is($md5->hexdigest, Digest::MD5::md5_hex("abc"), "Chunked standard vector");

    $md5->reset;
    $md5->add("The quick brown fox ");
    $md5->add("jumps over the lazy dog");
    is($md5->hexdigest, Digest::MD5::md5_hex("The quick brown fox jumps over the lazy dog"), "Chunked fox string");
};

subtest 'Padding verification' => sub {
    my $md5 = gmd5->new;
    $md5->add("a" x 64);
    my $len_before = length($md5->{buffer});
    $md5->hexdigest; # Triggers padding
    my $len_after = length($md5->{buffer});
    ok($len_after % 64 == 0, "Padded buffer length is multiple of 64");
};

# Test edge cases
subtest 'Edge cases' => sub {
    my $md5 = gmd5->new;
    $md5->add("");
    is($md5->hexdigest, Digest::MD5::md5_hex(""), "Empty string addition");

    # 64-byte input
    $md5->reset;
    my $input_64 = "a" x 64;
    $md5->add($input_64);
    my $got_64 = $md5->hexdigest;
    my $expected_64 = Digest::MD5::md5_hex($input_64);
    is($got_64, $expected_64, "64-byte input");

    # 65-byte input
    $md5->reset;
    my $input_65 = "a" x 65;
    $md5->add($input_65);
    my $got_65 = $md5->hexdigest;
    my $expected_65 = Digest::MD5::md5_hex($input_65);
    is($got_65, $expected_65, "65-byte input");

    # Test multiple digest calls
    $md5->reset;
    $input_64 = "a" x 64;
    $md5->add($input_64);
    my $first_digest = $md5->hexdigest;
    is($first_digest, Digest::MD5::md5_hex($input_64), "First digest for 64-byte input");
    my $second_digest = $md5->hexdigest;
    is($second_digest, $first_digest, "Second digest matches first for 64-byte input");

    # Extra edge case: 56-byte input ("a" x 56)
    $md5->reset;
    my $input_56 = "a" x 56;
    $md5->add($input_56);
    is($md5->hexdigest, Digest::MD5::md5_hex($input_56), "56-byte input");

    # Extra edge case: 63-byte input ("a" x 63)
    $md5->reset;
    my $input_63 = "a" x 63;
    $md5->add($input_63);
    is($md5->hexdigest, Digest::MD5::md5_hex($input_63), "63-byte input");

    # Extra edge case: 128-byte input ("a" x 128)
    $md5->reset;
    my $input_128 = "a" x 128;
    $md5->add($input_128);
    is($md5->hexdigest, Digest::MD5::md5_hex($input_128), "128-byte input");

    # Extra edge case: 256-byte input ("a" x 256)
    $md5->reset;
    my $input_256 = "a" x 256;
    $md5->add($input_256);
    is($md5->hexdigest, Digest::MD5::md5_hex($input_256), "256-byte input");

    # Extra edge case: 64-byte null bytes ("\x00" x 64)
    $md5->reset;
    my $input_null = "\x00" x 64;
    $md5->add($input_null);
    is($md5->hexdigest, Digest::MD5::md5_hex($input_null), "64-byte null input");

    # Extra edge case: 64-byte "ab" pattern ("ab" x 32)
    $md5->reset;
    my $input_ab = "ab" x 32;
    $md5->add($input_ab);
    is($md5->hexdigest, Digest::MD5::md5_hex($input_ab), "64-byte ab pattern");

    # Extra edge case: 64-byte 0xFF input ("\xFF" x 64)
    $md5->reset;
    my $input_ff = "\xFF" x 64;
    $md5->add($input_ff);
    is($md5->hexdigest, Digest::MD5::md5_hex($input_ff), "64-byte 0xFF input");
};

# Test error handling
subtest 'Error handling' => sub {
    eval { md5(undef); };
    like($@, qr/Input must be defined/, "md5 undef input");

    eval { md5_hex(undef); };
    like($@, qr/Input must be defined/, "md5_hex undef input");

    my $md5 = gmd5->new;
    eval { $md5->add(undef); };
    like($@, qr/Input must be defined/, "Streaming undef input");
};

done_testing();

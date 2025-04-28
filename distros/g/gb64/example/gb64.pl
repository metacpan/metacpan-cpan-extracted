#!/usr/bin/perl
use strict;
use warnings;
use gb64 qw(enc_b64 dec_b64);

# Direct encoding/decoding
my $data = "Hello World";
my $encoded = enc_b64($data);
my $decoded = dec_b64($encoded);
print "Direct encoding: $data -> $encoded\n";
print "Direct decoding: $encoded -> $decoded\n";

# Streaming encoding/decoding
my $gb64 = gb64->new;
$gb64->add("Hello ");
$gb64->add("World");
$encoded = $gb64->encode;
$decoded = $gb64->decode($encoded);
print "Streaming encoding: $data -> $encoded\n";
print "Streaming decoding: $encoded -> $decoded\n";

# Encode/decode a file
if (@ARGV) {
    my $file = $ARGV[0];
    if (-f $file) {
        $gb64 = gb64->new;
        open my $fh, '<', $file or die "Cannot open $file: $!";
        while (my $chunk = <$fh>) {
            $gb64->add($chunk);
        }
        close $fh;
        $encoded = $gb64->encode;
        print "Base64 encoded file '$file': $encoded\n";
    } else {
        warn "File '$file' not found\n";
    }
}
#!/usr/bin/perl
use strict;
use warnings;
use gmd5 qw(md5_hex);

# Direct hash
my $data = "Hello World";
my $hex = md5_hex($data);
print "MD5 hash of '$data': $hex\n";

# Direct hash with md5 (binary)
my $binary = md5($data);
print "MD5 binary of '$data': ", unpack("H*", $binary), "\n";

# Streaming hash
my $md5 = gmd5->new;
$md5->add("Hello ");
$md5->add("World");
$hex = $md5->hexdigest;
print "Streaming MD5 hash of '$data': $hex\n";

# Reusing the object after reset
$md5->reset;
$md5->add("The quick brown fox jumps over the lazy dog");
$hex = $md5->hexdigest;
print "MD5 hex of fox string: $hex\n";

# Hash a file
if (@ARGV) {
    my $file = $ARGV[0];
    if (-f $file) {
        $md5->reset;
        open my $fh, '<', $file or die "Cannot open $file: $!";
        while (my $chunk = <$fh>) {
            $md5->add($chunk);
        }
        close $fh;
        $hex = $md5->hexdigest;
        print "MD5 hash of file '$file': $hex\n";
    } else {
        warn "File '$file' not found\n";
    }
}

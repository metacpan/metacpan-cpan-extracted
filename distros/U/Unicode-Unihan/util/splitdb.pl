#!/usr/local/bin/perl
use strict;

my %FH;
#U+3400  kCantonese      JAAU1 KAAU5
my $olduni;
while(<>){
    next if /^#/;
    chomp;
    my ($uni, $key, $value) = m/^U\+([0-9A-Za-z]+)\s+k(\w+)\s(.*)/o;
    $key ||= "COMMENT";
    $FH{$key} or open $FH{$key}, ">$key.txt" or die "$key.txt:$!";
    my $line = $uni ? "$uni\t$value" : $_;
    my $fh = $FH{$key};
    print $fh $line, "\n";
    if ($uni ne $olduni){
	warn "processing U+$uni\n";
	$olduni = $uni;
    }
}

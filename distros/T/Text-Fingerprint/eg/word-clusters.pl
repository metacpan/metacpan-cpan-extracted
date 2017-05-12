#!/usr/bin/env perl
use autodie;
use open OUT => q(:locale);
use strict;
use utf8;
use warnings qw(all);

use Text::Fingerprint qw(fingerprint_ngram);

my %clusters;
open my $fh, q(<:encoding(utf-8)), q(/usr/share/dict/words);
while (<$fh>) {
    chomp;
    ++$clusters{fingerprint_ngram($_)}->{$_};
}
close $fh;

while (my ($key, $cluster) = each %clusters) {
    next if 2 > keys %$cluster;
    my @word = sort keys %$cluster;

    local ($\, $,) = (qq(\n), q(, ));
    print @word;
}

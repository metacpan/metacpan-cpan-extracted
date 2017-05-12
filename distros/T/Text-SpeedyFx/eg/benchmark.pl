#!/usr/bin/env perl
use autodie;
use strict;
use utf8;
use warnings;

use Benchmark qw(cmpthese :hireswallclock);
use Digest::MurmurHash qw(murmur_hash);
use Text::SpeedyFx;

my $data = do {
    local $/ = undef;
    open my $fh, q(<:mmap), q(enwik8);
    <$fh>;
};

my $sfx_latin1  = Text::SpeedyFx->new(1, 8);
my $sfx         = Text::SpeedyFx->new(1);

cmpthese(10 => {
    hash            => sub { $sfx_latin1->hash($data) },
    hash_utf8       => sub { $sfx->hash($data) },
    hash_fv         => sub { $sfx_latin1->hash_fv($data, 1024 << 3) },
    hash_min        => sub { $sfx_latin1->hash_min($data) },
    hash_min_utf8   => sub { $sfx->hash_min($data) },
    murmur_utf8     => sub { tokenize($data) },
});

sub tokenize {
    my ($data) = @_;
    my $fv;

    ++$fv->{murmur_hash(lc $1)}
        while $data =~ /(\w+)/gx;

    return $fv;
}

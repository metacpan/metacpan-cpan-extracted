#!/usr/bin/env perl
use strict;
use warnings;

use Benchmark::Dumb ();
use File::Map ();
use Digest::MurmurHash ();
use Text::SpeedyFx ();

File::Map::map_file(my $data, q(enwik8));

my $sfx_latin1  = Text::SpeedyFx->new(1, 8);
my $sfx         = Text::SpeedyFx->new(1);

# seek ~0.5% precision
Benchmark::Dumb::cmpthese(0.005 => {
    hash            => sub { $sfx_latin1->hash($data) },
    hash_utf8       => sub { $sfx->hash($data) },
    hash_fv         => sub { $sfx_latin1->hash_fv($data, 1024 << 3) },
    hash_min        => sub { $sfx_latin1->hash_min($data) },
    hash_min_utf8   => sub { $sfx->hash_min($data) },
    murmur          => sub { tokenize($data) },
});

sub tokenize {
    my ($data) = @_;
    my $fv;

    ++$fv->{Digest::MurmurHash::murmur_hash(lc $1)}
        while $data =~ /(\w+)/gx;

    return $fv;
}

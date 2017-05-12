use strict;
use warnings;
use Path::Class qw/dir/;
use Test::More;
use WWW::KGS::GameArchives;

my @tests;
for my $dir ( dir('t/data')->children ) {
    next unless $dir->is_dir;
    push @tests, {
        name => $dir->basename,
        input => scalar $dir->file('input.html')->slurp(iomode=>'<:encoding(UTF-8)'),
        expected => do $dir->file('expected.pl'),
    };
}

plan tests => scalar @tests;

my $archives = WWW::KGS::GameArchives->new;

for my $test ( @tests ) {
    my $got = $archives->scrape( \$test->{input}, $archives->base_uri );
    is_deeply $got, $test->{expected}, $test->{name};
}

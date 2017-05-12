#!perl

use Test::More;
plan skip_all => 'POD tests are only run in RELEASE_TESTING mode.' unless $ENV{'RELEASE_TESTING'};

eval 'use Test::Pod 1.14';
plan skip_all => 'Test::Pod v1.14 required for testing POD' if $@;
eval 'use Pod::Simple';
plan skip_all => 'Pod::Simple v3.28 required for testing POD encoding' if $@;

for my $pod ( all_pod_files() ) {
    my $parser = Pod::Simple->new();
    $parser->parse_file($pod);
    next if !$parser->content_seen();

    my $enc = $parser->encoding();
    ok( defined $enc, "=encoding exists: $pod" ) && like( $enc, qr/^utf-?8$/i, "=encoding is utf8: $pod" );
}

done_testing;

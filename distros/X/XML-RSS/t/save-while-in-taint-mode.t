#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

use XML::RSS;

{
    my $rss = XML::RSS->new();
    $rss->parsefile(
        File::Spec->catfile(
            File::Spec->curdir(), "t", "data", "2.0", "sf-hs-with-pubDate.rss"
        )
    );

    my $target_fn =
        File::Spec->catfile(
            File::Spec->curdir(), "t", "data", "2.0", "sf-hs-temp.rss"
        )
        ;

    $rss->save($target_fn);

    # TEST
    ok(scalar(-e $target_fn), "Test that save was successful");

    unlink($target_fn);
}

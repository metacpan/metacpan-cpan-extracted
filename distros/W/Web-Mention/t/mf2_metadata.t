use warnings; use strict;
use Test::More;
use Test::Exception;
use FindBin;
use utf8;

use_ok ("Web::Mention");

my $metadata_source = 'file://' . "$FindBin::Bin/sources/explicit_metadata.html";
my $vanilla_source = 'file://' . "$FindBin::Bin/sources/valid.html";
my $target = "http://example.com/webmention-target";

{
    my $wm = Web::Mention->new(
        source => $metadata_source,
        target => $target,

    );

    is (
        $wm->original_source,
        'https://example.com/original-source',
        "Explicit original_source is correct."
    );

    is (
        $wm->time_published->ymd,
        '2019-06-22',
        "Explicit time_published is correct."
    );
}

{
    my $wm = Web::Mention->new(
        source => $vanilla_source,
        target => $target,

    );

    is (
        $wm->original_source,
        $vanilla_source,
        "Fallback original_source is correct."
    );

    is (
        $wm->time_published,
        $wm->time_received,
        "Fallback time_published is correct."
    );

}

done_testing();

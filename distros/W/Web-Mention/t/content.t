use warnings; use strict;
use Test::More;
use Test::Exception;
use FindBin;

use_ok ("Web::Mention");

my $valid_source = 'file://' . "$FindBin::Bin/sources/valid.html";
my $content_source = 'file://' . "$FindBin::Bin/sources/content_property.html";

my $target = "http://example.com/webmention-target";

{
    my $wm = Web::Mention->new(
        source => $valid_source,
        target => $target,
    );

    my $content = $wm->content;
    is( $content, 'This page mentions the target URL!', );
}

{
    my $wm = Web::Mention->new(
        source => $content_source,
        target => $target,
    );
    my $content = $wm->content;
    like( $content, qr/Hooray!/ );
}

done_testing();

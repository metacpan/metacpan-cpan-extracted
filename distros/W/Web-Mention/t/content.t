use warnings; use strict;
use Test::More;
use Test::Exception;
use FindBin;
use utf8;

use_ok ("Web::Mention");

my $valid_source = 'file://' . "$FindBin::Bin/sources/valid.html";
my $content_source = 'file://' . "$FindBin::Bin/sources/very_long_content_property.html";

my $target = "http://example.com/webmention-target";

{
    my $wm = Web::Mention->new(
        source => $valid_source,
        target => $target,

    );

    my $content = $wm->content;
    is( $content, 'This page mentions the target URL!', );
    is( $wm->title, 'This page mentions the target URL!' );
}

{
    my $wm = Web::Mention->new(
        source => $content_source,
        target => $target,
    );
    my $content = $wm->content;
    like( $content, qr/🤠 Howdy, I’m/ );
    unlike( $content, qr/Antwerp/ );

    is( $wm->title, 'This page uses MF2 to explicitly define some content.');
}

{
    my $wm = Web::Mention->new(
        source => 'file://' . "$FindBin::Bin/sources/long_content_and_short_summary.html",
        target => $target,
    );

    my $content = $wm->content;
    like( $content, qr/summary/ );
    like( $content, qr/Antwerp/ );
}

{
    my $old_value = Web::Mention->max_content_length;
    Web::Mention->max_content_length( 30 );
    my $wm = Web::Mention->new(
        source => 'file://' . "$FindBin::Bin/sources/long_content_and_short_summary.html",
        target => $target,
    );

    my $content = $wm->content;
    like( $content, qr/summary/ );
    unlike( $content, qr/Antwerp/ );
    Web::Mention->max_content_length( $old_value );
}

{
    my $old_value = Web::Mention->content_truncation_marker;
    Web::Mention->content_truncation_marker( '!!!' );
    my $wm = Web::Mention->new(
        source => $content_source,
        target => $target,
    );

    my $content = $wm->content;
    $content =~ /!!!$/;
    Web::Mention->content_truncation_marker( $old_value );
}

{
    my $wm = Web::Mention->new(
        source => 'file://' . "$FindBin::Bin/sources/long_content_and_long_summary.html",
        target => $target,
    );
    my $content = $wm->content;
    like( $content, qr/summary/ );
    unlike( $content, qr/Antwerp/ );
}

{
    my $wm = Web::Mention->new(
        source => 'file://' . "$FindBin::Bin/sources/explicit_name.html",
        target => $target,
    );
    my $content = $wm->content;
    like( $content, qr/At least I declare a name/ );
    unlike( $content, qr/Antwerp/ );

    is( $wm->title, 'At least I declare a name.');
}

{
    my $wm = Web::Mention->new(
        source => 'file://' . "$FindBin::Bin/sources/no_properties.html",
        target => $target,
    );
    my $content = $wm->content;
    like( $content, qr/Gosh/ );
}


done_testing();

#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;

use XML::RSS;

sub starts_with
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($rss, $prefix, $msg) = @_;

    my $rss_output = $rss->as_string();
    my $ok = is (
        substr($rss_output, 0, length($prefix)-1),
        substr($prefix, 0, length($prefix)-1),
        $msg
    );
}

sub create_rss_1
{
    my $args = shift;
    my @style =
        exists($args->{stylesheet}) ?
            (stylesheet => $args->{stylesheet}) :
            ()
            ;
    my $rss = XML::RSS->new(
        version => $args->{version},
        @style
    );
    my $image_link = exists($args->{image_link}) ? $args->{image_link} :
        "http://freshmeat.net/";

    my $extra_image_params = $args->{image_params} || [];

    $rss->channel(
        title => "freshmeat.net",
        link  => "http://freshmeat.net",
        description => "the one-stop-shop for all your Linux software needs",
        );

    $rss->image(
        title => "freshmeat.net",
        url   => "0",
        link  => $image_link,
        @{$extra_image_params},
        );

    $rss->add_item(
        title => "GTKeyboard 0.85",
        link  => "http://freshmeat.net/news/1999/06/21/930003829.html"
        );

    return $rss;
}

{
    # TEST
    starts_with(
        create_rss_1({'version' => "0.9"}),
        <<'EOF',
<?xml version="1.0" encoding="UTF-8"?>

<rdf:RDF
EOF
        "header of RSS 0.9 without the stylesheet"
    );
}

{
    # TEST
    starts_with(
        create_rss_1({'version' => "0.91"}),
        <<'EOF',
<?xml version="1.0" encoding="UTF-8"?>

<!DOCTYPE rss PUBLIC "-//Netscape Communications//DTD RSS 0.91//EN"
            "http://www.rssboard.org/rss-0.91.dtd">

<rss version="0.91">
EOF
        "header of RSS 0.9.1 without the stylesheet"
    );
}


{
    # TEST
    starts_with(
        create_rss_1({'version' => "1.0"}),
        <<'EOF',
<?xml version="1.0" encoding="UTF-8"?>

<rdf:RDF
EOF
        "header of RSS 1.0 without the stylesheet"
    );
}

{
    # TEST
    starts_with(
        create_rss_1({'version' => "2.0"}),
        <<'EOF',
<?xml version="1.0" encoding="UTF-8"?>

<rss version="2.0"
EOF
        "header of RSS 2.0 without the stylesheet"
    );
}

{
    # TEST
    starts_with(
        create_rss_1({'version' => "0.9", stylesheet => "http://myhost.tld/foo.xsl"}),
        <<'EOF',
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="http://myhost.tld/foo.xsl"?>

<rdf:RDF
EOF
        "header of RSS 0.9 with the stylesheet"
    );
}

{
    # TEST
    starts_with(
        create_rss_1({'version' => "0.91", stylesheet => "http://myhost.tld/foo.xsl"}),
        <<'EOF',
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="http://myhost.tld/foo.xsl"?>

<!DOCTYPE rss PUBLIC "-//Netscape Communications//DTD RSS 0.91//EN"
            "http://www.rssboard.org/rss-0.91.dtd">

<rss version="0.91">
EOF
        "header of RSS 0.9.1 with the stylesheet"
    );
}

{
    # TEST
    starts_with(
        create_rss_1({'version' => "1.0", stylesheet => "http://myhost.tld/foo.xsl"}),
        <<'EOF',
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="http://myhost.tld/foo.xsl"?>

<rdf:RDF
EOF
        "header of RSS 1.0 without the stylesheet"
    );
}

{
    # TEST
    starts_with(
        create_rss_1({'version' => "2.0", stylesheet => "http://myhost.tld/foo.xsl"}),
        <<'EOF',
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="http://myhost.tld/foo.xsl"?>

<rss version="2.0"
EOF
        "header of RSS 2.0 without the stylesheet"
    );
}

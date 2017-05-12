#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;

use XML::RSS::LibXML;

sub starts_with
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($rss, $pattern, $msg) = @_;
    
    my $rss_output = $rss->as_string();
    my $ok = like(
        $rss_output,
        $pattern,
        $msg
    );
}

sub create_rss_1
{
    my $args = shift;
    # my $rss = new XML::RSS::LibXML (version => '0.9');
    my @style =
        exists($args->{stylesheet}) ? 
            (stylesheet => $args->{stylesheet}) :
            ()
            ;
    my $rss = XML::RSS::LibXML->new(
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
        qr{^<\?xml version="1\.0" encoding="UTF-8"\?>\s*<rdf:RDF},
        "header of RSS 0.9 without the stylesheet"
    );
}

{
    # TEST
    starts_with(
        create_rss_1({'version' => "0.91"}),
        qr{^<\?xml version="1\.0" encoding="UTF-8"\?>\s*<!DOCTYPE rss PUBLIC "-//Netscape Communications//DTD RSS 0\.91//EN"\s+"http://my\.netscape\.com/publish/formats/rss-0\.91\.dtd">\s*<rss version="0\.91">},
        "header of RSS 0.91 without the stylesheet"
    );
}


{
    # TEST
    starts_with(
        create_rss_1({'version' => "1.0"}),
        qr{^<\?xml version="1\.0" encoding="UTF-8"\?>\s*<rdf:RDF},
        "header of RSS 1.0 without the stylesheet"
    );
}

{
    # TEST
    starts_with(
        create_rss_1({'version' => "2.0"}),
        qr{^<\?xml version="1\.0" encoding="UTF-8"\?>\s*<rss version="2\.0"},
        "header of RSS 2.0 without the stylesheet"
    );
}

{
    # TEST
    starts_with(
        create_rss_1({'version' => "0.9", stylesheet => "http://myhost.tld/foo.xsl"}),
        qr{^<\?xml version="1\.0" encoding="UTF-8"\?>\s*<\?xml-stylesheet (?:type="text/xsl"\s*|href="http://myhost\.tld/foo\.xsl"\s*){2}\?>\s*<rdf:RDF},
        "header of RSS 0.9 with the stylesheet"
    );
}

{
    # TEST
    starts_with(
        create_rss_1({'version' => "0.91", stylesheet => "http://myhost.tld/foo.xsl"}),
        qr{^<\?xml version="1\.0" encoding="UTF-8"\?>\s*<!DOCTYPE rss PUBLIC "-//Netscape Communications//DTD RSS 0\.91//EN"\s+"http://my\.netscape\.com/publish/formats/rss-0\.91\.dtd">\s*<\?xml-stylesheet (?:type="text/xsl"\s*|href="http://myhost\.tld/foo\.xsl"\s*){2}\?>\s*<rss version="0\.91">},
        "header of RSS 0.91 with the stylesheet"
    );
}

{
    # TEST
    starts_with(
        create_rss_1({'version' => "1.0", stylesheet => "http://myhost.tld/foo.xsl"}),
        qr{^<\?xml version="1\.0" encoding="UTF-8"\?>\s*<\?xml-stylesheet (?:type="text/xsl"\s*|href="http://myhost\.tld/foo\.xsl"\s*){2}\?>\s*<rdf:RDF},
        "header of RSS 1.0 without the stylesheet"
    );
}

{
    # TEST
    starts_with(
        create_rss_1({'version' => "2.0", stylesheet => "http://myhost.tld/foo.xsl"}),
        qr{^<\?xml version="1\.0" encoding="UTF-8"\?>\s*<\?xml-stylesheet (?:type="text/xsl"\s*|href="http://myhost\.tld/foo\.xsl"\s*){2}\?>\s*<rss version="2\.0"},
        "header of RSS 2.0 without the stylesheet"
    );
}

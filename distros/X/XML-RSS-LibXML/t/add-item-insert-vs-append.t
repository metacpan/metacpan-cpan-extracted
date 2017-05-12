#!/usr/bin/perl

# Test the add_item(mode => "insert")

use strict;
use warnings;

use Test::More tests => 3;

use XML::RSS::LibXML;

sub contains
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($rss, $pattern, $msg) = @_;
    my $rss_output = $rss->as_string();
    my $ok = like ($rss_output, $pattern, $msg);
    if (! $ok)
    {
        diag("Could not find the substring [$pattern] in:{{{{\n$rss_output\n}}}}\n");
    }
}

sub create_rss
{
    my $rss = XML::RSS::LibXML->new(version => "2.0");

    $rss->channel(
        title => "freshmeat.net",
        link  => "http://freshmeat.net",
        description => "the one-stop-shop for all your Linux software needs",
        );

    $rss->add_item(
        title => "GTKeyboard 0.85",
        link  => "http://freshmeat.net/news/1999/06/21/930003829.html"
        );
    
    return $rss;
}

{
    my $rss = create_rss();

    $rss->add_item(
        title => "gcc 10.0.10",
        link => "http://gcc-compiler.tld/",
    );

    # TEST
    contains($rss,
        qr{(?sm)<title>GTKeyboard 0.85</title>.+<title>gcc 10.0.10</title>},
        "Checking for second item after first item when add_item without mode."
    );
}

{
    my $rss = create_rss();

    $rss->add_item(
        mode => "append",
        title => "gcc 10.0.10",
        link => "http://gcc-compiler.tld/",
    );

    # TEST
    contains($rss,
        qr{(?sm)<title>GTKeyboard 0.85</title>.+<title>gcc 10.0.10</title>},
        "Checking for second item after first item when add_item with mode == append."
    );
}

{
    my $rss = create_rss();

    $rss->add_item(
        mode => "insert",
        title => "gcc 10.0.10",
        link => "http://gcc-compiler.tld/",
    );

    # TEST
    contains($rss,
        qr{(?sm)<title>gcc 10.0.10</title>.+<title>GTKeyboard 0.85</title>},
        "Checking for second item before first item when add_item with mode == insert."
    );
}



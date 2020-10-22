#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

use File::Temp qw( tempdir );
use File::Spec;

use XML::RSS;
use XML::LibXML;

use List::Util qw(first);

use lib './t/lib';

use SyndTempWrap (qw(dir $temp_dir common_fns atom_fn rss_fn));

my @cmd_line;

sub print_cmd_line
{
    open my $out_fh, ">", "file.bash";
    print {$out_fh} join( " ", map { qq{"$_"} } @cmd_line );
    close($out_fh);
}

{
    $temp_dir = tempdir( CLEANUP => 1 );
    @cmd_line = (
        $^X,
        "-MXML::Grammar::Fortune::Synd::App",
        "-e",
        "run()",
        "--",
        "--dir" => dir("t/data/fortune-synd-1"),
        qw(
            --xml-file irc-conversation-4-several-convos.xml
            --xml-file screenplay-fort-sample-1.xml
            ),
        @{ common_fns() },
        "--master-url" => "http://www.fortunes.tld/My-Fortunes/",
        "--title"      => "My Fortune Feeds",
        "--tagline"    => "My Fortune Feeds",
        "--author"     => "shlomif\@iglu.org.il (Shlomi Fish)",
    );

    # print_cmd_line();

    # TEST
    ok( !system(@cmd_line) );

    my $rss = XML::RSS->new( version => "2.0" );

    $rss->parsefile( rss_fn() );

    my $item =
        first { $_->{'title'} =~ m{The Only Language} } @{ $rss->{'items'} };

    # TEST
    ok( $item, "Item exists." );

    # TEST
    like(
        $item->{'content'}->{'encoded'},
qr{<table class="irc-conversation">\s*<tbody>\s*<tr class="saying">\s*<td class="who">}ms,
        "Contains the table tag."
    );

    # print $item;
}

{
    $temp_dir = tempdir( CLEANUP => 1 );

    my $rss_fn = rss_fn();

    @cmd_line = (
        $^X,
        "-MXML::Grammar::Fortune::Synd::App",
        "-e",
        "run()",
        "--",
        "--dir" => dir("t/data/fortune-synd-many-fortunes"),
        qw(
            --xml-file sharp-perl.xml
            ),
        @{ common_fns() },
        "--master-url" => "http://www.fortunes.tld/My-Fortunes/",
        "--title"      => "My Fortune Feeds",
        "--tagline"    => "My Fortune Feeds",
        "--author"     => "shlomif\@iglu.org.il (Shlomi Fish)",
    );

    # print_cmd_line();

    # TEST
    ok( !system(@cmd_line) );

    my $rss = XML::RSS->new( version => "2.0" );

    $rss->parsefile($rss_fn);

    my $count = @{ $rss->{'items'} };

    # TEST
    is( $count, 20, "There are exactly 20 items." );

    my $dom = XML::LibXML->load_xml( location => atom_fn() );
    my $xpc = XML::LibXML::XPathContext->new($dom);

    $xpc->registerNs( 'atom', "http://www.w3.org/2005/Atom" );

    # TEST
    is(
        $xpc->findvalue('//atom:feed/atom:id'),
        "http://www.fortunes.tld/My-Fortunes/fort.atom",
        "Feed ID is OK.",
    );
}

# $Id: synopsis.t 33 2007-03-14 03:06:58Z daisuke $
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

use strict;
use Test::More (tests => 14);

BEGIN {
    use_ok("XML::RSS::LibXML");
    use_ok("XML::RSS::LibXML::Namespaces", qw(NS_RSS10 NS_RSS20));
};

my $rss = new XML::RSS::LibXML (version => '1.0');
ok($rss->channel(
    title        => "freshmeat.net",
    link         => "http://freshmeat.net",
    description  => "the one-stop-shop for all your Linux software needs",
    dc => {
        date       => '2000-08-23T07:00+00:00',
        subject    => "Linux Software",
        creator    => 'scoop@freshmeat.net',
        publisher  => 'scoop@freshmeat.net',
        rights     => 'Copyright 1999, Freshmeat.net',
        language   => 'en-us',
    },
    syn => {
        updatePeriod     => "hourly",
        updateFrequency  => "1",
        updateBase       => "1901-01-01T00:00+00:00",
    },
    taxo => [
        'http://dmoz.org/Computers/Internet',
        'http://dmoz.org/Computers/PC'
    ]
), "channel() works");

ok($rss->image(
    title  => "freshmeat.net",
    url    => "http://freshmeat.net/images/fm.mini.jpg",
    link   => "http://freshmeat.net",
    dc => {
        creator  => "G. Raphics (graphics at freshmeat.net)",
    },
), "image() works");

ok($rss->add_item(
    title       => "GTKeyboard 0.85",
    link        => "http://freshmeat.net/news/1999/06/21/930003829.html",
    description => "GTKeyboard is a graphical keyboard that ...",
    dc => {
        subject  => "X11/Utilities",
        creator  => "David Allen (s2mdalle at titan.vcu.edu)",
    },
    taxo => [
        'http://dmoz.org/Computers/Internet',
        'http://dmoz.org/Computers/PC'
    ]
), "add_item() works");

ok($rss->textinput(
    title        => "quick finder",
    description  => "Use the text input below to search freshmeat",
    name         => "query",
    link         => "http://core.freshmeat.net/search.php3",
), "textinput() works");

ok($rss->add_module(prefix=>'my', uri=>'http://purl.org/my/rss/module/'), "add_module() works");

ok($rss->add_item(
    title       => "xIrc 2.4pre2",
    link        => "http://freshmeat.net/projects/xirc/",
    description => "xIrc is an X11-based IRC client which ...",
    my => {
        rating    => "A+",
        category  => "X11/IRC",
    },
), "add_item() with custom module");

reparse($rss);

undef $rss;
$rss = new XML::RSS::LibXML (version => '2.0');
ok($rss->channel(title          => 'freshmeat.net',
              link           => 'http://freshmeat.net',
              language       => 'en',
              description    => 'the one-stop-shop for all your Linux software needs',
# XXX - XML::RSS sourcode says it's not supported by RSS 2.0, but
# this still exists in the SYNOPSIS
#              rating         => '(PICS-1.1 "http://www.classify.org/safesurf/" 1 r (SS~~000 1))',
              copyright      => 'Copyright 1999, Freshmeat.net',
              pubDate        => 'Thu, 23 Aug 1999 07:00:00 GMT',
              lastBuildDate  => 'Thu, 23 Aug 1999 16:20:26 GMT',
              docs           => 'http://www.blahblah.org/fm.cdf',
              managingEditor => 'scoop@freshmeat.net',
              webMaster      => 'scoop@freshmeat.net'
              ), "channel() works");

ok($rss->image(title       => 'freshmeat.net',
            url         => 'http://freshmeat.net/images/fm.mini.jpg',
            link        => 'http://freshmeat.net',
            width       => 88,
            height      => 31,
            description => 'This is the Freshmeat image stupid'
            ), "image() works");

ok($rss->add_item(title => "GTKeyboard 0.85",
       # creates a guid field with permaLink=true
       permaLink  => "http://freshmeat.net/news/1999/06/21/930003829.html",
       # alternately creates a guid field with permaLink=false
       # guid     => "gtkeyboard-0.85

# It would be nice to test this, but overload makes it a bit of a problem
#       enclosure   => XML::RSS::LibXML::MagicElement->new(
#            attributes => {
#                url  => 'http://example.com/torrent',
#                type => "application/x-bittorrent"
#            }
#       ),
       description => 'blah blah'
), "add_item() works");

ok($rss->textinput(title => "quick finder",
                description => "Use the text input below to search freshmeat",
                name  => "query",
                link  => "http://core.freshmeat.net/search.php3"
                ), "textinput() works");

reparse($rss);

sub reparse
{
    my $rss1 = shift;
    my $rss2 = XML::RSS::LibXML->new();

# print STDERR $rss1->as_string;
    $rss2->parse($rss1->as_string());
    my $version = $rss2->{_internal}{version} || $rss2->{output};

    for (grep { /^_/ } (keys %{$rss}, keys %{$rss2})) {
        delete $rss1->{$_};
        delete $rss2->{$_};
    }
    # Also, do not compare $rss->{channel}{image}. It doesn't work when it's
    # generated via ->image(); Same for textinput
    for my $p (qw(image textinput textInput items)) {
        delete $rss1->{channel}{$p};
        delete $rss2->{channel}{$p};
    }

    if ($version eq '2.0') {
        delete $rss1->{items};
        delete $rss2->{items};
    }

    # XXX - Namespaces and modules don't necessarily work for our custom
    # rss20/rss10 namespaces
    delete $rss1->{modules}{&NS_RSS10};
    delete $rss1->{modules}{&NS_RSS20};
    delete $rss2->{modules}{&NS_RSS10};
    delete $rss2->{modules}{&NS_RSS20};
    delete $rss1->{namespaces}{rss10};
    delete $rss1->{namespaces}{rss20};
    delete $rss2->{namespaces}{rss10};
    delete $rss2->{namespaces}{rss20};
    
    # Also, #default namespaces don't count
    delete $rss1->{namespaces}{'#default'};
    delete $rss2->{namespaces}{'#default'};

    is_deeply($rss1, $rss2, "Reparsing produces same structure (RSS version = $version)");
}

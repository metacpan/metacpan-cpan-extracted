#!/usr/bin/perl

use strict;
use warnings;

use Test::More 
    tests => 502
;

use XML::RSS::LibXML;

sub contains
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($rss, $sub_string, $msg) = @_;
    my $rss_output = $rss->as_string();
    my $ok = ok (index ($rss_output,
        $sub_string) >= 0,
        $msg
    );
    if (! $ok)
    {
        diag("Could not find the substring [$sub_string] in:{{{{\n$rss_output\n}}}}\n");
    }
}

sub not_contains
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($rss, $sub_string, $msg) = @_;
    ok ((index ($rss->as_string(),
        $sub_string) < 0),
        $msg
    );
}

sub create_rss_1
{
    my $args = shift;

    my $extra_rss_args = $args->{rss_args} || [];
    # my $rss = new XML::RSS::LibXML (version => '0.9');
    my $rss = new XML::RSS::LibXML (version => $args->{version}, @$extra_rss_args);
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


sub create_no_image_rss
{
    my $args = shift;
    # my $rss = new XML::RSS::LibXML (version => '0.9');
    my $rss = new XML::RSS::LibXML (version => $args->{version});

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

sub create_item_with_0_rss
{
    my $args = shift;
    # my $rss = new XML::RSS::LibXML (version => '0.9');
    my $rss = new XML::RSS::LibXML (version => $args->{version});
    my $image_link = exists($args->{image_link}) ? $args->{image_link} : 
        "http://freshmeat.net/";

    my $extra_image_params = $args->{image_params} || [];
    my $extra_item_params = $args->{item_params} || [];

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
        title => "0",
        link  => "http://rss.mytld/",
        @{$extra_item_params},
        );

    return $rss;
}

sub create_textinput_with_0_rss
{
    my $args = shift;
    my $rss = new XML::RSS::LibXML (version => $args->{version});
    my $image_link = exists($args->{image_link}) ? $args->{image_link} : 
        "http://freshmeat.net/";

    my $extra_image_params = $args->{image_params} || [];
    my $extra_item_params = $args->{item_params} || [];
    my $extra_textinput_params = $args->{textinput_params} || [];

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
        title => "0",
        link  => "http://rss.mytld/",
        @{$extra_item_params},
        );

    $rss->textinput(
        (map { $_ => 0 } (qw(link title description name))),
        @{$extra_textinput_params},
    );

    return $rss;
}

sub create_channel_rss
{
    my $args = shift;
    # my $rss = new XML::RSS::LibXML (version => '0.9');
    my $rss = new XML::RSS::LibXML (version => $args->{version});

    my $extra_channel_params = $args->{channel_params} || [];
    my @build_date =
        ($args->{version} eq "2.0" && !$args->{omit_date}) ?
            (lastBuildDate => "Sat, 07 Sep 2002 09:42:31 GMT",) :
            ();

    $rss->channel(
        title => "freshmeat.net",
        link  => "http://freshmeat.net",
        description => "Linux software",
        @build_date,
        @{$extra_channel_params},
        );

    $rss->add_item(
        title => "GTKeyboard 0.85",
        link  => "http://freshmeat.net/news/1999/06/21/930003829.html"
        );

    return $rss;
}

sub create_skipHours_rss
{
    my $args = shift;
    # my $rss = new XML::RSS::LibXML (version => '0.9');
    my $rss = new XML::RSS::LibXML (version => $args->{version});

    my $extra_channel_params = $args->{channel_params} || [];
    my $extra_skipHours_params = $args->{skipHours_params} || [];
    my @build_date =
        ($args->{version} eq "2.0" && !$args->{omit_date}) ?
            (lastBuildDate => "Sat, 07 Sep 2002 09:42:31 GMT",) :
            ();

    $rss->channel(
        title => "freshmeat.net",
        link  => "http://freshmeat.net",
        description => "Linux software",
        @build_date,
        @{$extra_channel_params},
        );

    $rss->add_item(
        title => "GTKeyboard 0.85",
        link  => "http://freshmeat.net/news/1999/06/21/930003829.html"
        );

    $rss->skipHours(@{$extra_skipHours_params});

    return $rss;
}

sub create_skipDays_rss
{
    my $args = shift;
    # my $rss = new XML::RSS::LibXML (version => '0.9');
    my $rss = new XML::RSS::LibXML (version => $args->{version});

    my $extra_channel_params = $args->{channel_params} || [];
    my $extra_skipDays_params = $args->{skipDays_params} || [];
    my @build_date =
        ($args->{version} eq "2.0" && !$args->{omit_date}) ?
            (lastBuildDate => "Sat, 07 Sep 2002 09:42:31 GMT",) :
            ();

    $rss->channel(
        title => "freshmeat.net",
        link  => "http://freshmeat.net",
        description => "Linux software",
        @build_date,
        @{$extra_channel_params},
        );

    $rss->add_item(
        title => "GTKeyboard 0.85",
        link  => "http://freshmeat.net/news/1999/06/21/930003829.html"
        );

    $rss->skipDays(@{$extra_skipDays_params});

    return $rss;
}

sub create_rss_with_image_w_undef_link
{
    my $args = shift;
    # my $rss = new XML::RSS::LibXML (version => '0.9');
    my $rss = new XML::RSS::LibXML (version => $args->{version});

    my $extra_image_params = $args->{image_params} || [];

    $rss->channel(
        title => "freshmeat.net",
        link  => "http://freshmeat.net",
        description => "the one-stop-shop for all your Linux software needs",
        );

    $rss->image(
        title => "freshmeat.net",
        url   => "0",
        @{$extra_image_params},
        );

    $rss->add_item(
        title => "GTKeyboard 0.85",
        link  => "http://freshmeat.net/news/1999/06/21/930003829.html"
        );

    return $rss;
}

sub create_item_rss
{
    my $args = shift;
    # my $rss = new XML::RSS::LibXML (version => '0.9');
    my $rss = new XML::RSS::LibXML (version => $args->{version});

    my $extra_item_params = $args->{item_params} || [];

    $rss->channel(
        title => "freshmeat.net",
        link  => "http://freshmeat.net",
        description => "the one-stop-shop for all your Linux software needs",
        );

    $rss->add_item(
        title => "Freecell Solver",
        link  => "http://fc-solve.berlios.de/",
        @$extra_item_params,
        );

    return $rss;
}

sub create_rss_without_item
{
    my $args = shift;
    # my $rss = new XML::RSS::LibXML (version => '0.9');
    my $rss = new XML::RSS::LibXML (version => $args->{version});

    $rss->channel(
        title => "freshmeat.net",
        link  => "http://freshmeat.net",
        description => "the one-stop-shop for all your Linux software needs",
        );

    return $rss;
}

{
    my $rss = create_no_image_rss({version => "0.9"});
    # TEST
    not_contains($rss, "<image>",
        "0.9 - if an image was not specified it isn't there."
    );
}

{
    my $rss = create_no_image_rss({version => "0.91"});
    # TEST
    not_contains($rss, "<image>",
        "0.91 - if an image was not specified it isn't there."
    );
}

{
    my $rss = create_no_image_rss({version => "1.0"});
    # TEST
    not_contains($rss, "<image rdf:about=\"",
        "1.0 - if an image was not specified it isn't there."
    );
    # TEST
    not_contains($rss, "<image rdf:resource=\"",
        "1.0 - if an image was not specified it isn't there."
    );
    
}

{
    my $rss = create_no_image_rss({version => "2.0"});
    # TEST
    not_contains($rss, "<image>",
        "1.0 - if an image was not specified it isn't there."
    );
}

sub match_elements
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($rss, $parent, $h) = @_;

    my $version = $rss->version;
    my $output  = $rss->as_string;

    my $re      = do {
        my %attrs;
        my $about   = delete $h->{about};
        if ($about) {
            $attrs{'rdf:about'} = $about;
        }

        my $str = "<$parent";
        if (my @attr_keys = keys %attrs) {
            $str .= "(?: (?:" . join('|', map { qq|$_="$attrs{$_}"| } @attr_keys) . ")[^>/]*)";
        } else {
            $str .= "[^>/]*";
        }
        $str .= ">((?!</$parent>).+?)</$parent>";

        qr{(?sm)$str};
    };

    ok ($output =~ /$re/, "Checking for $parent in RSS $version");
    my $contents = $1 || '';
    while (my ($e, $v) = each %$h) {
        my $local_re = do {
            my $content = ref $v ? delete $v->{content} : $v;
            if (! defined $content) {
                $content = '';
            }
            my $str = "<$e";
            if (ref $v) {
                $str .= "(?: (?:" . join('|', map { qq|$_="$v->{$_}"| } keys %$v) . ")[^>/]*)";
            }
            $str .= ">";

            if (! length $content) {
                $str =~ s/\)[^\)]+\)>/\)\)\/>/;
                qr{$str};
            } else {
                qr{$str$content</$e>};
            }
        };

        ok($contents =~ $local_re, "Checking for $e = $local_re in $parent for RSS $version");
    }
}

{
    foreach my $version (qw(0.9 0.91 1.0 2.0)) {
        my $rss = create_rss_1({version => $version});
        # TEST
        match_elements($rss, 'image', { url => 0, link => "http://freshmeat.net/", title => "freshmeat.net" });
    }
}

{
    foreach my $version (qw(0.9 0.91 1.0 2.0)) {
        my $rss = create_rss_1({version => $version, image_link => "0",});
        # TEST
        match_elements($rss, 'image', { url => 0, link => 0, title => "freshmeat.net" });
    }
}

{
    foreach my $version (qw(0.91 2.0)) {
        my $rss = create_rss_1({
                version => $version, 
                image_params => [width => 0, height => 0, description => 0],
            }
        );

        # TEST
        match_elements($rss, 'image', { url => 0, link => "http://freshmeat.net/", title => "freshmeat.net", description => 0, width => 0, height => 0 });
    }
}

{
    my $rss = create_item_with_0_rss({version => "0.9"});
    # TEST
    match_elements($rss, 'item', { title => 0, link => "http://rss.mytld/" });
}

{
    my $rss = create_item_with_0_rss({version => "0.91", 
            item_params => [description => "Hello There"],
        });

    # TEST
    match_elements($rss, 'item', { title => 0, link => "http://rss.mytld/", description => "Hello There" });
}

{
    my $rss = create_item_with_0_rss({version => "0.91", 
            item_params => [description => "0"],
        });

    # TEST
    match_elements($rss, 'item', { title => 0, link => "http://rss.mytld/", description => 0 } );
}

{
    my $rss = create_item_with_0_rss({version => "1.0", 
            item_params => [description => "Hello There", about => "Yowza"],
        });
    # TEST
    match_elements($rss, 'item', { about => "Yowza", title => 0, link => "http://rss.mytld/", description => "Hello There" } );
}

{
    my $rss = create_item_with_0_rss({version => "1.0", 
            item_params => [description => "0", about => "Yowza"],
        });
    # TEST
    match_elements($rss, 'item', { about => "Yowza", title => 0, link => "http://rss.mytld/", description => 0 });
}
# TODO : Test the dc: items.

{
    my @subs = (qw(title link description author category comments pubDate));
    my $rss = create_item_with_0_rss({version => "2.0", 
            item_params => 
            [
                map { $_ => 0 } @subs
            ],
        }
    );

    match_elements($rss, 'item', +{ map { ($_ => 0) } @subs });
}

{
    my $rss = create_item_with_0_rss({version => "2.0", 
            item_params => 
            [
                title => "Foo&Bar",
                link => "http://www.mytld/",
                permaLink => "0",
            ],
        }
    );

    # TEST
    match_elements($rss, 'item', { title => "Foo&amp;Bar", link => "http://www.mytld/", guid => { isPermaLink => "true", content => 0 } });
}

{
    my $rss = create_item_with_0_rss({version => "2.0", 
            item_params => 
            [
                title => "Foo&Bar",
                link => "http://www.mytld/",
                guid => "0",
            ],
        }
    );

    match_elements($rss, 'item', { title => "Foo&amp;Bar", link => "http://www.mytld/", guid => { isPermaLink => "false", content => 0 } });
}

SKIP:
{
    skip "TODO", 4;

    # TEST:$num_iters=4;
    foreach my $s (
        ["Hercules", "http://www.hercules.tld/",],
        ["0", "http://www.hercules.tld/",],
        ["Hercules", "0",],
        ["0", "0",],
        )
    {
        my $rss = create_item_with_0_rss({version => "2.0",
                item_params => 
                [
                    title => "Foo&Bar",
                    link => "http://www.mytld/",
                    source => $s->[0],
                    sourceUrl => $s->[1],
                ],
            }
        );

        # TEST*$num_iters
        contains(
            $rss,
            ("<item>\n" .
             "<title>Foo&#x26;Bar</title>\n" .
             "<link>http://www.mytld/</link>\n" .
             "<source url=\"$s->[1]\">$s->[0]</source>\n" .
             "</item>"
             ),
            "2.0 - item - source = $s->[0] sourceUrl = $s->[1]",
        );
    }
}

{
    foreach my $version (qw(0.9 0.91 2.0)) {
        my $rss = create_no_image_rss({version => $version});
        # TEST
        not_contains($rss, "<textinput>",
            "$version - if a textinput was not specified it isn't there."
        );
    }
}

{
    foreach my $version (qw(0.9 0.91)) {
        my $rss = create_textinput_with_0_rss({version => $version});
        # TEST
        match_elements($rss, 'textinput', { title => 0, description => 0, name => 0, link => 0 });
    }
}

{
    my $rss = create_no_image_rss({version => "1.0"});
    # TEST
    not_contains($rss, "<textinput rdf:about=",
        "1.0 - if a textinput was not specified it isn't there."
    );
    # TEST
    not_contains($rss, "<textinput rdf:resource=",
        "1.0 - if a textinput was not specified it isn't there."
    );
    
}

SKIP:
{
    skip "TODO, NOW", 2;
    my $rss = create_textinput_with_0_rss({version => "1.0"});
    # TEST
    contains(
        $rss,
        ("<textinput rdf:about=\"0\">\n" . join("", map {"<$_>0</$_>\n"} (qw(title description name link))) . "</textinput>\n"),
        "1.0 - textinput/link == 0",
    );
    # TEST
    contains(
        $rss,
        "<textinput rdf:resource=\"0\" />\n</channel>\n",
        "1.0 - textinput/link == 0 and textinput rdf:resource",
    );    
}


{
    my $rss = create_textinput_with_0_rss({version => "2.0"});
    # TEST
    match_elements($rss, 'textInput', { link => 0, title => 0, description => 0, name => 0});
}

{
    my $rss = create_channel_rss({version => "0.91"});
    # TEST
    match_elements($rss, 'channel', { title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software' });
}

{
    my $rss = create_channel_rss({
            version => "0.91", 
            channel_params => [dc => { language => "0",},],
        });
    # TEST
    match_elements($rss, 'channel', { title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'dc:language' => 0 });
}

{
    my $rss = create_channel_rss({
            version => "0.91", 
            channel_params => [language => "0",],
        });
    match_elements($rss, 'channel', { title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'language' => 0 });
}

{
    my $rss = create_channel_rss({version => "1.0"});
    # TEST
    match_elements($rss, 'channel', { about => "http://freshmeat.net", title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software' });
}

{
    my $rss = create_channel_rss({
            version => "1.0", 
            channel_params => [dc => { language => "0",},],
        });
    # TEST
    match_elements($rss, 'channel', { about => "http://freshmeat.net", title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'dc:language' => 0 });
}

{
    my $rss = create_channel_rss({
            version => "1.0", 
            channel_params => [language => "0",],
        });
    # TEST
    match_elements($rss, 'channel', { about => "http://freshmeat.net", title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'dc:language' => 0 });
}

{
    my $rss = create_channel_rss({version => "2.0"});
    # TEST
    match_elements($rss, 'channel', { title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'lastBuildDate' => 'Sat, 07 Sep 2002 09:42:31 GMT' });
}

{
    my $rss = create_channel_rss({
            version => "2.0", 
            channel_params => [dc => { language => "0",},],
        });
    # XXX - Original only tested for 'language'. should this be the case?
    # TEST
    match_elements($rss, 'channel', { title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'dc:language' => 0, 'language' => 0, 'lastBuildDate' => 'Sat, 07 Sep 2002 09:42:31 GMT' });
}

{
    my $rss = create_channel_rss({
            version => "2.0", 
            channel_params => [language => "0",],
        });
    # TEST
    match_elements($rss, 'channel', { title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'language' => 0, 'lastBuildDate' => 'Sat, 07 Sep 2002 09:42:31 GMT' });
}

{
    my $rss = create_channel_rss({
            version => "0.91", 
            channel_params => [rating => "0",],
        });
    # TEST
    match_elements($rss, 'channel', { title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'rating' => 0});
}

{
    my $rss = create_channel_rss({
            version => "0.91", 
            channel_params => [rating => "Hello", dc => {rights => "0"},],
        });
    # TEST
    match_elements($rss, 'channel', { title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'rating' => 'Hello', 'dc:rights' => 0});
}

{
    my $rss = create_channel_rss({
            version => "0.91", 
            channel_params => [rating => "Hello", copyright => "0",],
        });
    # TEST
    match_elements($rss, 'channel', { title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'rating' => 'Hello', 'copyright' => 0});
}

{
    my $rss = create_channel_rss({
            version => "2.0", 
            channel_params => [dc => {rights => "0"},],
        });
    # TEST
    match_elements($rss, 'channel', { title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'dc:rights' => 0, 'lastBuildDate' => 'Sat, 07 Sep 2002 09:42:31 GMT' });
}

{
    my $rss = create_channel_rss({
            version => "2.0", 
            channel_params => [copyright=> "0",],
        });
    # TEST
    match_elements($rss, 'channel', { title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'copyright' => 0, 'lastBuildDate' => 'Sat, 07 Sep 2002 09:42:31 GMT' });
}

{
    my $rss = create_channel_rss({
            version => "0.91", 
            channel_params => 
            [rating => "Hello", copyright => "Martha",docs => "0",],
        });
    # TEST
    match_elements($rss, 'channel', { title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'copyright' => 'Martha', docs => 0 });
}

{
    my $rss = create_channel_rss({
            version => "2.0", 
            channel_params => [copyright => "Martha", docs => "0",],
        });
    # TEST
    match_elements($rss, 'channel', { title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'copyright' => 'Martha', docs => 0 });
}

{
    my $rss = create_channel_rss({
            version => "0.91", 
            channel_params => 
            [rating => "Hello", copyright => "Martha",
            docs => "MyDr. docs",dc => {publisher => 0}],
        });
    # TEST
    match_elements($rss, 'channel', { title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'copyright' => 'Martha', docs => 'MyDr. docs', managingEditor => 0 });
}

{
    my $rss = create_channel_rss({
            version => "0.91", 
            channel_params => 
            [rating => "Hello", copyright => "Martha",
            docs => "MyDr. docs",managingEditor => 0],
        });
    # TEST
    match_elements($rss, 'channel', { title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'copyright' => 'Martha', docs => 'MyDr. docs', managingEditor => 0 });
}

{
    my $rss = create_channel_rss({
            version => "2.0", 
            channel_params => 
            [copyright => "Martha",
            docs => "MyDr. docs",managingEditor => 0],
        });
    # TEST
    match_elements($rss, 'channel', { title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'copyright' => 'Martha', lastBuildDate => 'Sat, 07 Sep 2002 09:42:31 GMT', docs => 'MyDr. docs', managingEditor => 0 });
}

{
    my $rss = create_channel_rss({
            version => "2.0", 
            channel_params => 
            [copyright => "Martha", docs => "MyDr. docs",
            dc => {publisher => 0}],
        });
    # TEST
    match_elements($rss, 'channel', { title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'copyright' => 'Martha', lastBuildDate => 'Sat, 07 Sep 2002 09:42:31 GMT', docs => 'MyDr. docs', managingEditor => 0 });
}

{
    my $rss = create_channel_rss({
            version => "1.0", 
            channel_params => 
            [copyright => "Martha", dc => {publisher => 0}],
        });
    # TEST
    match_elements($rss, 'channel', { about => "http://freshmeat.net", title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'dc:rights' => 'Martha', 'dc:publisher' => 0 });
}

{
    # Here we create an RSS 2.0 object and render it as 1.0 to get the
    # "managingEditor" field acknowledged.
    my $rss = create_channel_rss({
            version => "2.0", 
            channel_params =>
            [copyright => "Martha", managingEditor => 0,],
            omit_date => 1,
        });
    $rss->{output} = "1.0";
    # TEST

    match_elements($rss, 'channel', { about => "http://freshmeat.net", title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'dc:rights' => 'Martha', 'dc:publisher' => 0 });
}

{
    my $rss = create_channel_rss({
            version => "0.91", 
            channel_params => 
            [rating => "Hello", copyright => "Martha",
            docs => "MyDr. docs",dc => {creator => 0}],
        });
    # TEST
    match_elements($rss, 'channel', { title => 'freshmeat.net', link => 'http://freshmeat.net', description => 'Linux software', rating => 'Hello', copyright => 'Martha', docs => 'MyDr. docs', webMaster => 0 });
}

{
    my $rss = create_channel_rss({
            version => "0.91", 
            channel_params => 
            [rating => "Hello", copyright => "Martha",
            docs => "MyDr. docs",webMaster => 0],
        });
    # TEST
    match_elements($rss, 'channel', { title => 'freshmeat.net', link => 'http://freshmeat.net', description => 'Linux software', rating => 'Hello', copyright => 'Martha', docs => 'MyDr. docs', webMaster => 0 });
}

{
    my $rss = create_channel_rss({
            version => "1.0", 
            channel_params => 
            [copyright => "Martha", dc => {creator => 0}],
        });
    # TEST
    match_elements($rss, 'channel', { about => "http://freshmeat.net", title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'dc:rights' => 'Martha', 'dc:creator' => 0 });
}

{
    # Here we create an RSS 2.0 object and render it as 1.0 to get the
    # "managingEditor" field acknowledged.
    my $rss = create_channel_rss({
            version => "2.0", 
            channel_params =>
            [copyright => "Martha", webMaster => 0,],
            omit_date => 1,
        });
    $rss->{output} = "1.0";
    # TEST
    match_elements($rss, 'channel', { about => "http://freshmeat.net", title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'dc:rights' => 'Martha', 'dc:creator' => 0 });
}

{
    my $rss = create_channel_rss({
            version => "2.0", 
            channel_params => 
            [copyright => "Martha",
            docs => "MyDr. docs",webMaster => 0],
        });
    # TEST
    match_elements($rss, 'channel', { title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'copyright' => 'Martha', lastBuildDate => 'Sat, 07 Sep 2002 09:42:31 GMT', docs => 'MyDr. docs', webMaster => 0 });
}

{
    my $rss = create_channel_rss({
            version => "2.0", 
            channel_params => 
            [copyright => "Martha", docs => "MyDr. docs",
            dc => {creator => 0}],
        });
    # TEST
    match_elements($rss, 'channel', { title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'copyright' => 'Martha', lastBuildDate => 'Sat, 07 Sep 2002 09:42:31 GMT', docs => 'MyDr. docs', webMaster => 0 });
}

{
    my $rss = create_no_image_rss({version => "0.91"});
    # TEST
    not_contains($rss, "<skipHours>",
        "0.91 - if skipHours was not specified it isn't there."
    );
}

{
    my $rss = create_skipHours_rss({
            version => "0.91", 
            skipHours_params => [ hour => "0" ],
        });
    # TEST
    match_elements($rss, 'channel', { skipHours => '\s*<hour>0</hour>\s*' });
}

{
    my $rss = create_no_image_rss({version => "2.0"});
    # TEST
    not_contains($rss, "<skipHours>",
        "2.0 - if skipHours was not specified it isn't there."
    );
}

{
    my $rss = create_skipHours_rss({
            version => "2.0", 
            skipHours_params => [ hour => "0" ],
        });
    # TEST
    match_elements($rss, 'channel', { skipHours => '\s*<hour>0</hour>\s*' });
}

{
    my $rss = create_no_image_rss({version => "0.91"});
    # TEST
    not_contains($rss, "<skipDays>",
        "0.91 - if skipDays was not specified it isn't there."
    );
}

{
    my $rss = create_skipDays_rss({
            version => "0.91", 
            skipDays_params => [ day => "0" ],
        });
    # TEST
    match_elements($rss, 'channel', { skipDays => '\s*<day>0</day>\s*' });
}

{
    my $rss = create_no_image_rss({version => "2.0"});
    # TEST
    not_contains($rss, "<skipDays>",
        "2.0 - if skipDays was not specified it isn't there."
    );
}

{
    my $rss = create_skipDays_rss({
            version => "2.0", 
            skipDays_params => [ day => "0" ],
        });
    # TEST
    match_elements($rss, 'channel', { skipDays => '\s*<day>0</day>\s*' });
}

{
    my $rss = create_channel_rss({
            version => "1.0", 
            channel_params => 
            [copyright => 0,],
        });
    # TEST
    match_elements($rss, 'channel', { about => "http://freshmeat.net", title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'dc:rights' => 0 });
=head1
    contains($rss, "<channel rdf:about=\"http://freshmeat.net\">\n" .
        "<title>freshmeat.net</title>\n" .
        "<link>http://freshmeat.net</link>\n" .
        "<description>Linux software</description>\n" .
        "<dc:rights>0</dc:rights>\n" .
        "<items>\n",
        "1.0 - channel/copyright == 0"
    );
=cut
}

{
    my $rss = create_channel_rss({
            version => "1.0", 
            channel_params => 
            [dc => { rights => 0},],
        });
    # TEST
    match_elements($rss, 'channel', { about => "http://freshmeat.net", title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'dc:rights' => 0 });
=head1
    contains($rss, "<channel rdf:about=\"http://freshmeat.net\">\n" .
        "<title>freshmeat.net</title>\n" .
        "<link>http://freshmeat.net</link>\n" .
        "<description>Linux software</description>\n" .
        "<dc:rights>0</dc:rights>\n" .
        "<items>\n",
        "1.0 - channel/dc/rights == 0"
    );
=cut
}

{
    my $rss = create_channel_rss({
            version => "1.0", 
            channel_params => 
            [dc => { title => 0},],
        });
    # TEST
    match_elements($rss, 'channel', { about => "http://freshmeat.net", title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'dc:title' => 0 });
=head1
    contains($rss, "<channel rdf:about=\"http://freshmeat.net\">\n" .
        "<title>freshmeat.net</title>\n" .
        "<link>http://freshmeat.net</link>\n" .
        "<description>Linux software</description>\n" .
        "<dc:title>0</dc:title>\n" .
        "<items>\n",
        "1.0 - channel/dc/title == 0"
    );
=cut
}

{
    my $rss = create_channel_rss({
            version => "1.0", 
            channel_params => 
            [syn => { updateBase=> 0},],
        });
    # TEST
    match_elements($rss, 'channel', { about => "http://freshmeat.net", title => 'freshmeat.net', link => 'http://freshmeat.net', 'description' => 'Linux software', 'syn:updateBase' => 0 });
=head1
    contains($rss, "<channel rdf:about=\"http://freshmeat.net\">\n" .
        "<title>freshmeat.net</title>\n" .
        "<link>http://freshmeat.net</link>\n" .
        "<description>Linux software</description>\n" .
        "<syn:updateBase>0</syn:updateBase>\n" .
        "<items>\n",
        "1.0 - channel/syn/updateBase == 0"
    );
=cut
}

{
    my $rss = create_rss_1({version => "1.0", 
            image_params => [ dc => { subject => 0, }]
        });
    # TEST
    match_elements($rss, 'image', { about => 0, title => 'freshmeat.net', url => 0, link => 'http://freshmeat.net/', 'dc:subject' => 0 });
=head1
    contains ($rss, 
        (qq{<image rdf:about="0">\n<title>freshmeat.net</title>\n} .
        qq{<url>0</url>\n<link>http://freshmeat.net/</link>\n} . 
        qq{<dc:subject>0</dc:subject>\n</image>}),
         "1.0 - Checking for image/dc/subject == 0");
=cut
}

{
    my $rss = create_item_with_0_rss({version => "1.0", 
            item_params => 
            [
                description => "Hello There",
                about => "Yowza",
                dc => { subject => 0,},
            ],
        });
    # TEST
    match_elements($rss, 'item', { about => "Yowza", title => 0, link => "http://rss.mytld/", description => "Hello There", "dc:subject" => 0 });
=head1
    contains(
        $rss,
        "<item rdf:about=\"Yowza\">\n<title>0</title>\n<link>http://rss.mytld/</link>\n<description>Hello There</description>\n<dc:subject>0</dc:subject>\n</item>",
        "1.0 - item/dc/subject == 0",
    );
=cut
}

{
    my $rss = create_textinput_with_0_rss({version => "1.0",
            textinput_params => [dc => { subject => 0,},],
        });
    # TEST
    match_elements($rss, 'textinput', { about => 0, title => 0, description => 0, name => 0, link => 0, 'dc:subject' => 0 });
=head1
    contains(
        $rss,
        ("<textinput rdf:about=\"0\">\n" . join("", map {"<$_>0</$_>\n"} (qw(title description name link dc:subject))) . "</textinput>\n"),
        "1.0 - textinput/dc/subject == 0",
    );
=cut
}

{
    # TEST:$num_fields=3;
    foreach my $field (qw(category generator ttl))
    {
        # TEST:$num_dc=2;
        foreach my $dc (1,0)
        {
            my $rss = create_channel_rss({
                    version => "2.0",
                    channel_params =>
                    [$dc ? 
                        (dc => {$field => 0 }) :
                        ($field => 0)
                    ],
                });
            # TEST*$num_fields*$num_dc

            match_elements($rss, 'channel', { title => 'freshmeat.net', link => 'http://freshmeat.net', description => 'Linux software', lastBuildDate => 'Sat, 07 Sep 2002 09:42:31 GMT', $field => 0 });
=head
            contains($rss, "<channel>\n" .
                "<title>freshmeat.net</title>\n" .
                "<link>http://freshmeat.net</link>\n" .
                "<description>Linux software</description>\n" .
                "<lastBuildDate>Sat, 07 Sep 2002 09:42:31 GMT</lastBuildDate>\n" . 
                "<$field>0</$field>\n" .
                "\n" .
                "<item>\n",
                "2.0 - Testing for fields with an optional dc being 0. (dc=$dc,field=$field)"
            );
=cut
        }
    }
}

{
    my $rss = create_channel_rss({
            version => "0.91", 
            channel_params => [pubDate => "</pubDate><hello>There&amp;Everywhere</hello>"],
        });
    # TEST
    match_elements($rss, 'channel', { title => 'freshmeat.net', link => 'http://freshmeat.net', description => 'Linux software', pubDate => '&lt;/pubDate&gt;&lt;hello&gt;There&amp;amp;Everywhere&lt;/hello&gt;' });
=head1
    contains($rss, "<channel>\n" .
        "<title>freshmeat.net</title>\n" .
        "<link>http://freshmeat.net</link>\n" .
        "<description>Linux software</description>\n" .
        "<pubDate>&#x3C;/pubDate&#x3E;&#x3C;hello&#x3E;There&#x26;amp;Everywhere&#x3C;/hello&#x3E;</pubDate>\n" .
        "\n" .
        "<item>\n",
        "0.9.1 - channel/pubDate Markup Injection"
    );
=cut
}

{
    my $rss = create_channel_rss({
            version => "0.91", 
            channel_params => [lastBuildDate => "</pubDate><hello>There&amp;Everywhere</hello>"],
        });
    # TEST
    match_elements($rss, 'channel', { title => 'freshmeat.net', link => 'http://freshmeat.net', description => 'Linux software', lastBuildDate => '&lt;/pubDate&gt;&lt;hello&gt;There&amp;amp;Everywhere&lt;/hello&gt;' });
=head1
    contains($rss, "<channel>\n" .
        "<title>freshmeat.net</title>\n" .
        "<link>http://freshmeat.net</link>\n" .
        "<description>Linux software</description>\n" .
        "<lastBuildDate>&#x3C;/pubDate&#x3E;&#x3C;hello&#x3E;There&#x26;amp;Everywhere&#x3C;/hello&#x3E;</lastBuildDate>\n" .
        "\n" .
        "<item>\n",
        "0.9.1 - channel/lastBuildDate Markup Injection"
    );
=cut
}

{
    my $rss = create_channel_rss({
        version => "1.0",
        channel_params => 
        [
            dc => 
            {
                date => "</pubDate><hello>There&amp;Everywhere</hello>"
            },
        ],
    });
    # TEST
    match_elements($rss, 'channel', { about => 'http://freshmeat.net', title => 'freshmeat.net', link => 'http://freshmeat.net', description => 'Linux software', 'dc:date' => '&lt;/pubDate&gt;&lt;hello&gt;There&amp;amp;Everywhere&lt;/hello&gt;' });
=head1
    contains($rss, "<channel rdf:about=\"http://freshmeat.net\">\n" .
        "<title>freshmeat.net</title>\n" .
        "<link>http://freshmeat.net</link>\n" .
        "<description>Linux software</description>\n" .
        "<dc:date>&#x3C;/pubDate&#x3E;&#x3C;hello&#x3E;There&#x26;amp;Everywhere&#x3C;/hello&#x3E;</dc:date>\n" .
        "<items>\n",
        "1.0 - dc/date Markup Injection"
    );
=cut
}

{
    my $rss = create_channel_rss({version => "2.0", 
            channel_params => [pubDate => "</pubDate><hello>There&amp;Everywhere</hello>"],
            omit_date => 1,
        });
    # TEST
    match_elements($rss, 'channel', { title => 'freshmeat.net', link => 'http://freshmeat.net', description => 'Linux software', 'pubDate' => '&lt;/pubDate&gt;&lt;hello&gt;There&amp;amp;Everywhere&lt;/hello&gt;' });
=head1
    contains($rss, "<channel>\n" .
        "<title>freshmeat.net</title>\n" .
        "<link>http://freshmeat.net</link>\n" .
        "<description>Linux software</description>\n" .
        "<pubDate>&#x3C;/pubDate&#x3E;&#x3C;hello&#x3E;There&#x26;amp;Everywhere&#x3C;/hello&#x3E;</pubDate>\n" .
        "\n" .
        "<item>\n",
        "2.0 - channel/pubDate Markup Injection"
    );
=cut
}

{
    my $rss = create_channel_rss({version => "2.0", 
            channel_params => [lastBuildDate => "</pubDate><hello>There&amp;Everywhere</hello>"],
            omit_date => 1,
        });
    # TEST
    match_elements($rss, 'channel', { title => 'freshmeat.net', link => 'http://freshmeat.net', description => 'Linux software', 'lastBuildDate' => '&lt;/pubDate&gt;&lt;hello&gt;There&amp;amp;Everywhere&lt;/hello&gt;' });
=head1
    contains($rss, "<channel>\n" .
        "<title>freshmeat.net</title>\n" .
        "<link>http://freshmeat.net</link>\n" .
        "<description>Linux software</description>\n" .
        "<lastBuildDate>&#x3C;/pubDate&#x3E;&#x3C;hello&#x3E;There&#x26;amp;Everywhere&#x3C;/hello&#x3E;</lastBuildDate>\n" .
        "\n" .
        "<item>\n",
        "2.0 - channel/lastBuildDate Markup Injection"
    );
=cut
}

{
    my $rss = create_rss_with_image_w_undef_link({version => "0.9"});
    # TEST
    match_elements($rss, 'image', { title => 'freshmeat.net', url => 0 });
=head1
    contains ($rss, qq{<image>\n<title>freshmeat.net</title>\n<url>0</url>\n</image>\n},
        "Image with undefined link does not render the Image - RSS version 0.9"
    );
=cut
}

{
    my $rss = create_rss_with_image_w_undef_link({version => "1.0"});
    # TEST
    match_elements($rss, 'image', { about => 0, title => 'freshmeat.net', url => 0 });
=head1
    contains ($rss, 
        qq{<image rdf:about="0">\n<title>freshmeat.net</title>\n} . 
        qq{<url>0</url>\n</image>\n},
        "Image with undefined link does not render the Image - RSS version 1.0"
    );
=cut
}

{
    my $rss = create_channel_rss({
            version => "1.0", 
            channel_params => [about => "http://xml-rss-hackers.tld/"],
        });
    # TEST
    match_elements($rss, 'channel', { about => 'http://xml-rss-hackers.tld/', title => 'freshmeat.net', link => 'http://freshmeat.net', description => 'Linux software' });
=head1
    contains($rss, "<channel rdf:about=\"http://xml-rss-hackers.tld/\">\n" .
        "<title>freshmeat.net</title>\n" .
        "<link>http://freshmeat.net</link>\n" .
        "<description>Linux software</description>\n" .
        "<items>\n",
        "1.0 - channel/about overrides the rdf:about attribute."
    );
=cut
}

{
    my $rss = create_channel_rss({
        version => "1.0",
        channel_params => 
        [
            taxo => ["Foo", "Bar", "QuGof", "Lambda&Delta"],
        ],
    });
    # TEST
    match_elements($rss, 'channel', { about => "http://freshmeat.net", title => 'freshmeat.net', link => 'http://freshmeat.net', description => 'Linux software' });
    match_elements($rss, 'rdf:Bag', { 'rdf:li' => { resource => 'Foo' } });
    match_elements($rss, 'rdf:Bag', { 'rdf:li' => { resource => 'Bar' } });
    match_elements($rss, 'rdf:Bag', { 'rdf:li' => { resource => 'QuGof' } });
    match_elements($rss, 'rdf:Bag', { 'rdf:li' => { resource => 'Lambda&amp;Delta' } });
=head1
    contains($rss, "<channel rdf:about=\"http://freshmeat.net\">\n" .
        "<title>freshmeat.net</title>\n" .
        "<link>http://freshmeat.net</link>\n" .
        "<description>Linux software</description>\n" .
        qq{<taxo:topics>\n  <rdf:Bag>\n} .
        qq{    <rdf:li resource="Foo" />\n} .
        qq{    <rdf:li resource="Bar" />\n} .
        qq{    <rdf:li resource="QuGof" />\n} .
        qq{    <rdf:li resource="Lambda&#x26;Delta" />\n} .
        qq{  </rdf:Bag>\n</taxo:topics>\n} .
        "<items>\n",
        "1.0 - taxo topics"
    );
=cut
}

SKIP:
{
    skip "TODO (Unsupported key)", 3;
{
    my $rss = create_channel_rss({
        version => "1.0",
        channel_params => 
        [
            admin => { 'foobar' => "Quod", },
        ],
    });
    # TEST
    contains($rss, "<channel rdf:about=\"http://freshmeat.net\">\n" .
        "<title>freshmeat.net</title>\n" .
        "<link>http://freshmeat.net</link>\n" .
        "<description>Linux software</description>\n" .
        "<admin:foobar>Quod</admin:foobar>\n" .
        "<items>\n",
        '1.0 - channel/[module] with unknown key'
    );
}

{
    my $rss = create_channel_rss({
        version => "1.0",
        channel_params => 
        [
            eloq => { 'grow' => "There", },
        ],
    });

    $rss->add_module(prefix => "eloq", uri => "http://eloq.tld2/Gorj/");
    # TEST
    contains($rss, "<channel rdf:about=\"http://freshmeat.net\">\n" .
        "<title>freshmeat.net</title>\n" .
        "<link>http://freshmeat.net</link>\n" .
        "<description>Linux software</description>\n" .
        "<eloq:grow>There</eloq:grow>\n" .
        "<items>\n",
        '1.0 - channel/[module] with new module'
    );
}

{
    my $rss = create_rss_1({
        version => "1.0",
        image_params => 
        [
            admin => { 'foobar' => "Quod", },
        ],
    });
    # TEST
    contains($rss, "<image rdf:about=\"0\">\n" .
        "<title>freshmeat.net</title>\n" .
        "<url>0</url>\n" .
        "<link>http://freshmeat.net/</link>\n" .
        "<admin:foobar>Quod</admin:foobar>\n" .
        "</image>",
        '1.0 - image/[module] with unknown key'
    );
}
}

{
    my $rss = create_rss_1({
        version => "1.0",
        image_params => 
        [
            eloq => { 'grow' => "There", },
        ],
    });

    $rss->add_module(prefix => "eloq", uri => "http://eloq.tld2/Gorj/");
    # TEST

    match_elements($rss, 'image', { about => 0, title => 'freshmeat.net', url => 0, link => "http://freshmeat.net/", 'eloq:grow' => 'There' });
=head1
    contains($rss, "<image rdf:about=\"0\">\n" .
        "<title>freshmeat.net</title>\n" .
        "<url>0</url>\n" .
        "<link>http://freshmeat.net/</link>\n" .
        "<eloq:grow>There</eloq:grow>\n" .
        "</image>",
        '1.0 - image/[module] with new module'
    );
=cut
}

SKIP:
{
    skip "TODO (generatorAgent)", 1;
    my $rss = create_rss_1({
        version => "1.0",
        image_params => 
        [
            admin => { 'generatorAgent' => "Spozilla 5.5", },
        ],
    });

    # TEST
    match_elements($rss, 'image', { about => 0, title => 'freshmeat.net', url => 0, link => "http://freshmeat.net/", 'admin:generatorAgent' => { 'rdf:resource' => 'Spozilla 5.5' } });

=head1
    contains($rss, "<image rdf:about=\"0\">\n" .
        "<title>freshmeat.net</title>\n" .
        "<url>0</url>\n" .
        "<link>http://freshmeat.net/</link>\n" .
        "<admin:generatorAgent rdf:resource=\"Spozilla 5.5\" />\n" .
        "</image>",
        '1.0 - image/[module] with known module'
    );
=cut
}

{
    my $rss = create_channel_rss({
        version => "1.0",
    });

    $rss->add_item(
        title => "In the Jungle",
        link => "http://jungle.tld/Enter/",
        taxo => ["Foo","Loom", "<Ard>", "Yok&Dol"],
    );

    # TEST
    match_elements($rss, 'item', { about => "http://jungle.tld/Enter/", title => 'In the Jungle', link => 'http://jungle.tld/Enter/'});
    match_elements($rss, 'rdf:Bag', { 'rdf:li' => { resource => 'Foo' } });
    match_elements($rss, 'rdf:Bag', { 'rdf:li' => { resource => 'Loom' } });
    match_elements($rss, 'rdf:Bag', { 'rdf:li' => { resource => '&lt;Ard&gt;' } });
    match_elements($rss, 'rdf:Bag', { 'rdf:li' => { resource => 'Yok&amp;Dol' } });
=head1
    contains($rss, "<item rdf:about=\"http://jungle.tld/Enter/\">\n" .
        "<title>In the Jungle</title>\n" .
        "<link>http://jungle.tld/Enter/</link>\n" .
        qq{<taxo:topics>\n} . 
        qq{  <rdf:Bag>\n} .
        qq{    <rdf:li resource="Foo" />\n} .
        qq{    <rdf:li resource="Loom" />\n} .
        qq{    <rdf:li resource="&#x3C;Ard&#x3E;" />\n} .
        qq{    <rdf:li resource="Yok&#x26;Dol" />\n} .
        qq{  </rdf:Bag>\n} . 
        qq{</taxo:topics>\n} .
        "</item>\n",
        "1.0 - item/taxo:topics (with escaping)"
    );
=cut
}

## Test the RSS 1.0 items' ad-hoc modules support.
SKIP: {
    skip "hoge", 10;
{
    my $rss = create_item_rss({
        version => "1.0",
        item_params => 
        [
            admin => { 'foobar' => "Quod", },
        ],
    });

    # TEST
    contains($rss, "<item rdf:about=\"http://fc-solve.berlios.de/\">\n" .
        "<title>Freecell Solver</title>\n" .
        "<link>http://fc-solve.berlios.de/</link>\n" .
        "<admin:foobar>Quod</admin:foobar>\n" .
        "</item>",
        '1.0 - item/[module] with unknown key'
    );
}

{
    my $rss = create_item_rss({
        version => "1.0",
        item_params => 
        [
            eloq => { 'grow' => "There", },
        ],
    });

    $rss->add_module(prefix => "eloq", uri => "http://eloq.tld2/Gorj/");

    # TEST
    contains($rss, "<item rdf:about=\"http://fc-solve.berlios.de/\">\n" .
        "<title>Freecell Solver</title>\n" .
        "<link>http://fc-solve.berlios.de/</link>\n" .
        "<eloq:grow>There</eloq:grow>\n" .        
        "</item>",
        '1.0 - item/[module] with new module'
    );
}

{
    my $rss = create_item_rss({
        version => "1.0",
        item_params => 
        [
            admin => { 'generatorAgent' => "Spozilla 5.5", },
        ],
    });

    # TEST
    contains($rss, "<item rdf:about=\"http://fc-solve.berlios.de/\">\n" .
        "<title>Freecell Solver</title>\n" .
        "<link>http://fc-solve.berlios.de/</link>\n" .
        "<admin:generatorAgent rdf:resource=\"Spozilla 5.5\" />\n" .
        "</item>",
        '1.0 - item/[module] with known module'
    );
}

{
    my $rss = create_textinput_with_0_rss({version => "1.0",
            textinput_params => [admin => { 'foobar' => "Quod", },],
        });
    # TEST
    contains(
        $rss,
        ("<textinput rdf:about=\"0\">\n" .
         join("", map {"<$_>0</$_>\n"} (qw(title description name link))) .
         "<admin:foobar>Quod</admin:foobar>\n" .
         "</textinput>\n"
        ),
        "1.0 - textinput/[module]",
    );
}

{
    my $rss = create_channel_rss({
        version => "2.0",
        channel_params => 
        [
            admin => { 'generatorAgent' => "Spozilla 5.5", },
        ],
    });

    $rss->add_module(prefix => "admin", uri => "http://webns.net/mvcb/");
    # TEST

    contains($rss, "<channel>\n" .
        "<title>freshmeat.net</title>\n" .
        "<link>http://freshmeat.net</link>\n" .
        "<description>Linux software</description>\n" .
        "<lastBuildDate>Sat, 07 Sep 2002 09:42:31 GMT</lastBuildDate>\n" .
        "<admin:generatorAgent rdf:resource=\"Spozilla 5.5\" />\n" .
        "\n" . 
        "<item>\n",
        '2.0 - channel/[module] with known module and key'
    );
}


{
    my $rss = create_channel_rss({
        version => "2.0",
        channel_params => 
        [
            admin => { 'foobar' => "Quod", },
        ],
    });
    $rss->add_module(prefix => "admin", uri => "http://webns.net/mvcb/");
    # TEST
    contains($rss, "<channel>\n" .
        "<title>freshmeat.net</title>\n" .
        "<link>http://freshmeat.net</link>\n" .
        "<description>Linux software</description>\n" .
        "<lastBuildDate>Sat, 07 Sep 2002 09:42:31 GMT</lastBuildDate>\n" .
        "<admin:foobar>Quod</admin:foobar>\n" .
        "\n" .
        "<item>\n",
        '2.0 - channel/[module] with unknown key'
    );
}

{
    my $rss = create_channel_rss({
        version => "2.0",
        channel_params => 
        [
            eloq => { 'grow' => "There", },
        ],
    });

    $rss->add_module(prefix => "eloq", uri => "http://eloq.tld2/Gorj/");
    # TEST
    contains($rss, "<channel>\n" .
        "<title>freshmeat.net</title>\n" .
        "<link>http://freshmeat.net</link>\n" .
        "<description>Linux software</description>\n" .
        "<lastBuildDate>Sat, 07 Sep 2002 09:42:31 GMT</lastBuildDate>\n" .
        "<eloq:grow>There</eloq:grow>\n" .
        "\n" .
        "<item>\n",
        '2.0 - channel/[module] with new module'
    );
}


## Testing the RSS 2.0 Image Modules Support

{
    my $rss = create_rss_1({
        version => "2.0",
        image_params => 
        [
            admin => { 'foobar' => "Quod", },
        ],
    });
    $rss->add_module(prefix => "admin", uri => "http://webns.net/mvcb/");
    # TEST
    contains($rss, "<image>\n" .
        "<title>freshmeat.net</title>\n" .
        "<url>0</url>\n" .
        "<link>http://freshmeat.net/</link>\n" .
        "<admin:foobar>Quod</admin:foobar>\n" .
        "</image>\n",
        '2.0 - image/[module] with unknown key'
    );
}

{
    my $rss = create_rss_1({
        version => "2.0",
        image_params => 
        [
            eloq => { 'grow' => "There", },
        ],
    });

    $rss->add_module(prefix => "eloq", uri => "http://eloq.tld2/Gorj/");
    # TEST
    contains($rss, "<image>\n" .
        "<title>freshmeat.net</title>\n" .
        "<url>0</url>\n" .
        "<link>http://freshmeat.net/</link>\n" .
        "<eloq:grow>There</eloq:grow>\n" .
        "</image>",
        '2.0 - image/[module] with new module'
    );
}

{
    my $rss = create_rss_1({
        version => "2.0",
        image_params => 
        [
            admin => { 'generatorAgent' => "Spozilla 5.5", },
        ],
    });
    $rss->add_module(prefix => "admin", uri => "http://webns.net/mvcb/");
    # TEST
    contains($rss, "<image>\n" .
        "<title>freshmeat.net</title>\n" .
        "<url>0</url>\n" .
        "<link>http://freshmeat.net/</link>\n" .
        "<admin:generatorAgent rdf:resource=\"Spozilla 5.5\" />\n" .
        "</image>",
        '2.0 - image/[module] with known module'
    );
}

## Test the RSS 2.0 items' ad-hoc modules support.

{
    my $rss = create_item_rss({
        version => "2.0",
        item_params => 
        [
            admin => { 'foobar' => "Quod", },
        ],
    });
    $rss->add_module(prefix => "admin", uri => "http://webns.net/mvcb/");

    # TEST
    contains($rss, "<item>\n" .
        "<title>Freecell Solver</title>\n" .
        "<link>http://fc-solve.berlios.de/</link>\n" .
        "<admin:foobar>Quod</admin:foobar>\n" .
        "</item>",
        '2.0 - item/[module] with unknown key'
    );
}

{
    my $rss = create_item_rss({
        version => "2.0",
        item_params => 
        [
            eloq => { 'grow' => "There", },
        ],
    });

    $rss->add_module(prefix => "eloq", uri => "http://eloq.tld2/Gorj/");

    # TEST
    contains($rss, "<item>\n" .
        "<title>Freecell Solver</title>\n" .
        "<link>http://fc-solve.berlios.de/</link>\n" .
        "<eloq:grow>There</eloq:grow>\n" .        
        "</item>",
        '2.0 - item/[module] with new module'
    );
}

{
    my $rss = create_item_rss({
        version => "2.0",
        item_params => 
        [
            admin => { 'generatorAgent' => "Spozilla 5.5", },
        ],
    });
    $rss->add_module(prefix => "admin", uri => "http://webns.net/mvcb/");

    # TEST
    contains($rss, "<item>\n" .
        "<title>Freecell Solver</title>\n" .
        "<link>http://fc-solve.berlios.de/</link>\n" .
        "<admin:generatorAgent rdf:resource=\"Spozilla 5.5\" />\n" .
        "</item>",
        '2.0 - item/[module] with known module'
    );
}
}

## Test the RSS 2.0 skipping-items condition.

{
    my $rss = create_rss_without_item({
        version => "2.0",
    });
    $rss->add_item(
        link  => "http://freshmeat.net/news/1999/06/21/930003829.html"
    );

    # TEST
    contains($rss, "<item>\n",
        '2.0 - Item without description or title is included'
    );
}

## Test the RSS 2.0 <source url= condition.
{
    # TEST:$num_iters=3;
    foreach my $s (
        [undef, "http://www.hercules.tld/",],
        ["Hercules", undef,],
        [undef, undef],
        )
    {
        my $rss = create_item_with_0_rss({version => "2.0",
                item_params => 
                [
                    title => "Foo&Bar",
                    link => "http://www.mylongtldyeahbaby/",
                    source => $s->[0],
                    sourceUrl => $s->[1],
                ],
            }
        );

        # TEST*$num_iters
        match_elements($rss, 'item', { title => 'Foo&amp;Bar', link => 'http://www.mylongtldyeahbaby/' });
=head1
        contains(
            $rss,
            ("<item>\n" .
             "<title>Foo&#x26;Bar</title>\n" .
             "<link>http://www.mylongtldyeahbaby/</link>\n" .
             "</item>"
             ),
            "2.0 - item - Source and/or Source URL are not defined",
        );
=cut
    }
}

{
    # Here we create an RSS 2.0 object and render it as the output
    # version "3.5" in order to test that version 1.0 is the default
    # version for output.
    my $rss = create_channel_rss({
            version => "2.0", 
            channel_params =>
            [copyright => "Martha", managingEditor => 0,],
            omit_date => 1,
        });
    $rss->{output} = "3.5";

    # TEST
    match_elements($rss, 'channel', { about => "http://freshmeat.net", title => "freshmeat.net", link => "http://freshmeat.net", description => "Linux software", 'dc:rights' => 'Martha', 'dc:publisher' => 0 });
=head1
    contains($rss, "<channel rdf:about=\"http://freshmeat.net\">\n" .
        "<title>freshmeat.net</title>\n" .
        "<link>http://freshmeat.net</link>\n" .
        "<description>Linux software</description>\n" .
        "<dc:rights>Martha</dc:rights>\n" .
        "<dc:publisher>0</dc:publisher>\n" .
        "<items>\n",
        "Unknown version renders as 1.0"
    );
=cut
}

{
    my $rss = eval {
        create_channel_rss({
            version => "0.91",
            image_link => undef,
            channel_params => [ title => undef ],
        });
    };

    # TEST
    ok ($@ =~ m{\AUndefined value in XML::RSS::LibXML::validate_accessor},
        "Undefined string throws an exception"
    );
}

SKIP:
{
    skip "TODO", 1;
    my $rss = create_channel_rss({
            version => "0.91",
            image_link => undef,
            channel_params => [ title => "Hello and <![CDATA[Aloha<&>]]>"],
        });

    # TEST
    contains($rss,
        "<title>Hello and <![CDATA[Aloha<&>]]></title>",
    );
}

################
### RSS Parsing Tests:
### We generate RSS and test that we get the same results.
################

sub parse_generated_rss
{
    my $args = shift;

    my $gen_func = $args->{'func'};

    my $rss_generator = $gen_func->($args);

    $rss_generator->{output} = $args->{version};

    my $output = $rss_generator->as_string();

    if ($args->{postproc})
    {
        $args->{postproc}->(\$output);
    }
    
    my $parser = XML::RSS::LibXML->new(version => $args->{version});

    $parser->parse($output);

    return $parser;
}

SKIP: {
    skip "TODO", 2; # Why 0.9, and forcing rdf:RDF -> rss ?
{
    my $rss =
        parse_generated_rss({
            func => \&create_textinput_with_0_rss,
            version => "0.9",
            textinput_params => [
                description => "Welcome to the Jungle.", 
                'link' => "http://fooque.tld/",
                'title' => "The Jungle of the City",
                'name' => "There's more than one way to do it.",
                ],
            postproc => sub {
                    for (${shift()})
                    {
                        s{(<rdf:RDF)[^>]*(>)}{<rss version="0.9">};
                        s{</rdf:RDF>}{</rss>};
                    }
            },
        });

    # TEST
    is ($rss->{textinput}->{description},
        "Welcome to the Jungle.",
        "0.9 parse - textinput/description",
    );

    # TEST
    is ($rss->{textinput}->{link},
        "http://fooque.tld/",
        "0.9 parse - textinput/link",
    );

    # TEST
    is ($rss->{textinput}->{title},
        "The Jungle of the City",
        "0.9 parse - textinput/title",
    );

    # TEST
    is ($rss->{textinput}->{name},
        "There's more than one way to do it.",
        "0.9 parse - textinput/name",
    );
}

{
    my $rss_parser =
        parse_generated_rss(
            {
                func => \&create_textinput_with_0_rss,
                version => "0.9",
                textinput_params => [
                    description => "Welcome to the Jungle.", 
                    'link' => "http://fooque.tld/",
                    'title' => "The Jungle of the City",
                    'name' => "There's more than one way to do it.",
                ],
                postproc => sub {
                    for (${shift()})
                    {
                        s{(<rdf:RDF)[^>]*(>)}{<rss version="0.9">};
                        s{</rdf:RDF>}{</rss>};
                        s{<(/?)textinput([^>]*)>}{<$1textInput$2>}g;
                    }   
                },
            }
        );

    # TEST
    is ($rss_parser->{textinput}->{description},
        "Welcome to the Jungle.",
        "0.9 parse - textinput/description",
    );

    # TEST
    is ($rss_parser->{textinput}->{link},
        "http://fooque.tld/",
        "Parse textInput (with capital I) - textinput/link",
    );

    # TEST
    is ($rss_parser->{textinput}->{title},
        "The Jungle of the City",
        "Parse textInput (with capital I) - textinput/title",
    );

    # TEST
    is ($rss_parser->{textinput}->{name},
        "There's more than one way to do it.",
        "Parse textInput (with capital I) - textinput/name",
    );
}
}

{
    my $rss_parser =
        parse_generated_rss(
            {
                func => \&create_textinput_with_0_rss,
                version => "0.9",
                textinput_params => [
                    description => "Welcome to the Jungle.", 
                    'link' => "http://fooque.tld/",
                    'title' => "The Jungle of the City",
                    'name' => "There's more than one way to do it.",
                ],
                postproc => sub {
                    for (${shift()})
                    {
                        s{<(/?)textinput([^>]+)?>}{sprintf('<%stextInput%s>', $1 || '', $2 || '')}ge
                    }
                },
            }
        );

    # TEST
    is ($rss_parser->{textinput}->{description},
        "Welcome to the Jungle.",
        "0.9 parse - textinput/description",
    );

    # TEST
    is ($rss_parser->{textinput}->{link},
        "http://fooque.tld/",
        "Parse textInput (with capital I) - textinput/link",
    );

    # TEST
    is ($rss_parser->{textinput}->{title},
        "The Jungle of the City",
        "Parse textInput (with capital I) - textinput/title",
    );

    # TEST
    is ($rss_parser->{textinput}->{name},
        "There's more than one way to do it.",
        "Parse textInput (with capital I) - textinput/name",
    )
}

{
    my $rss_parser =
        parse_generated_rss(
            {
                func => \&create_skipHours_rss,
                version => "0.91", 
                skipHours_params => [ hour => "5" ],
            }
        );

    # TEST
    is ($rss_parser->{skipHours}->{hour},
        "5",
        "Parse 0.91 - skipHours/hour",
    );
}

{
    my $rss_parser =
        parse_generated_rss(
            {
                func => \&create_skipHours_rss,
                version => "2.0", 
                skipHours_params => [ hour => "5" ],
            }
        );
    
    # TEST
    is ($rss_parser->{skipHours}->{hour},
        "5",
        "Parse 2.0 - skipHours/hour",
    );
}

## Test the skipDays parsing.

{
    my $rss_parser =
        parse_generated_rss(
            {
                func => \&create_skipDays_rss,
                version => "0.91", 
                skipDays_params => [ day => "5" ],
            }
        );

    # TEST
    is ($rss_parser->{skipDays}->{day},
        "5",
        "Parse 0.91 - skipDays/day",
    );
}

{
    my $rss_parser =
        parse_generated_rss(
            {
                func => \&create_skipDays_rss,
                version => "2.0", 
                skipDays_params => [ day => "5" ],
            }
        );

    # TEST
    is ($rss_parser->{skipDays}->{day},
        "5",
        "Parse 2.0 - skipDays/day",
    );
}

{
    my $rss_parser = XML::RSS::LibXML->new(version => "2.0");

    $rss_parser->parse(<<'EOF');
<?xml version="1.0" encoding="UTF-8"?>

<rss version="2.0"
 xmlns:blogChannel="http://backend.userland.com/blogChannelModule"
 xmlns:foo="http://foo.tld/foobar/"
>

<channel>
<title>Test 2.0 Feed</title>
<link>http://example.com/</link>
<description></description>
<language>en-us</language>
<copyright>Copyright 2002</copyright>
<pubDate>2007-01-19T14:21:43+0200</pubDate>
<lastBuildDate>2007-01-19T14:21:43+0200</lastBuildDate>
<docs>http://backend.userland.com/rss</docs>
<managingEditor>editor@example.com</managingEditor>
<webMaster>webmaster@example.com</webMaster>
<category>MyCategory</category>
<generator>XML::RSS::LibXML Test</generator>
<ttl>60</ttl>

<image>
<title>Test Image</title>
<url>http://example.com/example.gif</url>
<link>http://example.com/</link>
<height>25</height>
<description>Test Image</description>
<foo:hello>Hi there!</foo:hello>
</image>

<item>
<title>This is an item</title>
<link>http://example.com/2007/01/19</link>
<description>Yadda yadda yadda - R&#x26;D;</description>
<author>joeuser@example.com</author>
<category>MyCategory</category>
<comments>http://example.com/2007/01/19/comments.html</comments>
<guid isPermaLink="true">http://example.com/2007/01/19</guid>
<pubDate>Fri 19 Jan 2007 02:21:43 PM IST GMT</pubDate>
<source url="http://example.com">my brain</source>
<enclosure url="http://127.0.0.1/torrents/The_Passion_of_Dave_Winer.torrent" type="application/x-bittorrent" />
</item>

</channel>
</rss>
EOF

    # TEST
    is ($rss_parser->{image}->{"http://foo.tld/foobar/"}->{hello},
        "Hi there!",
        "Parsing 2.0 - element in a different namespace contained in image",
    );
}

SKIP:
{
    skip "TODO (null namespace)", 1;
    my $rss_parser = XML::RSS::LibXML->new(version => "1.0");

    $rss_parser->parse(<<'EOF');
<?xml version="1.0" encoding="UTF-8"?>

<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns="http://purl.org/rss/1.0/"
 xmlns:content="http://purl.org/rss/1.0/modules/content/"
 xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:syn="http://purl.org/rss/1.0/modules/syndication/"
 xmlns:my="http://purl.org/my/rss/module/"
 xmlns:admin="http://webns.net/mvcb/"
>

<channel rdf:about="http://example.com/">
<title>Test 1.0 Feed</title>
<link>http://example.com/</link>
<description>To lead by example</description>
<dc:date>2007-01-19T14:21:18+0200</dc:date>
<items>
 <rdf:Seq>
  <rdf:li rdf:resource="http://example.com/2007/01/19" />
 </rdf:Seq>
</items>
<image rdf:resource="http://example.com/example.gif" />
<textinput rdf:resource="http://example.com/search.pl" />
</channel>

<image rdf:about="http://example.com/example.gif" xmlns="">
<title>Test Image</title>
<url>http://example.com/example.gif</url>
<link>http://example.com/</link>
<foo>Aye Karamba</foo>
</image>

<item rdf:about="http://example.com/2007/01/19">
<title>This is an item</title>
<link>http://example.com/2007/01/19</link>
<description>Yadda &#x26; yadda &#x26; yadda</description>
<dc:creator>joeuser@example.com</dc:creator>
</item>

<textinput rdf:about="http://example.com/search.pl">
<title>Search</title>
<description>Search for an example</description>
<name>q</name>
<link>http://example.com/search.pl</link>
</textinput>

</rdf:RDF>
EOF

    # TEST
    is ($rss_parser->{image}->{""}->{foo},
        "Aye Karamba",
        "Parsing 1.0 - element in a null namespace contained in image",
    );
}

{
    my $rss_parser = XML::RSS::LibXML->new(version => "2.0");

    $rss_parser->parse(<<'EOF');
<?xml version="1.0" encoding="UTF-8"?>

<rss version="2.0"
 xmlns:blogChannel="http://backend.userland.com/blogChannelModule"
 xmlns:foo="http://foo.tld/foobar/"
>

<channel>
<title>Test 2.0 Feed</title>
<link>http://example.com/</link>
<description></description>
<language>en-us</language>
<copyright>Copyright 2002</copyright>
<pubDate>2007-01-19T14:21:43+0200</pubDate>
<lastBuildDate>2007-01-19T14:21:43+0200</lastBuildDate>
<docs>http://backend.userland.com/rss</docs>
<managingEditor>editor@example.com</managingEditor>
<webMaster>webmaster@example.com</webMaster>
<category>MyCategory</category>
<generator>XML::RSS::LibXML Test</generator>
<ttl>60</ttl>

<image>
<title>Test Image</title>
<url>http://example.com/example.gif</url>
<link>http://example.com/</link>
<height>25</height>
<description>Test Image</description>
</image>

<item>
<title>This is an item</title>
<link>http://example.com/2007/01/19</link>
<description>Yadda yadda yadda - R&#x26;D;</description>
<author>joeuser@example.com</author>
<category>MyCategory</category>
<comments>http://example.com/2007/01/19/comments.html</comments>
<guid isPermaLink="true">http://example.com/2007/01/19</guid>
<pubDate>Fri 19 Jan 2007 02:21:43 PM IST GMT</pubDate>
<source url="http://example.com">my brain</source>
<enclosure url="http://127.0.0.1/torrents/The_Passion_of_Dave_Winer.torrent" type="application/x-bittorrent" />
<foo:hello>Hi there!</foo:hello>
</item>

</channel>
</rss>
EOF

    # TEST
    is ($rss_parser->{items}->[0]->{"http://foo.tld/foobar/"}->{hello},
        "Hi there!",
        "Parsing 2.0 - element in a different namespace contained in an item",
    );
}

SKIP:
{
    skip "TODO (null namespace)", 1;
    my $rss_parser = XML::RSS::LibXML->new(version => "1.0");

    $rss_parser->parse(<<'EOF');
<?xml version="1.0" encoding="UTF-8"?>

<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns="http://purl.org/rss/1.0/"
 xmlns:alterrss="http://purl.org/rss/1.0/"
 xmlns:content="http://purl.org/rss/1.0/modules/content/"
 xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:syn="http://purl.org/rss/1.0/modules/syndication/"
 xmlns:my="http://purl.org/my/rss/module/"
 xmlns:admin="http://webns.net/mvcb/"
>

<channel rdf:about="http://example.com/">
<title>Test 1.0 Feed</title>
<link>http://example.com/</link>
<description>To lead by example</description>
<dc:date>2007-01-19T14:21:18+0200</dc:date>
<items>
 <rdf:Seq>
  <rdf:li rdf:resource="http://example.com/2007/01/19" />
 </rdf:Seq>
</items>
<image rdf:resource="http://example.com/example.gif" />
<textinput rdf:resource="http://example.com/search.pl" />
</channel>

<image rdf:about="http://example.com/example.gif">
<title>Test Image</title>
<url>http://example.com/example.gif</url>
<link>http://example.com/</link>
</image>

<alterrss:item rdf:about="http://example.com/2007/01/19" xmlns="">
<title>This is an item</title>
<link>http://example.com/2007/01/19</link>
<description>Yadda &#x26; yadda &#x26; yadda</description>
<dc:creator>joeuser@example.com</dc:creator>
<foo>Aye Karamba</foo>
</alterrss:item>

<textinput rdf:about="http://example.com/search.pl">
<title>Search</title>
<description>Search for an example</description>
<name>q</name>
<link>http://example.com/search.pl</link>
</textinput>

</rdf:RDF>
EOF

    # TEST
    is ($rss_parser->{items}->[0]->{""}->{foo},
        "Aye Karamba",
        "Parsing 1.0 - element in a null namespace contained in image",
    );
}

{
    my $rss_parser = XML::RSS::LibXML->new(version => "2.0");

    $rss_parser->parse(<<'EOF');
<?xml version="1.0" encoding="UTF-8"?>

<rss version="2.0"
 xmlns:blogChannel="http://backend.userland.com/blogChannelModule"
 xmlns:foo="http://foo.tld/foobar/"
>

<channel>
<title>Test 2.0 Feed</title>
<link>http://example.com/</link>
<description></description>
<language>en-us</language>
<copyright>Copyright 2002</copyright>
<pubDate>2007-01-19T14:21:43+0200</pubDate>
<lastBuildDate>2007-01-19T14:21:43+0200</lastBuildDate>
<docs>http://backend.userland.com/rss</docs>
<managingEditor>editor@example.com</managingEditor>
<webMaster>webmaster@example.com</webMaster>
<category>MyCategory</category>
<generator>XML::RSS::LibXML Test</generator>
<ttl>60</ttl>

<image>
<title>Test Image</title>
<url>http://example.com/example.gif</url>
<link>http://example.com/</link>
<height>25</height>
<description>Test Image</description>
</image>

<item>
<title>This is an item</title>
<link>http://example.com/2007/01/19</link>
<description>Yadda yadda yadda - R&#x26;D;</description>
<author>joeuser@example.com</author>
<category>MyCategory</category>
<comments>http://example.com/2007/01/19/comments.html</comments>
<guid isPermaLink="true">http://example.com/2007/01/19</guid>
<pubDate>Fri 19 Jan 2007 02:21:43 PM IST GMT</pubDate>
<source url="http://example.com">my brain</source>
<enclosure url="http://127.0.0.1/torrents/The_Passion_of_Dave_Winer.torrent" type="application/x-bittorrent" />
</item>

<textInput>
<title>Search</title>
<description>Search for an example</description>
<name>q</name>
<link>http://example.com/search.pl</link>
<foo:hello>Show Baloon</foo:hello>
</textInput>

</channel>
</rss>
EOF

    # TEST
    is ($rss_parser->{textinput}->{"http://foo.tld/foobar/"}->{hello},
        "Show Baloon",
        "Parsing 2.0 - element in a different namespace contained in a textinput",
    );
}

SKIP:
{
    skip "TODO (null namespace)", 1;
    my $rss_parser = XML::RSS::LibXML->new(version => "1.0");

    $rss_parser->parse(<<'EOF');
<?xml version="1.0" encoding="UTF-8"?>

<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns="http://purl.org/rss/1.0/"
 xmlns:alterrss="http://purl.org/rss/1.0/"
 xmlns:content="http://purl.org/rss/1.0/modules/content/"
 xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:syn="http://purl.org/rss/1.0/modules/syndication/"
 xmlns:my="http://purl.org/my/rss/module/"
 xmlns:admin="http://webns.net/mvcb/"
>

<channel rdf:about="http://example.com/">
<title>Test 1.0 Feed</title>
<link>http://example.com/</link>
<description>To lead by example</description>
<dc:date>2007-01-19T14:21:18+0200</dc:date>
<items>
 <rdf:Seq>
  <rdf:li rdf:resource="http://example.com/2007/01/19" />
 </rdf:Seq>
</items>
<image rdf:resource="http://example.com/example.gif" />
<textinput rdf:resource="http://example.com/search.pl" />
</channel>

<image rdf:about="http://example.com/example.gif">
<title>Test Image</title>
<url>http://example.com/example.gif</url>
<link>http://example.com/</link>
</image>

<item rdf:about="http://example.com/2007/01/19">
<title>This is an item</title>
<link>http://example.com/2007/01/19</link>
<description>Yadda &#x26; yadda &#x26; yadda</description>
<dc:creator>joeuser@example.com</dc:creator>
</item>

<textinput rdf:about="http://example.com/search.pl" xmlns="">
<title>Search</title>
<description>Search for an example</description>
<name>q</name>
<link>http://example.com/search.pl</link>
<foo>Priceless</foo>
</textinput>

</rdf:RDF>
EOF

    # TEST
    is ($rss_parser->{textinput}->{""}->{foo},
        "Priceless",
        "Parsing 1.0 - element in a null namespace contained in a textinput",
    );
}

{
    my $rss_parser = XML::RSS::LibXML->new(version => "2.0");

    $rss_parser->parse(<<'EOF');
<?xml version="1.0" encoding="UTF-8"?>

<rss version="2.0"
 xmlns:blogChannel="http://backend.userland.com/blogChannelModule"
 xmlns:foo="http://foo.tld/foobar/"
>

<channel>
<title>Test 2.0 Feed</title>
<link>http://example.com/</link>
<description></description>
<language>en-us</language>
<copyright>Copyright 2002</copyright>
<pubDate>2007-01-19T14:21:43+0200</pubDate>
<lastBuildDate>2007-01-19T14:21:43+0200</lastBuildDate>
<docs>http://backend.userland.com/rss</docs>
<managingEditor>editor@example.com</managingEditor>
<webMaster>webmaster@example.com</webMaster>
<category>MyCategory</category>
<generator>XML::RSS::LibXML Test</generator>
<ttl>60</ttl>
<foo:hello>The RSS Must Flow</foo:hello>

<image>
<title>Test Image</title>
<url>http://example.com/example.gif</url>
<link>http://example.com/</link>
<height>25</height>
<description>Test Image</description>
</image>

<item>
<title>This is an item</title>
<link>http://example.com/2007/01/19</link>
<description>Yadda yadda yadda - R&#x26;D;</description>
<author>joeuser@example.com</author>
<category>MyCategory</category>
<comments>http://example.com/2007/01/19/comments.html</comments>
<guid isPermaLink="true">http://example.com/2007/01/19</guid>
<pubDate>Fri 19 Jan 2007 02:21:43 PM IST GMT</pubDate>
<source url="http://example.com">my brain</source>
<enclosure url="http://127.0.0.1/torrents/The_Passion_of_Dave_Winer.torrent" type="application/x-bittorrent" />
</item>

<textInput>
<title>Search</title>
<description>Search for an example</description>
<name>q</name>
<link>http://example.com/search.pl</link>
</textInput>

</channel>
</rss>
EOF

    # TEST
    is ($rss_parser->{channel}->{"http://foo.tld/foobar/"}->{hello},
        "The RSS Must Flow",
        "Parsing 2.0 - element in a different namespace contained in a channel",
    );
}

SKIP:
{
    skip "TODO", 1;
    my $rss_parser = XML::RSS::LibXML->new(version => "1.0");

    $rss_parser->parse(<<'EOF');
<?xml version="1.0" encoding="UTF-8"?>

<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns="http://purl.org/rss/1.0/"
 xmlns:alterrss="http://purl.org/rss/1.0/"
 xmlns:content="http://purl.org/rss/1.0/modules/content/"
 xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:syn="http://purl.org/rss/1.0/modules/syndication/"
 xmlns:my="http://purl.org/my/rss/module/"
 xmlns:admin="http://webns.net/mvcb/"
>

<channel rdf:about="http://example.com/" xmlns="">
<title>Test 1.0 Feed</title>
<link>http://example.com/</link>
<description>To lead by example</description>
<dc:date>2007-01-19T14:21:18+0200</dc:date>
<items>
 <rdf:Seq>
  <rdf:li rdf:resource="http://example.com/2007/01/19" />
 </rdf:Seq>
</items>
<image rdf:resource="http://example.com/example.gif" />
<textinput rdf:resource="http://example.com/search.pl" />
<foo>Placebo is here</foo>
</channel>

<image rdf:about="http://example.com/example.gif">
<title>Test Image</title>
<url>http://example.com/example.gif</url>
<link>http://example.com/</link>
</image>

<item rdf:about="http://example.com/2007/01/19">
<title>This is an item</title>
<link>http://example.com/2007/01/19</link>
<description>Yadda &#x26; yadda &#x26; yadda</description>
<dc:creator>joeuser@example.com</dc:creator>
</item>

<textinput rdf:about="http://example.com/search.pl">
<title>Search</title>
<description>Search for an example</description>
<name>q</name>
<link>http://example.com/search.pl</link>
</textinput>

</rdf:RDF>
EOF

    # TEST
    is ($rss_parser->{channel}->{""}->{foo},
        "Placebo is here",
        "Parsing 1.0 - element in a null namespace contained in a channel",
    );
}

{
    my $rss_parser = XML::RSS::LibXML->new(version => "1.0");

    $rss_parser->parse(<<'EOF');
<?xml version="1.0" encoding="UTF-8"?>

<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns="http://purl.org/rss/1.0/"
 xmlns:content="http://purl.org/rss/1.0/modules/content/"
 xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:syn="http://purl.org/rss/1.0/modules/syndication/"
 xmlns:admin="http://webns.net/mvcb/"
>

<channel rdf:about="http://freshmeat.net">
<title>freshmeat.net</title>
<link>http://freshmeat.net</link>
<description>Linux software</description>
<items>
 <rdf:Seq>
  <rdf:li rdf:resource="http://freshmeat.net/news/1999/06/21/930003829.html" />
  <rdf:li rdf:resource="http://jungle.tld/Enter/" />
 </rdf:Seq>
</items>
</channel>

<item rdf:about="http://freshmeat.net/news/1999/06/21/930003829.html">
<title>GTKeyboard 0.85</title>
<link>http://freshmeat.net/news/1999/06/21/930003829.html</link>
</item>

<item rdf:about="http://jungle.tld/Enter/">
<title>In the Jungle</title>
<link>http://jungle.tld/Enter/</link>
<taxo:topics>
  <rdf:Bag>
    <rdf:li resource="Foo" />
    <rdf:li resource="Loom" />
    <rdf:li resource="Hello" />
    <rdf:li resource="myowA" />
  </rdf:Bag>
</taxo:topics>
</item>

</rdf:RDF>
EOF

    # TEST
    is_deeply ($rss_parser->{items}->[1]->{taxo},
        ["Foo", "Loom", "Hello", "myowA"],
        "Parsing 1.0 - taxo items",
    );
}

{
    my $rss_parser = XML::RSS::LibXML->new(version => "1.0");

    $rss_parser->parse(<<'EOF');
<?xml version="1.0" encoding="UTF-8"?>

<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns="http://purl.org/rss/1.0/"
 xmlns:content="http://purl.org/rss/1.0/modules/content/"
 xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:syn="http://purl.org/rss/1.0/modules/syndication/"
 xmlns:admin="http://webns.net/mvcb/"
>

<channel rdf:about="http://freshmeat.net">
<title>freshmeat.net</title>
<link>http://freshmeat.net</link>
<description>Linux software</description>
<items>
 <rdf:Seq>
  <rdf:li rdf:resource="http://freshmeat.net/news/1999/06/21/930003829.html" />
  <rdf:li rdf:resource="http://jungle.tld/Enter/" />
 </rdf:Seq>
</items>
</channel>

<item rdf:about="http://freshmeat.net/news/1999/06/21/930003829.html">
<title>GTKeyboard 0.85</title>
<link>http://freshmeat.net/news/1999/06/21/930003829.html</link>
</item>

<item rdf:about="http://jungle.tld/Enter/">
<title>In the Jungle</title>
<link>http://jungle.tld/Enter/</link>
<taxo:topics>
  <rdf:Bag>
    <rdf:li resource="Everybody" />
    <rdf:li resource="needs" />
    <dc:hello />
    <rdf:li resource="a" />
    <rdf:li resource="[[[HUG]]]" />
  </rdf:Bag>
</taxo:topics>
</item>

</rdf:RDF>
EOF

    # TEST
    is_deeply ($rss_parser->{items}->[1]->{taxo},
        ["Everybody", "needs", "a", "[[[HUG]]]"],
        "Parsing 1.0 - taxo bag in <item> with junk elements",
    );
}

{
    my $rss_parser = XML::RSS::LibXML->new(version => "1.0");

    $rss_parser->parse(<<'EOF');
<?xml version="1.0" encoding="UTF-8"?>

<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns="http://purl.org/rss/1.0/"
 xmlns:content="http://purl.org/rss/1.0/modules/content/"
 xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:syn="http://purl.org/rss/1.0/modules/syndication/"
 xmlns:admin="http://webns.net/mvcb/"
>

<channel rdf:about="http://freshmeat.net">
<title>freshmeat.net</title>
<link>http://freshmeat.net</link>
<description>Linux software</description>
<items>
 <rdf:Seq>
  <rdf:li rdf:resource="http://freshmeat.net/news/1999/06/21/930003829.html" />
  <rdf:li rdf:resource="http://jungle.tld/Enter/" />
 </rdf:Seq>
</items>
<taxo:topics>
  <rdf:Bag>
    <rdf:li resource="Elastic" />
    <rdf:li resource="Plastic" />
    <rdf:li resource="stochastic" />
    <rdf:li resource="dynamic^^K" />
  </rdf:Bag>
</taxo:topics>
</channel>

<item rdf:about="http://freshmeat.net/news/1999/06/21/930003829.html">
<title>GTKeyboard 0.85</title>
<link>http://freshmeat.net/news/1999/06/21/930003829.html</link>
</item>

<item rdf:about="http://jungle.tld/Enter/">
<title>In the Jungle</title>
<link>http://jungle.tld/Enter/</link>
<taxo:topics>
  <rdf:Bag>
    <rdf:li resource="Foo" />
    <rdf:li resource="Loom" />
    <rdf:li resource="Hello" />
    <rdf:li resource="myowA" />
  </rdf:Bag>
</taxo:topics>
</item>

</rdf:RDF>
EOF

    # TEST
    is_deeply ($rss_parser->{channel}->{taxo},
        ["Elastic", "Plastic", "stochastic", "dynamic^^K"],
        "Parsing 1.0 - taxo items in channel",
    );
}

{
    my $rss_parser = XML::RSS::LibXML->new(version => "1.0");

    $rss_parser->parse(<<'EOF');
<?xml version="1.0" encoding="UTF-8"?>

<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns="http://purl.org/rss/1.0/"
 xmlns:content="http://purl.org/rss/1.0/modules/content/"
 xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:syn="http://purl.org/rss/1.0/modules/syndication/"
 xmlns:admin="http://webns.net/mvcb/"
>

<channel rdf:about="http://freshmeat.net">
<title>freshmeat.net</title>
<link>http://freshmeat.net</link>
<description>Linux software</description>
<items>
 <rdf:Seq>
  <rdf:li rdf:resource="http://freshmeat.net/news/1999/06/21/930003829.html" />
  <rdf:li rdf:resource="http://jungle.tld/Enter/" />
 </rdf:Seq>
</items>
<taxo:topics>
  <rdf:Bag>
    <rdf:li resource="Elastic" />
    <rdf:li resource="Plastic" />
    <rdf:li resource="stochastic" />
    <dc:hello />
    <rdf:li resource="dynamic^^K" />
  </rdf:Bag>
</taxo:topics>
</channel>

<item rdf:about="http://freshmeat.net/news/1999/06/21/930003829.html">
<title>GTKeyboard 0.85</title>
<link>http://freshmeat.net/news/1999/06/21/930003829.html</link>
</item>

<item rdf:about="http://jungle.tld/Enter/">
<title>In the Jungle</title>
<link>http://jungle.tld/Enter/</link>
<taxo:topics>
  <rdf:Bag>
    <rdf:li resource="Foo" />
    <rdf:li resource="Loom" />
    <rdf:li resource="Hello" />
    <rdf:li resource="myowA" />
  </rdf:Bag>
</taxo:topics>
</item>

</rdf:RDF>
EOF

    # TEST
    is_deeply ($rss_parser->{channel}->{taxo},
        ["Elastic", "Plastic", "stochastic", "dynamic^^K"],
        "Parsing 1.0 - taxo items in channel with junk items",
    );
}

{
    my $rss_parser = XML::RSS::LibXML->new(version => "1.0");

    $rss_parser->parse(<<'EOF');
<?xml version="1.0" encoding="UTF-8"?>

<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns="http://purl.org/rss/1.0/"
 xmlns:content="http://purl.org/rss/1.0/modules/content/"
 xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:syn="http://purl.org/rss/1.0/modules/syndication/"
 xmlns:admin="http://webns.net/mvcb/"
>

<channel rdf:about="http://freshmeat.net">
<title>freshmeat.net</title>
<link>http://freshmeat.net</link>
<description>Linux software</description>
<items>
 <rdf:Seq>
  <rdf:li rdf:resource="http://freshmeat.net/news/1999/06/21/930003829.html" />
  <rdf:li rdf:resource="http://jungle.tld/Enter/" />
 </rdf:Seq>
</items>
<taxo:topics>
  <rdf:Bag>
    <rdf:li resource="Elastic" />
    <rdf:li resource="Plastic" />
    <rdf:li resource="stochastic" />
    <dc:hello />
    <rdf:li resource="dynamic^^K" />
  </rdf:Bag>
</taxo:topics>
</channel>

<item rdf:about="http://freshmeat.net/news/1999/06/21/930003829.html">
<title>GTKeyboard 0.85</title>
<link>http://freshmeat.net/news/1999/06/21/930003829.html</link>
</item>

<item rdf:about="http://jungle.tld/Enter/">
<title>In the Jungle</title>
<link>http://jungle.tld/Enter/</link>
<admin:hello>Gow</admin:hello>
</item>

</rdf:RDF>
EOF

    # TEST
    is ($rss_parser->{items}->[1]->{"http://webns.net/mvcb/"}->{hello},
        "Gow",
        "Parsing 1.0 - Elements inside <item> that don't exist in \%rdf_resource_fields",
    );
}

{
    my $rss_parser = XML::RSS::LibXML->new(version => "1.0");

    $rss_parser->parse(<<'EOF');
<?xml version="1.0" encoding="UTF-8"?>

<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns="http://purl.org/rss/1.0/"
 xmlns:content="http://purl.org/rss/1.0/modules/content/"
 xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:syn="http://purl.org/rss/1.0/modules/syndication/"
 xmlns:admin="http://webns.net/mvcb/"
>

<channel rdf:about="http://freshmeat.net">
<title>freshmeat.net</title>
<link>http://freshmeat.net</link>
<description>Linux software</description>
<items>
 <rdf:Seq>
  <rdf:li rdf:resource="http://freshmeat.net/news/1999/06/21/930003829.html" />
  <rdf:li rdf:resource="http://jungle.tld/Enter/" />
 </rdf:Seq>
</items>
<taxo:topics>
  <rdf:Bag>
    <rdf:li resource="Elastic" />
    <rdf:li resource="Plastic" />
    <rdf:li resource="stochastic" />
    <dc:hello />
    <rdf:li resource="dynamic^^K" />
  </rdf:Bag>
</taxo:topics>
</channel>

<admin:generatorAgent>Gow</admin:generatorAgent>
<item rdf:about="http://freshmeat.net/news/1999/06/21/930003829.html">
<title>GTKeyboard 0.85</title>
<link>http://freshmeat.net/news/1999/06/21/930003829.html</link>
</item>

<item rdf:about="http://jungle.tld/Enter/">
<title>In the Jungle</title>
<link>http://jungle.tld/Enter/</link>
</item>

</rdf:RDF>
EOF

    # TEST
    ok ((!grep { exists($_->{"http://webns.net/mvcb/"}->{generatorAgent}) }
        @{$rss_parser->{items}}),
        "Parsing 1.0 - Elements that exist in \%rdf_resource_fields but not inside item",
    );
}

{
    my $rss_parser = XML::RSS::LibXML->new(version => "1.0");

    $rss_parser->parse(<<'EOF');
<?xml version="1.0" encoding="UTF-8"?>

<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns="http://purl.org/rss/1.0/"
 xmlns:content="http://purl.org/rss/1.0/modules/content/"
 xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:syn="http://purl.org/rss/1.0/modules/syndication/"
 xmlns:admin="http://webns.net/mvcb/"
>

<channel rdf:about="http://freshmeat.net">
<title>freshmeat.net</title>
<link>http://freshmeat.net</link>
<description>Linux software</description>
<items>
 <rdf:Seq>
  <rdf:li rdf:resource="http://freshmeat.net/news/1999/06/21/930003829.html" />
  <rdf:li rdf:resource="http://jungle.tld/Enter/" />
 </rdf:Seq>
</items>
<taxo:topics>
  <rdf:Bag>
    <rdf:li resource="Elastic" />
    <rdf:li resource="Plastic" />
    <rdf:li resource="stochastic" />
    <dc:hello />
    <rdf:li resource="dynamic^^K" />
  </rdf:Bag>
</taxo:topics>
</channel>

<item rdf:about="http://freshmeat.net/news/1999/06/21/930003829.html">
<title>GTKeyboard 0.85</title>
<link>http://freshmeat.net/news/1999/06/21/930003829.html</link>
</item>

<item rdf:about="http://jungle.tld/Enter/">
<title>In the Jungle</title>
<link>http://jungle.tld/Enter/</link>
</item>
<enclosure foo="bar" good="them" />

</rdf:RDF>
EOF

    # TEST
    ok ((!grep { exists($_->{enclosure}) }
        @{$rss_parser->{items}}),
        "Parsing 1.0 - Testing \%empty_ok_elements",
    );
}

{
    my $rss_parser = XML::RSS::LibXML->new(version => "1.0");

    $rss_parser->parse(<<'EOF');
<?xml version="1.0" encoding="UTF-8"?>

<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns="http://purl.org/rss/1.0/"
 xmlns:content="http://purl.org/rss/1.0/modules/content/"
 xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:syn="http://purl.org/rss/1.0/modules/syndication/"
 xmlns:admin="http://webns.net/mvcb/"
 xmlns:foo="http://foobar.tld/foobardom/"
>

<channel rdf:about="http://freshmeat.net">
<title>freshmeat.net</title>
<link>http://freshmeat.net</link>
<description>Linux software</description>
<items>
 <rdf:Seq>
  <rdf:li rdf:resource="http://freshmeat.net/news/1999/06/21/930003829.html" />
  <rdf:li rdf:resource="http://jungle.tld/Enter/" />
 </rdf:Seq>
</items>
<taxo:topics>
  <rdf:Bag>
    <rdf:li resource="Elastic" />
    <rdf:li resource="Plastic" />
    <rdf:li resource="stochastic" />
    <rdf:li resource="dynamic^^K" />
  </rdf:Bag>
</taxo:topics>
</channel>

<item rdf:about="http://freshmeat.net/news/1999/06/21/930003829.html">
<title>GTKeyboard 0.85</title>
<link>http://freshmeat.net/news/1999/06/21/930003829.html</link>
</item>

<foo:item rdf:about="http://jungle.tld/Enter/">
<title>In the Jungle</title>
<link>http://jungle.tld/Enter/</link>
</foo:item>

</rdf:RDF>
EOF

    # TEST
    is (scalar(@{$rss_parser->{items}}), 1, "Parse 1.0 with item in a different NS - There is 1 item");

    # TEST
    is ($rss_parser->{items}->[0]->{title}, "GTKeyboard 0.85", "Parse 1.0 with item in a different NS - it is not the item in the other NS");
}

{
    my $rss_parser = XML::RSS::LibXML->new(version => "1.0");

    $rss_parser->parse(<<'EOF');
<?xml version="1.0" encoding="UTF-8"?>

<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns="http://purl.org/rss/1.0/"
 xmlns:content="http://purl.org/rss/1.0/modules/content/"
 xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:syn="http://purl.org/rss/1.0/modules/syndication/"
 xmlns:admin="http://webns.net/mvcb/"
 xmlns:foo="http://foobar.tld/foobardom/"
>

<channel rdf:about="http://freshmeat.net">
<title>freshmeat.net</title>
<link>http://freshmeat.net</link>
<description>Linux software</description>
<items>
 <rdf:Seq>
  <rdf:li rdf:resource="http://freshmeat.net/news/1999/06/21/930003829.html" />
  <rdf:li rdf:resource="http://jungle.tld/Enter/" />
 </rdf:Seq>
</items>
<taxo:topics>
  <rdf:Bag>
    <rdf:li resource="Elastic" />
    <rdf:li resource="Plastic" />
    <rdf:li resource="stochastic" />
    <rdf:li resource="dynamic^^K" />
  </rdf:Bag>
</taxo:topics>
</channel>

<item xmlns="">
<title>In the Jungle</title>
<link>http://jungle.tld/Enter/</link>
</item>

</rdf:RDF>
EOF

    # TEST
    is (scalar(@{$rss_parser->{items}}), 0, "Parse 1.0 with item in null namespace");
}

{
    my $rss_parser = XML::RSS::LibXML->new(version => "1.0");

    $rss_parser->parse(<<'EOF');
<?xml version="1.0" encoding="UTF-8"?>

<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns="http://purl.org/rss/1.0/"
 xmlns:content="http://purl.org/rss/1.0/modules/content/"
 xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:syn="http://purl.org/rss/1.0/modules/syndication/"
 xmlns:my="http://purl.org/my/rss/module/"
 xmlns:admin="http://webns.net/mvcb/"
>

<channel rdf:about="http://example.com/">
<title>Test 1.0 Feed</title>
<link>http://example.com/</link>
<description>To lead by example</description>
<dc:date>2007-01-19T14:21:18+0200</dc:date>
<items>
 <rdf:Seq>
  <rdf:li rdf:resource="http://example.com/2007/01/19" />
 </rdf:Seq>
</items>
<image rdf:resource="http://example.com/example.gif" />
<textinput rdf:resource="http://example.com/search.pl" />
</channel>

<image rdf:about="http://example.com/example.gif" xmlns="">
<title>Test Image</title>
<url>http://example.com/example.gif</url>
<link>http://example.com/</link>
<dc:date>5 Sep 2006</dc:date>
</image>

<item rdf:about="http://example.com/2007/01/19">
<title>This is an item</title>
<link>http://example.com/2007/01/19</link>
<description>Yadda &#x26; yadda &#x26; yadda</description>
<dc:creator>joeuser@example.com</dc:creator>
</item>

<textinput rdf:about="http://example.com/search.pl">
<title>Search</title>
<description>Search for an example</description>
<name>q</name>
<link>http://example.com/search.pl</link>
</textinput>

</rdf:RDF>
EOF

    # TEST
    is ($rss_parser->{image}->{dc}->{date},
        "5 Sep 2006",
        "Parsing 1.0 - Known module in image",
    );
}

{
    my $rss_parser = XML::RSS::LibXML->new(version => "1.0");

    $rss_parser->parse(<<'EOF');
<?xml version="1.0" encoding="UTF-8"?>

<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns="http://purl.org/rss/1.0/"
 xmlns:content="http://purl.org/rss/1.0/modules/content/"
 xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:syn="http://purl.org/rss/1.0/modules/syndication/"
 xmlns:my="http://purl.org/my/rss/module/"
 xmlns:admin="http://webns.net/mvcb/"
>

<channel rdf:about="http://example.com/">
<title>Test 1.0 Feed</title>
<link>http://example.com/</link>
<description>To lead by example</description>
<dc:date>2007-01-19T14:21:18+0200</dc:date>
<items>
 <rdf:Seq>
  <rdf:li rdf:resource="http://example.com/2007/01/19" />
 </rdf:Seq>
</items>
<image rdf:resource="http://example.com/example.gif" />
<textinput rdf:resource="http://example.com/search.pl" />
</channel>

<image rdf:about="http://example.com/example.gif" xmlns="">
<title>Test Image</title>
<url>http://example.com/example.gif</url>
<link>http://example.com/</link>
</image>

<item rdf:about="http://example.com/2007/01/19">
<title>This is an item</title>
<link>http://example.com/2007/01/19</link>
<description>Yadda &#x26; yadda &#x26; yadda</description>
<dc:creator>joeuser@example.com</dc:creator>
</item>

<textinput rdf:about="http://example.com/search.pl">
<title>Search</title>
<description>Search for an example</description>
<name>q</name>
<link>http://example.com/search.pl</link>
<dc:date>5 May 1977</dc:date>
</textinput>

</rdf:RDF>
EOF

    # TEST
    is ($rss_parser->{textinput}->{dc}->{date},
        "5 May 1977",
        "Parsing 1.0 - Known module in a textinput",
    );
}

SKIP:
{
    skip "TODO", 1;
    my $rss_parser = XML::RSS::LibXML->new(version => "2.0");

my $xml_text = <<'EOF';
<?xml version="1.0" encoding="UTF-8"?>

<rss
 xmlns:blogChannel="http://backend.userland.com/blogChannelModule"
 xmlns:foo="http://foo.tld/foobar/"
>

<channel>
<title>Test 2.0 Feed</title>
<link>http://example.com/</link>
<description></description>
<language>en-us</language>
<copyright>Copyright 2002</copyright>
<pubDate>2007-01-19T14:21:43+0200</pubDate>
<lastBuildDate>2007-01-19T14:21:43+0200</lastBuildDate>
<docs>http://backend.userland.com/rss</docs>
<managingEditor>editor@example.com</managingEditor>
<webMaster>webmaster@example.com</webMaster>
<category>MyCategory</category>
<generator>XML::RSS::LibXML Test</generator>
<ttl>60</ttl>

<image>
<title>Test Image</title>
<url>http://example.com/example.gif</url>
<link>http://example.com/</link>
<height>25</height>
<description>Test Image</description>
<foo:hello>Hi there!</foo:hello>
</image>

<item>
<title>This is an item</title>
<link>http://example.com/2007/01/19</link>
<description>Yadda yadda yadda - R&#x26;D;</description>
<author>joeuser@example.com</author>
<category>MyCategory</category>
<comments>http://example.com/2007/01/19/comments.html</comments>
<guid isPermaLink="true">http://example.com/2007/01/19</guid>
<pubDate>Fri 19 Jan 2007 02:21:43 PM IST GMT</pubDate>
<source url="http://example.com">my brain</source>
<enclosure url="http://127.0.0.1/torrents/The_Passion_of_Dave_Winer.torrent" type="application/x-bittorrent" />
</item>

</channel>
</rss>
EOF

    eval {
        $rss_parser->parse($xml_text);
    };

    # TEST
    ok ($@ =~ m{\AMalformed RSS},
        "Checking for thrown exception on missing version attribute"
    );
}

SKIP:
{
    skip "TODO", 1;
    my $rss_parser = XML::RSS::LibXML->new(version => "1.0");

    my $xml_text = <<'EOF';
<?xml version="1.0" encoding="UTF-8"?>

<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns:content="http://purl.org/rss/1.0/modules/content/"
 xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:syn="http://purl.org/rss/1.0/modules/syndication/"
 xmlns:my="http://purl.org/my/rss/module/"
 xmlns:admin="http://webns.net/mvcb/"
>

<channel rdf:about="http://example.com/">
<title>Test 1.0 Feed</title>
<link>http://example.com/</link>
<description>To lead by example</description>
<dc:date>2007-01-19T14:21:18+0200</dc:date>
<items>
 <rdf:Seq>
  <rdf:li rdf:resource="http://example.com/2007/01/19" />
 </rdf:Seq>
</items>
<image rdf:resource="http://example.com/example.gif" />
<textinput rdf:resource="http://example.com/search.pl" />
</channel>

<image rdf:about="http://example.com/example.gif" xmlns="">
<title>Test Image</title>
<url>http://example.com/example.gif</url>
<link>http://example.com/</link>
</image>

<item rdf:about="http://example.com/2007/01/19">
<title>This is an item</title>
<link>http://example.com/2007/01/19</link>
<description>Yadda &#x26; yadda &#x26; yadda</description>
<dc:creator>joeuser@example.com</dc:creator>
</item>

<textinput rdf:about="http://example.com/search.pl">
<title>Search</title>
<description>Search for an example</description>
<name>q</name>
<link>http://example.com/search.pl</link>
<dc:date>5 May 1977</dc:date>
</textinput>

</rdf:RDF>
EOF

    eval {
        $rss_parser->parse($xml_text);
    };

    # TEST
    ok ($@ =~ m{\AMalformed RSS: invalid version},
        "Checking for thrown exception on missing version attribute"
    );

}

{
    my $rss_parser = XML::RSS::LibXML->new(version => "1.0");

    $rss_parser->parse(<<'EOF');
<?xml version="1.0" encoding="UTF-8"?>

<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns="http://purl.org/rss/1.0/"
 xmlns:content="http://purl.org/rss/1.0/modules/content/"
 xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:syn="http://purl.org/rss/1.0/modules/syndication/"
 xmlns:admin="http://webns.net/mvcb/"
 xmlns:foo="http://foobar.tld/foobardom/"
>

<channel rdf:about="http://freshmeat.net">
<title>freshmeat.net</title>
<link>http://freshmeat.net</link>
<description>Linux software</description>
<items>
 <rdf:Seq>
  <rdf:li rdf:resource="http://freshmeat.net/news/1999/06/21/930003829.html" />
  <rdf:li rdf:resource="http://jungle.tld/Enter/" />
 </rdf:Seq>
</items>
<taxo:topics>
  <rdf:Bag>
    <rdf:li resource="Elastic" />
    <rdf:li resource="Plastic" />
    <rdf:li resource="stochastic" />
    <rdf:li resource="dynamic^^K" />
  </rdf:Bag>
</taxo:topics>
</channel>

<item rdf:about="http://freshmeat.net/news/1999/06/21/930003829.html">
<title>GTKeyboard 0.85</title>
<link>http://freshmeat.net/news/1999/06/21/930003829.html</link>
<item rdf:about="http://fooque.tld/">
</item>
</item>
</rdf:RDF>
EOF

    # TEST
    is (scalar(@{$rss_parser->{items}}), 1, "Parse 1.0 with nested <item>");
}

{
    my $rss_parser = XML::RSS::LibXML->new(version => "2.0");

my $xml_text = <<'EOF';
<?xml version="1.0" encoding="UTF-8"?>

<rss version="2.0"
 xmlns:blogChannel="http://backend.userland.com/blogChannelModule"
 xmlns:foo="http://foo.tld/foobar/"
 xmlns:anno="http://purl.org/rss/1.0/modules/annotate/"
>

<channel>
<title>Test 2.0 Feed</title>
<link>http://example.com/</link>
<description>Lambda</description>
<anno:reference resource="Aloha" />

</channel>
</rss>
EOF

    $rss_parser->parse($xml_text);

    my $channel = $rss_parser->{channel};

    is($channel->{description}, "Lambda", "Testing for non-moduled-namespaced element inside the channel (description)");
    is($channel->{"http://purl.org/rss/1.0/modules/annotate/"}{reference}, "Aloha", "Testing for non-moduled-namespacedelement inside the channel (reference)");
}

{
    my $rss_parser = XML::RSS::LibXML->new(version => "2.0");

my $xml_text = <<'EOF';
<?xml version="1.0" encoding="UTF-8"?>

<rss version="2.0"
 xmlns:blogChannel="http://backend.userland.com/blogChannelModule"
 xmlns:foo="http://foo.tld/foobar/"
 xmlns:anno="http://purl.org/rss/1.0/modules/annotate/"
>

<channel>
<title>Test 2.0 Feed</title>
<link>http://example.com/</link>
<description>Lambda</description>


<item>
<title>This is an item</title>
<link>http://example.com/2007/01/19</link>
<description>Yadda yadda yadda</description>
<author>joeuser@example.com</author>
<anno:reference resource="Aloha" />
</item>

</channel>

</rss>
EOF

    $rss_parser->parse($xml_text);

    my $item = $rss_parser->{items}->[0];

    # Sanitize the channel out of uninitialised keys.
    foreach my $field (qw(
        item
    ))
    {
        delete $item->{$field};
    }
    # TEST
    is($item->{title}, "This is an item", "Testing for non-moduled-namespaced element inside an item (title)");
    is($item->{"http://purl.org/rss/1.0/modules/annotate/"}{reference}, "Aloha", "Testing for non-moduled-namespaced element inside an item (title)");

}

{
    my $rss_parser = XML::RSS::LibXML->new(version => "1.0");

    $rss_parser->parse(<<'EOF');
<?xml version="1.0" encoding="UTF-8"?>

<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns="http://purl.org/rss/1.0/"
 xmlns:content="http://purl.org/rss/1.0/modules/content/"
 xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:syn="http://purl.org/rss/1.0/modules/syndication/"
 xmlns:my="http://purl.org/my/rss/module/"
 xmlns:admin="http://webns.net/mvcb/"
>

<channel rdf:about="http://example.com/">
<title>Test 1.0 Feed</title>
<link>http://example.com/</link>
<description>To lead by example</description>
<dc:date>2007-01-19T14:21:18+0200</dc:date>
<items>
 <rdf:Seq>
  <rdf:li rdf:resource="http://example.com/2007/01/19" />
 </rdf:Seq>
</items>
<image rdf:resource="http://example.com/example.gif" />
<textinput rdf:resource="http://example.com/search.pl" />
</channel>

<image rdf:about="http://example.com/example.gif" xmlns="">
<title>Test Image</title>
<url>http://example.com/example.gif</url>
<link>http://example.com/</link>
<dc:date>5 Sep 2006</dc:date>
</image>

<item rdf:about="http://example.com/2007/01/19">
<title>This is an item</title>
<link>http://example.com/2007/01/19</link>
<description>Yadda &#x26; yadda &#x26; yadda</description>
<dc:creator>joeuser@example.com</dc:creator>
<admin:generatorAgent resource="XmlRssGenKon" />
</item>

<textinput rdf:about="http://example.com/search.pl">
<title>Search</title>
<description>Search for an example</description>
<name>q</name>
<link>http://example.com/search.pl</link>
</textinput>

</rdf:RDF>
EOF

    # TEST
    is ($rss_parser->{items}->[0]->{admin}->{generatorAgent},
        "XmlRssGenKon",
        "Parsing 1.0 - known module rdf_resource_field",
    );
}

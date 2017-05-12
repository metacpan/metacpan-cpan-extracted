#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 34;

use File::Spec;

use XML::LibXML;

use XML::Grammar::Fiction::ToHTML;
use XML::Grammar::Fiction::ToDocBook;

my @tests = (qw(
        sections-and-paras
        sections-p-b-i
    ));

sub load_xml
{
    my $path = shift;

    open my $in, "<", $path;
    my $contents;
    {
        local $/;
        $contents = <$in>
    }
    close($in);
    return $contents;
}

# TEST:$num_texts=2

my %converters =
(
    'xhtml' =>
    {
        class => "XML::Grammar::Fiction::ToHTML",
        method => "translate_to_html",
    },
    'db' =>
    {
        class => "XML::Grammar::Fiction::ToDocBook",
        method => "translate_to_docbook",
    },
);

foreach my $conv_id (keys(%converters))
{
    my $h_ref = $converters{$conv_id};
    $h_ref->{obj} = $h_ref->{class}->new(
        {
            data_dir => File::Spec->catdir(File::Spec->curdir(), "extradata"),
        }
    );
}

foreach my $fn (@tests)
{
    my $xpc = XML::LibXML::XPathContext->new();
    $xpc->registerNs('x', q{http://www.w3.org/1999/xhtml});
    $xpc->registerNs('db', q{http://docbook.org/ns/docbook});

    # This is a closure that returns a closure (like shown in "On Lisp" :
    # http://www.paulgraham.com/onlisptext.html ) for a finder in
    # one of the documents
    my $create_finder = sub {
        my $format_id = shift;

        my $format_hash = $converters{$format_id};
        my $m = $format_hash->{method};

        my $xml_fn = "t/fiction/data/xml/$fn.xml";

        my $text = $format_hash->{'obj'}->$m(
            {
                source => { file => $xml_fn, },
                output => "string",
            }
        );
        if ($format_id eq "xhtml")
        {
            my $file_contents = load_xml($xml_fn);
            {
                my $from_string_text =
                    $format_hash->{'obj'}->$m(
                    {
                        source => { string_ref => \$file_contents, },
                        output => "string",
                    }
                );

                # TEST*$num_texts
                is ($from_string_text, $text, "From-string-ref text is OK.")
            }

            {
                my $parser = XML::LibXML->new();
                my $file_dom = $parser->parse_string($file_contents);

                my $from_string_text =
                    $format_hash->{'obj'}->$m(
                    {
                        source => { dom => $file_dom, },
                        output => "string",
                    }
                );

                # TEST*$num_texts
                is ($from_string_text, $text, "From-dom text is OK.")
            }
        }
        my $parser = XML::LibXML->new();

        $parser->load_ext_dtd(0);

        my $doc = $parser->parse_string($text);

        return sub {
            my $xpath = shift;
            return $xpc->findnodes($xpath, $doc);
        };
    };

    my $xhtml_find = $create_finder->("xhtml");
    my $db_find = $create_finder->("db");

    # TEST*$num_texts
    is (
        scalar(() = $xhtml_find->(q{//x:html})),
        1,
        "Found one article with id index",
    );

    {
        my @title = $db_find->(q{//db:article/db:info/db:title});

        # TEST*$num_texts
        is (
            scalar(@title),
            1,
            "Found one global <db:title>",
        );

        # TEST*$num_texts
        is ($title[0]->textContent(), "David vs. Goliath - Part I");
    }

    # TEST:$num_xhtml_top_titles=2;
    # TEST:$n=$num_texts*$num_xhtml_top_titles;
    foreach my $xpath (
        q{//x:html/x:head/x:title},
        q{//x:html/x:body/x:div/x:h1},
    )
    {
        my @title = $xhtml_find->($xpath);

        # TEST*$n
        is (
            scalar(@title),
            1,
            "Found one global <x:title>",
        );

        # TEST*$n
        is ($title[0]->textContent(), "David vs. Goliath - Part I",
            "XHTML <title> has good content"
        );
    }

    # TEST*$num_texts
    ok (
        (scalar(() = $xhtml_find->(q{//x:div}))
            >=
            1
        ),
        "Found role=description sections",
    );

    {
        my @elems = $xhtml_find->(q{//x:div[@xml:id="top"]/x:h2});
        # TEST*$num_texts
        is (scalar(@elems), 1, "One element");

        # TEST*$num_texts
        is ($elems[0]->textContent(), "The Top Section",
            "<h2> element contains the right thing.");
    }

    # TEST:$num_with_styles=1;
    if ($fn eq "sections-p-b-i")
    {
        {
            my @elems;

            @elems = $xhtml_find->(q{//x:div/x:p/x:b});
            # TEST*$num_with_styles
            is (
                scalar(@elems),
                1,
                "Found bold tag",
            );

            # TEST*$num_with_styles
            like ($elems[0]->toString(), qr{swear},
                "Elem[0] is the right <b> tag."
            );

            @elems = $xhtml_find->(q{//x:div/x:p/x:i});
            # TEST*$num_with_styles
            is (
                scalar(@elems),
                1,
                "Found italic tag",
            );

            # TEST*$num_with_styles
            like ($elems[0]->toString(), qr{David},
                "<i>[0] contains the right contents."
            );
        }

        {
            my @elems;

            @elems = $db_find->(q{//db:article/db:section/db:para/db:emphasis[@role="bold"]});
            # TEST*$num_with_styles
            is (
                scalar(@elems),
                1,
                "DocBook: found bold tag",
            );

            # TEST*$num_with_styles
            is ($elems[0]->textContent(), "swear",
                "Elem[0] is the right <emphasis role=bold> tag."
            );

            @elems = $db_find->(
                q{//db:article//db:section/db:para/db:emphasis[not(@role)]}
            );
            # TEST*$num_with_styles
            is (
                scalar(@elems),
                1,
                "Found italic tag",
            );

            # TEST*$num_with_styles
            is ($elems[0]->textContent(), "David",
                "<i>[0] contains the right contents.",
            );
        }

        # Test the DocBook/XML incorporation of the <title> tag.
        {
            my @elems;

            @elems = $db_find->(
                q{//db:section[@xml:id='goliath']/db:info/db:title}
            );
            # TEST*$num_with_styles
            is (
                scalar(@elems),
                1,
                "DocBook: found one title tag",
            );

            # TEST*$num_with_styles
            is ($elems[0]->textContent(), "Goliath's Response",
                "title#goliath contains the right content.",
            );
        }
    }
}

1;


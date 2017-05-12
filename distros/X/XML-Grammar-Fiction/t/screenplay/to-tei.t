#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 17;

use lib './t/lib';
use XmlGrammarTestXML qw(my_is_xml);

use File::Spec;

use XML::LibXML;

use XML::Grammar::Screenplay::ToTEI;

# TEST:$num_texts=17
my @tests = (qw(
    dialogue-with-several-paragraphs
    nested-s
    scenes-with-titles
    two-nested-s
    with-brs
    with-colon-inside-description
    with-comments
    with-description
    with-dialogue
    with-entities
    with-i-element-inside-paragraphs
    with-internal-description-at-start-of-line
    with-internal-description
    with-multi-line-comments
    with-multi-para-desc
    with-numeric-entities
    with-tags-inside-paragraphs
    ));

sub load_xml
{
    my $path = shift;

    open my $in, "<", $path;
    my $contents;
    {
        local $/;
        $contents = <$in>;
    }
    close($in);
    return $contents;
}

my $converter = XML::Grammar::Screenplay::ToTEI->new({
        data_dir => File::Spec->catdir(File::Spec->curdir(), "extradata"),
    });

foreach my $fn (@tests)
{
    my $tei_text = $converter->translate_to_tei(
        {
            source => { file => "t/screenplay/data/xml/$fn.xml", },
            output => "string",
        }
    );

    # TEST*$num_texts
    my_is_xml (
        [ string => $tei_text, ],
        [ string => load_xml("t/screenplay/data/tei/$fn.tei.xml"), ],
        "Output of the TEI \"$fn\"",
    );
}

1;


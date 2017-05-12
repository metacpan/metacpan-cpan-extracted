#!/usr/bin/perl

use strict;
use warnings;

use lib './t/lib';

use Test::More tests => 76;

use XmlGrammarTestXML qw(my_is_xml);

use XML::LibXML;

require XML::Grammar::Screenplay::FromProto;

require XML::Grammar::Screenplay::FromProto::Parser::QnD;

sub load_xml
{
    my $path = shift;

    open my $in, "<:encoding(utf8)", $path;
    my $contents;
    {
        local $/;
        $contents = <$in>
    }
    close($in);
    return $contents;
}

my @tests = (qw(
        nested-s
        two-nested-s
        with-dialogue
        dialogue-with-several-paragraphs
        with-description
        with-tags-inside-paragraphs
        with-i-element-inside-paragraphs
        with-img-element-inside-paragraphs
        with-internal-description
        with-comments
        with-comments-with-newlines
        with-multi-para-desc
        with-multi-line-comments
        scenes-with-titles
        with-entities
        with-brs
        with-internal-description-at-start-of-line
        with-colon-inside-description
        with-numeric-entities
    ));

# TEST:$num_texts=19

my $grammar = XML::Grammar::Screenplay::FromProto->new({
        parser_class => "XML::Grammar::Screenplay::FromProto::Parser::QnD",
    });

my $rngschema = XML::LibXML::RelaxNG->new(
        location => "./extradata/screenplay-xml.rng"
    );

my $xml_parser = XML::LibXML->new();
$xml_parser->validation(0);

foreach my $fn (@tests)
{
    my $got_xml = $grammar->convert(
        {
            source =>
            {
                file => "t/screenplay/data/proto-text/$fn.txt",
            },
        }
    );

    # TEST*$num_texts
    unlike ($got_xml, qr{^<!DOCTYPE}ms, "No doctype in \"$fn\"");

    # TEST*$num_texts
    unlike ($got_xml, qr{[ \t+]$}ms, "No trailing space in \"$fn\"");

    # TEST*$num_texts
    my_is_xml (
        [ string => $got_xml, ],
        [ string => load_xml("t/screenplay/data/xml/$fn.xml"), ],
        "Output of the Proto Text \"$fn\""
    );

    my $dom = $xml_parser->parse_string($got_xml);

    my $code;
    eval
    {
    $code = $rngschema->validate($dom);
    };

    # TEST*$num_texts
    ok ((defined($code) && ($code == 0)),
        "The validation of '$fn' succeeded.") ||
        diag("\$@ == $@");
}

1;

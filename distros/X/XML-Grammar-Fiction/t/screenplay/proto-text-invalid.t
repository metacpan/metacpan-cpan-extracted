#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Test::More tests => 2;

use XML::LibXML;

use XML::Grammar::Screenplay::FromProto;
use XML::Grammar::Screenplay::FromProto::Parser::QnD;

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


{
    my $grammar = XML::Grammar::Screenplay::FromProto->new({
        parser_class => "XML::Grammar::Screenplay::FromProto::Parser::QnD",
    });

    eval {
        my $got_xml = $grammar->convert(
            {
                source =>
                {
                    file => "t/screenplay/data/proto-text-invalid/inner-desc-inside-char-addressing.txt",
                },
            }
        );
    };

    my $err = $@;

    # TEST
    like ($err, qr{inner-desc.*?addressing},
        "Tried to put an inner-desc inside an addressing "
    );

}

{
    my $grammar = XML::Grammar::Screenplay::FromProto->new({
        parser_class => "XML::Grammar::Screenplay::FromProto::Parser::QnD",
    });

    eval {
        my $got_xml = $grammar->convert(
            {
                source =>
                {
                    file => "t/screenplay/data/proto-text-invalid/non-terminated-desc.txt",
                },
            }
        );
    };

    my $err = $@;

    # TEST
    like ($err, qr{Tag not closed at EOF},
        "Screenplay with a description that did not terminate"
    );

}

1;


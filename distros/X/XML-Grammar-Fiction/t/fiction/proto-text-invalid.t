#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 26;

use XML::LibXML;

use Exception::Class;

use XML::Grammar::Fiction::FromProto;
use XML::Grammar::Fiction::FromProto::Parser::QnD;


{
    my $grammar = XML::Grammar::Fiction::FromProto->new({});
    my $got_xml;
    eval {
        $got_xml = $grammar->convert(
        {
            source =>
            {
                file => "t/fiction/data/proto-text-invalid/inner-desc-inside-char-addressing.txt",
            },
        }
    );
    };

    my $err = Exception::Class->caught(
        "XML::Grammar::Fiction::Err::Parse::TagsMismatch"
    );

    # TEST
    ok ($err, "TagsMismatch was caught");

    # TEST
    like(
        $err->error(),
        qr{\ATags do not match},
        "Text is OK."
    );

    # TEST
    is(
        $err->opening_tag()->name(),
        "start",
        "Opening tag-name is OK.",
    );

    # TEST
    is(
        $err->opening_tag()->line(),
        1,
        "Opening line is OK.",
    );

    # TEST
    is(
        $err->closing_tag()->name(),
        "wrong-finish-tag",
        "Closing tag-name is OK.",
    );

    # TEST
    is(
        $err->closing_tag()->line(),
        3,
        "Closing line is OK.",
    );
}

{
    my $grammar = XML::Grammar::Fiction::FromProto->new({});

    my $got_xml;

    eval {
        $got_xml = $grammar->convert(
        {
            source =>
            {
                file => "t/fiction/data/proto-text-invalid/not-start-with-tag.txt",
            },
        }
    );
    };

    my $err = Exception::Class->caught(
        "XML::Grammar::Fiction::Err::Parse::CannotMatchOpeningTag"
    );

    # TEST
    ok ($err, "CannotMatchOpeningTag was caught");

    # TEST
    like(
        $err->error(),
        qr{\ACannot match opening tag.},
        "Text is OK."
    );
}


{
    my $grammar = XML::Grammar::Fiction::FromProto->new({});

    my $got_xml;

    eval {
        $got_xml = $grammar->convert(
        {
            source =>
            {
                file => "t/fiction/data/proto-text-invalid/no-right-angle.txt",
            },
        }
    );
    };

    my $err_proto = $@;

    my $err = Exception::Class->caught(
        "XML::Grammar::Fiction::Err::Parse::NoRightAngleBracket"
    );

    # TEST
    ok ($err, "NoRightAngleBracket was matched.");

    # TEST
    like(
        $err->error(),
        qr{\ACannot match the \">\" of the opening tag},
        "Text is OK."
    );

    # TEST
    is (
        $err->line(),
        1,
        "Line is 1 as expected."
    );
}

{
    my $grammar = XML::Grammar::Fiction::FromProto->new({});

    my $got_xml;

    eval {
        $got_xml = $grammar->convert(
            {
                source =>
                {
                    file => "t/fiction/data/proto-text-invalid/wrong-close-tag.txt",
                },
            }
        );
    };

    my $err_proto = $@;

    my $err = Exception::Class->caught(
        "XML::Grammar::Fiction::Err::Parse::WrongClosingTagSyntax"
    );

    # TEST
    ok ($err, "WrongClosingTagSyntax was matched.");

    # TEST
    like(
        $err->error(),
        qr{\ACannot match closing tag},
        "Cannot match closing tag."
    );

    # TEST
    is (
        $err->line(),
        3,
        "Line is 1 as expected."
    );
}

{
    my $grammar = XML::Grammar::Fiction::FromProto->new({});
    eval {
    my $got_xml = $grammar->convert(
        {
            source =>
            {
                file => "t/fiction/data/proto-text-invalid/wrong-closing-inner-tag.txt",
            },
        }
    );
    };

    my $err_raw = $@;

    my $err = Exception::Class->caught(
        "XML::Grammar::Fiction::Err::Parse::TagsMismatch"
    );

    # TEST
    ok ($err, "TagsMismatch was caught");

    # TEST
    like(
        $err->error(),
        qr{\ATags do not match},
        "Text is OK."
    );

    # TEST
    is(
        $err->opening_tag()->name(),
        "b",
        "Opening tag-name is OK.",
    );

    # TEST
    is(
        $err->opening_tag()->line(),
        11,
        "Opening line is OK.",
    );

    # TEST
    is(
        $err->closing_tag()->name(),
        "i",
        "closing tag.",
    );

    # TEST
    is(
        $err->closing_tag()->line(),
        11,
        "Closing tag line is OK.",
    );
}

{
    my $grammar = XML::Grammar::Fiction::FromProto->new({});

    my $got_xml;

    eval {
        $got_xml = $grammar->convert(
        {
            source =>
            {
                file => "t/fiction/data/proto-text-invalid/leading-space.txt",
            },
        }
    );
    };

    my $err_proto = $@;

    my $err = Exception::Class->caught(
        "XML::Grammar::Fiction::Err::Parse::LeadingSpace"
    );

    # TEST
    ok ($err, "LeadingSpace was matched.");

    # TEST
    like(
        $err->error(),
        qr{\ALeading space},
        "Cannot match closing tag."
    );

    # TEST
    is (
        $err->line(),
        12,
        "Line is 1 as expected."
    );
}

{
    my $grammar = XML::Grammar::Fiction::FromProto->new({});

    my $got_xml;

    eval {
        $got_xml = $grammar->convert(
        {
            source =>
            {
                file => "t/fiction/data/proto-text-invalid/leading-space-at-para-start.txt",
            },
        }
    );
    };

    my $err_proto = $@;

    my $err = Exception::Class->caught(
        "XML::Grammar::Fiction::Err::Parse::LeadingSpace"
    );

    # TEST
    ok ($err, "LeadingSpace at para start was matched.");

    # TEST
    like(
        $err->error(),
        qr{\ALeading space},
        "LeadingSpace at para start error."
    );

    # TEST
    is (
        $err->line(),
        14,
        "LeadingSpace Line is 14 as expected."
    );
}

1;

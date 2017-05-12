#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 18;
use Test::Differences;

use File::Spec;
use IO::String;

use XML::LibXML;
use XML::LibXSLT;

use XML::Grammar::Fortune::ToText;

# TEST:$num_texts=18

my @tests = (qw(
        raw-fort-empty-info-1
        raw-fort-with-info-1
        irc-conversation-1
        irc-conversation-3-with-join-unjoin
        quote-fort-sample-2-with-brs
        quote-fort-sample-3-more-than-one-para
        quote-fort-sample-4-ul
        quote-fort-sample-5-ol
        quote-fort-sample-6-with-bold
        quote-fort-sample-7-with-italics
        quote-fort-sample-8-with-em-and-strong
        quote-fort-sample-9-with-blockquote
        quote-fort-sample-10-with-hyperlink
        quote-fort-sample-11-with-work-elem-spanning-several-lines
        screenplay-fort-sample-1
        screenplay-fort-sample-2-with-italics
        screenplay-fort-sample-2-long-line
        screenplay-fort-sample-3-with-inlinedesc
    ));

sub read_file
{
    my $path = shift;

    open my $in, "<", $path
        or die "Could not open '$path'! - $!";
    binmode $in, ":utf8";
    my $contents;
    {
        local $/;
        $contents = <$in>
    }
    close($in);
    return $contents;
}

foreach my $fn_base (@tests)
{
    my $buffer = "";
    my $io = IO::String->new($buffer);
    my $converter = XML::Grammar::Fortune::ToText->new(
        {
            'input' => "./t/data/xml/$fn_base.xml",
            'output' => $io,
        }
    );

    $converter->run();

    # TEST*$num_texts
    eq_or_diff (
        $buffer,
        read_file("./t/data/text-results/$fn_base.txt"),
        "Testing for Good Conversion to Text of '$fn_base'",
    );
}

1;


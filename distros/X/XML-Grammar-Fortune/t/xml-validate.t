use strict;
use warnings;

use Test::More tests => 20;                      # last test to print

use XML::LibXML;

# TEST:$num_tests=20
my @inputs = (qw(
        facts-fort-1
        facts-fort-2-more-than-one-fact
        facts-fort-3-more-than-one-list
        facts-fort-4-from-shlomifish.org
        irc-conversation-1
        irc-conversation-2-with-slash-me
        irc-conversation-3-with-join-unjoin
        irc-conversation-4-several-convos
        irc-convos-and-raw-fortunes-1
        quote-fort-sample-1
        quote-fort-sample-2-with-brs
        screenplay-fort-sample-1
        screenplay-fort-sample-2-with-italics
        quote-fort-sample-4-ul
        quote-fort-sample-5-ol
        quote-fort-sample-6-with-bold
        quote-fort-sample-7-with-italics
        quote-fort-sample-8-with-em-and-strong
        quote-fort-sample-9-with-blockquote
        quote-fort-sample-10-with-hyperlink
    ));

my $rngschema = XML::LibXML::RelaxNG->new(
    location => "./extradata/fortune-xml.rng"
);



foreach my $fn_base (@inputs)
{
    my $filename = "./t/data/xml/$fn_base.xml";
    my $doc = XML::LibXML->new->parse_file($filename);

    my $code;
    $code = $rngschema->validate($doc);

    # TEST*$num_tests
    ok ((defined($code) && ($code == 0)),
        "The validation of '$filename' succeeded.") ||
        diag("\$@ == $@");

}

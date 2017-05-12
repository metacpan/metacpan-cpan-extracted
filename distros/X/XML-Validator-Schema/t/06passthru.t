#!/usr/bin/perl
use strict;
use warnings;
use XML::Validator::Schema;
use XML::SAX::ParserFactory;

BEGIN {
    unless (eval "use XML::SAX::Writer; 1;") {
        eval "use Test::More skip_all => 'Test requires XML::SAX::Writer'";
    } else {
        eval "use Test::More qw(no_plan);";
    }
}


# run test.xml through the writer with no validator
my $output = "";
my $writer = XML::SAX::Writer->new(Output => \$output);
my $parser = XML::SAX::ParserFactory->parser(Handler => $writer);
$parser->parse_uri('t/test.xml');
ok($output);

# run test.xml through writer, validating against test.xsd
my $output2 = "";
my $writer2 = XML::SAX::Writer->new(Output => \$output2);
my $validator = XML::Validator::Schema->new(file => 't/test.xsd', 
                                            Handler => $writer2);
my $parser2 = XML::SAX::ParserFactory->parser(Handler => $validator);
$parser2->parse_uri('t/test.xml');
ok($output2);

# should be the same
is($output, $output2);


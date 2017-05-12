#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use XML::Printer::ESCPOS;
use lib 't/lib';
use Mock::Printer::ESCPOS;

plan tests => 15;

my $mockprinter = Mock::Printer::ESCPOS->new();
my $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

my $ret = $parser->parse(
    q#
        <escpos>
            <text wordwrap="10">advanced TeXT</text>
        </escpos>
    #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
is_deeply $mockprinter->{calls}, [ [ text => 'advanced' ], [ text => 'TeXT' ], ], 'XML translated correctly';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
        <escpos>
            <text wordwrap="39"
            >Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.</text>
        </escpos>
    #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
is_deeply $mockprinter->{calls},
    [
    [ text => 'Lorem ipsum dolor sit amet, consetetur', ],
    [ text => 'sadipscing elitr, sed diam nonumy', ],
    [ text => 'eirmod tempor invidunt ut labore et', ],
    [ text => 'dolore magna aliquyam erat, sed diam', ],
    [ text => 'voluptua. At vero eos et accusam et', ],
    [ text => 'justo duo dolores et ea rebum. Stet', ],
    [ text => 'clita kasd gubergren, no sea takimata', ],
    [ text => 'sanctus est Lorem ipsum dolor sit amet.', ],
    [ text => 'Lorem ipsum dolor sit amet, consetetur', ],
    [ text => 'sadipscing elitr, sed diam nonumy', ],
    [ text => 'eirmod tempor invidunt ut labore et', ],
    [ text => 'dolore magna aliquyam erat, sed diam', ],
    [ text => 'voluptua. At vero eos et accusam et', ],
    [ text => 'justo duo dolores et ea rebum. Stet', ],
    [ text => 'clita kasd gubergren, no sea takimata', ],
    [ text => 'sanctus est Lorem ipsum dolor sit amet.', ]
    ],
    'XML translated correctly';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
        <escpos>
            <text
                wordwrap="60"
                bodystart="   "
            >Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus</text>
        </escpos>
    #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
is_deeply $mockprinter->{calls},
    [
    [ text => 'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed' ],
    [ text => '   diam nonumy eirmod tempor invidunt ut labore et dolore' ],
    [ text => '   magna aliquyam erat, sed diam voluptua. At vero eos et' ],
    [ text => '   accusam et justo duo dolores et ea rebum. Stet clita kasd' ],
    [ text => '   gubergren, no sea takimata sanctus' ],
    ],
    'XML translated correctly';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
        <escpos>
            <text
                wordwrap="cx"
                bodystart="   "
            >Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus</text>
        </escpos>
    #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong text tag usage: wordwrap attribute must be a positive integer',
    'correct error message';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
        <escpos>
            <text
                wordwrap="37.9"
                bodystart="   "
            >Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus</text>
        </escpos>
    #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong text tag usage: wordwrap attribute must be a positive integer',
    'correct error message';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
        <escpos>
            <text
                wordwrap="00"
            >Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus</text>
        </escpos>
    #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong text tag usage: wordwrap attribute must be a positive integer',
    'correct error message';

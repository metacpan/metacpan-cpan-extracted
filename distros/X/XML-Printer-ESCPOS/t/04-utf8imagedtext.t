#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use XML::Printer::ESCPOS;
use lib 't/lib';
use Mock::Printer::ESCPOS;

plan tests => 9;

my $mockprinter = Mock::Printer::ESCPOS->new();
my $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

my $ret = $parser->parse(
    q#
        <escpos>
            <utf8ImagedText>advanced TeXT</utf8ImagedText>
        </escpos>
    #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
is_deeply $mockprinter->{calls}, [ [ utf8ImagedText => 'advanced TeXT' ], ], 'XML translated correctly';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
        <escpos>
            <utf8ImagedText
                fontFamily="Rubik"
            >Dont panic!</utf8ImagedText>
        </escpos>
    #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
is_deeply $mockprinter->{calls},
    [
    [   utf8ImagedText => "Dont panic!",
        fontFamily     => "Rubik",
    ],
    ],
    'XML translated correctly';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
        <escpos>
            <utf8ImagedText
                fontFamily="Rubik"
                fontStyle = "Normal"
                lineHeight ="40"
            >Dont panic!</utf8ImagedText>
        </escpos>
    #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
is_deeply $mockprinter->{calls},
    [
    [   utf8ImagedText => "Dont panic!",
        fontFamily     => "Rubik",
        fontStyle      => "Normal",
        lineHeight     => 40,
    ],
    ],
    'XML translated correctly';

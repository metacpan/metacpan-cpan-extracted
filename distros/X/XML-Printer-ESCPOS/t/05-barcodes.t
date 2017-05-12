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
            <barcode>advanced TeXT</barcode>
        </escpos>
    #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
is_deeply $mockprinter->{calls}, [ [ barcode => barcode => 'advanced TeXT' ], ], 'XML translated correctly';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
        <escpos>
            <barcode
                system="CODABAR"
            >Dont panic!</barcode>
        </escpos>
    #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
is_deeply $mockprinter->{calls},
    [
    [   barcode => barcode => "Dont panic!",
        system  => "CODABAR",
    ],
    ],
    'XML translated correctly';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
        <escpos>
            <barcode
                HRIPosition="below"
                font = "b"
                lineHeight ="37"
            >Dont panic!</barcode>
        </escpos>
    #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
is_deeply $mockprinter->{calls},
    [
    [   barcode     => barcode => "Dont panic!",
        HRIPosition => "below",
        font        => "b",
        lineHeight  => 37,
    ],
    ],
    'XML translated correctly';

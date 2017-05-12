#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use XML::Printer::ESCPOS;
use lib 't/lib';
use Mock::Printer::ESCPOS;

plan tests => 6;

my $mockprinter = Mock::Printer::ESCPOS->new();
my $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

my $ret = $parser->parse(
    q#
        <escpos>
            <qr>Simple QR code</qr>
        </escpos>
    #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
is_deeply $mockprinter->{calls}, [ [ qr => 'Simple QR code' ], ], 'XML translated correctly';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
        <escpos>
            <qr version="4" moduleSize="4">Dont panic!</qr>
        </escpos>
    #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
is_deeply $mockprinter->{calls}, [ [ qr => 'Dont panic!', 'L', 4, 4 ], ], 'XML translated correctly';

#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use XML::Printer::ESCPOS;
use lib 't/lib';
use Mock::Printer::ESCPOS;

plan tests => 4;

my $mockprinter = Mock::Printer::ESCPOS->new();
my $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

my $ret = $parser->parse(
    q#
            <escpos>
              <pold>bold text</pold>
              <underline>underlined text</underline>
            </escpos>
        #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'tag pold is not allowed', 'correct error message';

$ret = $parser->parse(
    q#
        <escpos>
            <qr>Simple QR code</qr>
        </escpos>
    #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';

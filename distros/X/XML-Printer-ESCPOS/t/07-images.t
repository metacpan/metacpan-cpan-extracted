#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use XML::Printer::ESCPOS;
use lib 't/lib';
use Mock::Printer::ESCPOS;

plan tests => 22;

my @filenames = ("t/images/arrow.png", "t/images/arrow.gif", "t/images/arrow.jpg");
for my $filename (@filenames) {
    my @xmls = (
        q#
            <escpos>
              <image filename="# . $filename . q#" />
            </escpos>
        #,
        q#
            <escpos>
              <image># . $filename . q#</image>
            </escpos>
        #
    );

    for my $xml (@xmls) {
        my $mockprinter = Mock::Printer::ESCPOS->new();
        my $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

        my $ret = $parser->parse($xml);
        ok $ret => 'parsing successful';
        is $parser->errormessage(), undef, 'errormessage is empty';
        my $calls = $mockprinter->{calls};
        ok( (          ref $calls eq 'ARRAY'
                    and @$calls == 1
                    and ref $calls->[0] eq 'ARRAY'
                    and @{$calls->[0]} == 2
                    and $calls->[0]->[0] eq 'image'
                    and ref $calls->[0]->[1] eq 'GD::Image'
                    and $calls->[0]->[1]->height == 60
                    and $calls->[0]->[1]->width == 83
            ),
            'XML translated correctly'
        );
    }
}

my $mockprinter = Mock::Printer::ESCPOS->new();
my $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

my $ret = $parser->parse(
    q#
            <escpos>
              <image size="23">t/images/arrow.png</image>
            </escpos>
        #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong image tag usage', 'correct error message';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
            <escpos>
              <image filename="t/images/arrow.pdf" />
            </escpos>
        #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong image tag usage: file format not supported', 'correct error message';

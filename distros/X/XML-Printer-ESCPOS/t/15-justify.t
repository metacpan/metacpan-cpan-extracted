#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use XML::Printer::ESCPOS;
use lib 't/lib';
use Mock::Printer::ESCPOS;

plan tests => 10;

my $mockprinter = Mock::Printer::ESCPOS->new();
my $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

my $ret = $parser->parse(
    q#
          <escpos>
            <justify align="right"
                >text <bold>bold</bold>
            </justify>
          </escpos>
        #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
is_deeply $mockprinter->{calls}, [
    [ justify => 'right' ],
    [ text    => 'text' ],
    [ bold    => 1 ],
    [ justify => 'right' ],
    [ text    => 'bold' ],
    [ bold    => 0 ],
], 'XML translated correctly';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
          <escpos>
            <justify align="right">First line is right aligned.<lf />
                <justify align="center">Second line is centered.</justify><lf />
                Third line is right aligned.
            </justify>
          </escpos>
        #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
is_deeply $mockprinter->{calls}, [
    [ justify   => 'right' ],
    [ text      => 'First line is right aligned.' ],
    [ lf        => ],
    [ justify   => 'center' ],
    [ text      => 'Second line is centered.' ],
    [ lf        => ],
    [ justify   => 'right' ],
    [ text      => 'Third line is right aligned.' ],
], 'XML translated correctly';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
            <escpos>
                <justify right="1">text</justify>
            </escpos>
        #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong justify tag usage', 'correct error message';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
            <escpos>
                <justify>right</justify>
            </escpos>
        #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong justify tag usage', 'correct error message';
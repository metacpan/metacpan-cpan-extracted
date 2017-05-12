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
            <set 
                paperWidth  = "815"
                wordwrap    = "60"
                fontFamily  = "OverpassMono"
                fontSize    = "16"
                fontStyle   = "Bold"
                lineHeight  = "30"
            />
            <utf8ImagedText>This is bold text, size 16.</utf8ImagedText>
            <utf8ImagedText
                fontStyle = "Normal"
                fontSize  = "20"
                >This is normal text, size 20.</utf8ImagedText>
            <utf8ImagedText>This is bold text, size 16.</utf8ImagedText>
        </escpos>
    #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
is_deeply $mockprinter->{calls}, [
    [
        utf8ImagedText  => 'This is bold text, size 16.',
        fontFamily      => 'OverpassMono',
        fontSize        => '16',
        fontStyle       => 'Bold',
        lineHeight      => '30',
        paperWidth      => '815'
    ],
    [
        utf8ImagedText  => 'This is normal text, size 20.',
        fontFamily      => 'OverpassMono',
        fontSize        => '20',
        fontStyle       => 'Normal',
        lineHeight      => '30',
        paperWidth      => '815'
    ],
    [
        utf8ImagedText  => 'This is bold text, size 16.',
        fontFamily      => 'OverpassMono',
        fontSize        => '16',
        fontStyle       => 'Bold',
        lineHeight      => '30',
        paperWidth      => '815'
    ],
], 'XML translated correctly';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
            <escpos>
              <set />
            </escpos>
        #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong set tag usage', 'correct error message';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
            <escpos>
              <set>815</set>
            </escpos>
        #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong set tag usage', 'correct error message';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
        <escpos>
            <utf8ImagedText>This is standard text.</utf8ImagedText>
            <set 
                fontSize    = "16"
                fontStyle   = "Bold"
            />
            <utf8ImagedText>This is bold text, size 16.</utf8ImagedText>
            <unset 
                fontSize    = ""
            />
            <utf8ImagedText>This is bold text.</utf8ImagedText>
            <unset 
                fontStyle   = ""
            />
            <utf8ImagedText>This is standard text.</utf8ImagedText>
        </escpos>
    #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
is_deeply $mockprinter->{calls}, [
    [
      'utf8ImagedText',
      'This is standard text.'
    ],
    [
      'utf8ImagedText',
      'This is bold text, size 16.',
      'fontSize',
      '16',
      'fontStyle',
      'Bold'
    ],
    [
      'utf8ImagedText',
      'This is bold text.',
      'fontStyle',
      'Bold'
    ],
    [
      'utf8ImagedText',
      'This is standard text.'
    ],
], 'XML translated correctly';

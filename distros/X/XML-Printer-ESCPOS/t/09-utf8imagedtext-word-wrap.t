#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use XML::Printer::ESCPOS;
use lib 't/lib';
use Mock::Printer::ESCPOS;

plan tests => 21;

my $mockprinter = Mock::Printer::ESCPOS->new();
my $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

my $ret = $parser->parse(
    q#
        <escpos>
            <utf8ImagedText wordwrap="10">advanced TeXT</utf8ImagedText>
        </escpos>
    #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
is_deeply $mockprinter->{calls}, [ [ utf8ImagedText => 'advanced' ], [ utf8ImagedText => 'TeXT' ], ], 'XML translated correctly';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
        <escpos>
            <utf8ImagedText
                fontFamily="Rubik"
                wordwrap="b"
            >Lorem ipsum dolor sit amet,</utf8ImagedText>
        </escpos>
    #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong utf8ImagedText tag usage: wordwrap attribute must be a positive integer',
    'correct error message';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(

    q#
        <escpos>
            <utf8ImagedText
                fontFamily="Rubik"
                wordwrap="13.9"
            >Lorem ipsum dolor sit amet,</utf8ImagedText>
        </escpos>
    #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong utf8ImagedText tag usage: wordwrap attribute must be a positive integer',
    'correct error message';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
        <escpos>
            <utf8ImagedText
                fontFamily="Rubik"
                wordwrap="0"
            >Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore </utf8ImagedText>
        </escpos>
    #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
is_deeply $mockprinter->{calls},
    [
    [ 'utf8ImagedText', 'Lorem ipsum dolor sit amet, consetetur sadipscing', 'fontFamily', 'Rubik' ],
    [ 'utf8ImagedText', 'elitr, sed diam nonumy eirmod tempor invidunt ut',  'fontFamily', 'Rubik' ],
    [ 'utf8ImagedText', 'labore',                                            'fontFamily', 'Rubik' ]
    ],
    'XML translated correctly';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
        <escpos>
            <utf8ImagedText
                wordwrap=""
            >Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.</utf8ImagedText>
        </escpos>
    #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
is_deeply $mockprinter->{calls},
    [
    [ utf8ImagedText => 'Lorem ipsum dolor sit amet, consetetur sadipscing' ],
    [ utf8ImagedText => 'elitr, sed diam nonumy eirmod tempor invidunt ut' ],
    [ utf8ImagedText => 'labore et dolore magna aliquyam erat, sed diam' ],
    [ utf8ImagedText => 'voluptua. At vero eos et accusam et justo duo' ],
    [ utf8ImagedText => 'dolores et ea rebum. Stet clita kasd gubergren,' ],
    [ utf8ImagedText => 'no sea takimata sanctus est Lorem ipsum dolor sit' ],
    [ utf8ImagedText => 'amet. Lorem ipsum dolor sit amet, consetetur' ],
    [ utf8ImagedText => 'sadipscing elitr, sed diam nonumy eirmod tempor' ],
    [ utf8ImagedText => 'invidunt ut labore et dolore magna aliquyam erat,' ],
    [ utf8ImagedText => 'sed diam voluptua. At vero eos et accusam et' ],
    [ utf8ImagedText => 'justo duo dolores et ea rebum. Stet clita kasd' ],
    [ utf8ImagedText => 'gubergren, no sea takimata sanctus est Lorem' ],
    [ utf8ImagedText => 'ipsum dolor sit amet.' ]
    ],
    'XML translated correctly';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
        <escpos>
            <utf8ImagedText
                fontFamily="Rubik"
                wordwrap="00"
            >Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.</utf8ImagedText>
        </escpos>
    #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong utf8ImagedText tag usage: wordwrap attribute must be a positive integer',
    'correct error message';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
        <escpos>
            <utf8ImagedText
                fontFamily="Rubik"
                wordwrap="39"
            >Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.</utf8ImagedText>
        </escpos>
    #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
is_deeply $mockprinter->{calls},
    [
    [ utf8ImagedText => 'Lorem ipsum dolor sit amet, consetetur',  'fontFamily', 'Rubik' ],
    [ utf8ImagedText => 'sadipscing elitr, sed diam nonumy',       'fontFamily', 'Rubik' ],
    [ utf8ImagedText => 'eirmod tempor invidunt ut labore et',     'fontFamily', 'Rubik' ],
    [ utf8ImagedText => 'dolore magna aliquyam erat, sed diam',    'fontFamily', 'Rubik' ],
    [ utf8ImagedText => 'voluptua. At vero eos et accusam et',     'fontFamily', 'Rubik' ],
    [ utf8ImagedText => 'justo duo dolores et ea rebum. Stet',     'fontFamily', 'Rubik' ],
    [ utf8ImagedText => 'clita kasd gubergren, no sea takimata',   'fontFamily', 'Rubik' ],
    [ utf8ImagedText => 'sanctus est Lorem ipsum dolor sit amet.', 'fontFamily', 'Rubik' ],
    [ utf8ImagedText => 'Lorem ipsum dolor sit amet, consetetur',  'fontFamily', 'Rubik' ],
    [ utf8ImagedText => 'sadipscing elitr, sed diam nonumy',       'fontFamily', 'Rubik' ],
    [ utf8ImagedText => 'eirmod tempor invidunt ut labore et',     'fontFamily', 'Rubik' ],
    [ utf8ImagedText => 'dolore magna aliquyam erat, sed diam',    'fontFamily', 'Rubik' ],
    [ utf8ImagedText => 'voluptua. At vero eos et accusam et',     'fontFamily', 'Rubik' ],
    [ utf8ImagedText => 'justo duo dolores et ea rebum. Stet',     'fontFamily', 'Rubik' ],
    [ utf8ImagedText => 'clita kasd gubergren, no sea takimata',   'fontFamily', 'Rubik' ],
    [ utf8ImagedText => 'sanctus est Lorem ipsum dolor sit amet.', 'fontFamily', 'Rubik' ]
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
                wordwrap="60"
                bodystart="   "
            >Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus</utf8ImagedText>
        </escpos>
    #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
is_deeply $mockprinter->{calls},
    [
    [   utf8ImagedText => 'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed',
        'fontFamily', 'Rubik', 'fontStyle', 'Normal', 'lineHeight', '40'
    ],
    [   utf8ImagedText => '   diam nonumy eirmod tempor invidunt ut labore et dolore',
        'fontFamily', 'Rubik', 'fontStyle', 'Normal', 'lineHeight', '40'
    ],
    [   utf8ImagedText => '   magna aliquyam erat, sed diam voluptua. At vero eos et',
        'fontFamily', 'Rubik', 'fontStyle', 'Normal', 'lineHeight', '40'
    ],
    [   utf8ImagedText => '   accusam et justo duo dolores et ea rebum. Stet clita kasd',
        'fontFamily', 'Rubik', 'fontStyle', 'Normal', 'lineHeight', '40'
    ],
    [   utf8ImagedText => '   gubergren, no sea takimata sanctus',
        'fontFamily', 'Rubik', 'fontStyle', 'Normal', 'lineHeight', '40'
    ],
    ],
    'XML translated correctly';

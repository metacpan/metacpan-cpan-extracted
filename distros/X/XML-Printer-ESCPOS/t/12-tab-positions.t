#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use XML::Printer::ESCPOS;
use lib 't/lib';
use Mock::Printer::ESCPOS;

plan tests => 18;

my $mockprinter = Mock::Printer::ESCPOS->new();
my $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

my $ret = $parser->parse(
    q#
          <escpos>
            <tabpositions>
              <tabposition>5</tabposition>
              <tabposition>9</tabposition>
              <tabposition>13</tabposition>
            </tabpositions>
          </escpos>
        #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
is_deeply $mockprinter->{calls}, [ [ tabPositions => 5, 9, 13 ], ], 'XML translated correctly';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
          <escpos>
            <tabpositions>
              <tabposition>5</tabposition>
              <tabposition>9</tabposition>
              <tabposition>13</tabposition>
              <tabposition>17</tabposition>
              <tabposition>19</tabposition>
              <tabposition>24</tabposition>
              <tabposition>37</tabposition>
              <tabposition>49</tabposition>
            </tabpositions>
          </escpos>
        #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
is_deeply $mockprinter->{calls}, [ [ tabPositions => 5, 9, 13, 17, 19, 24, 37, 49 ], ], 'XML translated correctly';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
          <escpos>
            <tabpositions>
            </tabpositions>
          </escpos>
        #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong tabpositions tag usage: must contain at least one tabposition tag as child',
    'correct error message';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
          <escpos>
            <tabpositions>
              <bold>123</bold>
              <tabposition>39</tabposition>
            </tabpositions>
          </escpos>
        #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong tabpositions tag usage: must not contain anything else than tabposition tags',
    'correct error message';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
          <escpos>
            <tabpositions>
              <tabposition>bdb</tabposition>
              <tabposition>39</tabposition>
            </tabpositions>
          </escpos>
        #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong tabposition tag usage: value must be a positive integer',
    'correct error message';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
          <escpos>
            <tabpositions>
              <tabposition>0</tabposition>
            </tabpositions>
          </escpos>
        #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong tabposition tag usage: value must be a positive integer',
    'correct error message';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
          <escpos>
            <tabpositions>
              <tabposition>
                <bold>
                  123
                </bold>
              </tabposition>
            </tabpositions>
          </escpos>
        #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong tabposition tag usage: value must be a positive integer',
    'correct error message';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
          <escpos>
            <tabpositions>127
              <tabposition>123</tabposition>
            </tabpositions>
          </escpos>
        #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong tabpositions tag usage: must not contain anything else than tabposition tags',
    'correct error message';

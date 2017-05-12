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
              <bold>bold text</bold>
              <repeat times="4">
                <underline>underlined text</underline>
              </repeat>
            </escpos>
        #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
is_deeply $mockprinter->{calls},
    [
    [ bold         => 1 ],
    [ text         => 'bold text' ],
    [ bold         => 0 ],
    [ underline    => 1 ],
    [ text         => 'underlined text' ],
    [ underline    => 0 ],
    [ underline    => 1 ],
    [ text         => 'underlined text' ],
    [ underline    => 0 ],
    [ underline    => 1 ],
    [ text         => 'underlined text' ],
    [ underline    => 0 ],
    [ underline    => 1 ],
    [ text         => 'underlined text' ],
    [ underline    => 0 ],
    ],
    'XML translated correctly';



$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
            <escpos>
              <bold>bold text</bold>
              <repeat times="-1">
                <underline>underlined text</underline>
              </repeat>
            </escpos>
        #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong repeat tag usage: only positive integers are allowed', 'correct error message';


$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
            <escpos>
              <bold>bold text</bold>
              <repeat times="37,9">
                <underline>underlined text</underline>
              </repeat>
            </escpos>
        #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong repeat tag usage: only positive integers are allowed', 'correct error message';


$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
            <escpos>
              <bold>bold text</bold>
              <repeat times="-27.2">
                <underline>underlined text</underline>
              </repeat>
            </escpos>
        #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong repeat tag usage: only positive integers are allowed', 'correct error message';


$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
            <escpos>
              <underline>
                <repeat times="67">
                  <text>_</text>
                </repeat>
              </underline>
            </escpos>
        #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
is_deeply $mockprinter->{calls},
    [
    [ underline    => 1 ],
    ([ text        => '_' ]) x 67,
    [ underline    => 0 ],
    ],
    'XML translated correctly';


$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
            <escpos>
              <underline>
                <repeat times="2">
                  <bold>
                    <repeat times="3">
                      <invert>It is me</invert>
                    </repeat>
                  </bold>
                </repeat>
              </underline>
            </escpos>
        #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
use Data::Dumper;
# diag Dumper($mockprinter->{calls});
is_deeply $mockprinter->{calls},
    [
    [ underline    => 1 ],
        [ bold         => 1 ],
            [ invert       => 1 ],
            [ text         => 'It is me' ],
            [ invert       => 0 ],
            [ invert       => 1 ],
            [ text         => 'It is me' ],
            [ invert       => 0 ],
            [ invert       => 1 ],
            [ text         => 'It is me' ],
            [ invert       => 0 ],
        [ bold         => 0 ],
        [ bold         => 1 ],
            [ invert       => 1 ],
            [ text         => 'It is me' ],
            [ invert       => 0 ],
            [ invert       => 1 ],
            [ text         => 'It is me' ],
            [ invert       => 0 ],
            [ invert       => 1 ],
            [ text         => 'It is me' ],
            [ invert       => 0 ],
        [ bold         => 0 ],
    [ underline    => 0 ],
    ],
    'XML translated correctly';
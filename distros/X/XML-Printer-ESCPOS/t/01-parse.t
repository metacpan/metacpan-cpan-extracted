#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use XML::Printer::ESCPOS;
use lib 't/lib';
use Mock::Printer::ESCPOS;

plan tests => 3;

my $mockprinter = Mock::Printer::ESCPOS->new();
my $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

my $ret = $parser->parse(
    q#
            <escpos>
              <bold>bold text</bold>
              <underline>underlined text</underline>
              <bold>
                <underline>bold AND <bold> underlinded</bold> text</underline>
                <doubleStrike>you <invert>can not</invert> read this</doubleStrike>
              </bold>
              <lf />
              <color>
                <bold>This is printed with the second color (if supported)</bold>
              </color>
              <lf lines="3" />
              <text> with whitespaces </text>
              <tab /><text>go on</text>
              <upsideDown>some additional text</upsideDown>
              <rot90>rotated text </rot90>
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
    [ bold         => 1 ],
    [ underline    => 1 ],
    [ text         => 'bold AND' ],
    [ text         => 'underlinded' ],
    [ text         => 'text' ],
    [ underline    => 0 ],
    [ doubleStrike => 1 ],
    [ text         => 'you' ],
    [ invert       => 1 ],
    [ text         => 'can not' ],
    [ invert       => 0 ],
    [ text         => 'read this' ],
    [ doubleStrike => 0 ],
    [ bold         => 0 ],
    [ lf           => ],
    [ color        => 1 ],
    [ bold         => 1 ],
    [ text         => 'This is printed with the second color (if supported)' ],
    [ bold         => 0 ],
    [ color        => 0 ],
    [ lf           => ],
    [ lf           => ],
    [ lf           => ],
    [ text         => ' with whitespaces ' ],
    [ tab          => ],
    [ text         => 'go on' ],
    [ upsideDown   => 1 ],
    [ text         => 'some additional text' ],
    [ upsideDown   => 0 ],
    [ rot90        => 1 ],
    [ text         => 'rotated text' ],
    [ rot90        => 0 ],
    ],
    'XML translated correctly';

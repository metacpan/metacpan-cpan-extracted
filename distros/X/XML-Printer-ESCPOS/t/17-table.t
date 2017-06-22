#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use XML::Printer::ESCPOS;
use lib 't/lib';
use Mock::Printer::ESCPOS;
use Test::Deep;
use Test::Deep::UnorderedPairs;

sub hashparams {
    my $positional = shift || [];
    my $hash       = shift || {};

    die "hashparams() only works with an even number of positional parameters" if @$positional % 2;
    return all(
            [ @$positional, ( ignore() ) x (2 * scalar keys %$hash) ],
            unordered_pairs(
                @$positional,
                %$hash,
            )
        )
}

plan tests => 18;

my $mockprinter = Mock::Printer::ESCPOS->new();
my $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

my $ret = $parser->parse(
    q#
          <escpos>
            <table
                separator   = "|"
                fontSize    = "16"
                wordwrap    = "60"
                lineHeight  = "30"
                paperWidth  = "815"
                leftBorder  = "|"
                rightBorder = "|"
                fontStyle   = "Normal"
            >
                <pattern align="center">
                    <td align="right" width="5"></td>
                    <td></td>
                    <td align="right" width="10"></td>
                </pattern>
                <tr fontStyle="Bold">
                    <td>1x</td>
                    <td>product A</td>
                    <td>9,00</td>
                </tr>
                <tr fontStyle="Normal">
                    <td>2x</td>
                    <td>product B (each 5,00)</td>
                    <td>10,00</td>
                </tr>
                <hr />
                <tr fontStyle="Bold">
                    <td colspan="2">sum</td>
                    <td align="right">19,00</td>
                </tr>
            </table>
          </escpos>
        #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
cmp_deeply $mockprinter->{calls},
    [
    hashparams(
        [ utf8ImagedText => '|   1x|      product A      |      9,00|' ],
        {   fontSize    => '16',
            fontStyle   => 'Bold',
            leftBorder  => '|',
            lineHeight  => '30',
            paperWidth  => '815',
            rightBorder => '|',
            separator   => '|',
            tag         => 'tr',
            wordwrap    => '60',
        },
    ),
    hashparams(
        [ utf8ImagedText => '|   2x|product B (each 5,00)|     10,00|' ],
        {   fontSize    => '16',
            fontStyle   => 'Normal',
            leftBorder  => '|',
            lineHeight  => '30',
            paperWidth  => '815',
            rightBorder => '|',
            separator   => '|',
            tag         => 'tr',
            wordwrap    => '60',
        },
    ),
    [ image => isa("GD::Image") ],
    hashparams(
        [ utf8ImagedText => '|                        sum|     19,00|' ],
        {   fontSize    => '16',
            fontStyle   => 'Bold',
            leftBorder  => '|',
            lineHeight  => '30',
            paperWidth  => '815',
            rightBorder => '|',
            separator   => '|',
            tag         => 'tr',
            wordwrap    => '60',
        },
    ),
    ],
    'XML translated correctly';


$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
            <escpos>
                <table
                    separator = "|||"
                >
                    <tr>
                        <td align="right">1x</td>
                        <td>product A</td>
                        <td align="right">9,00</td>
                    </tr>
                </table>
            </escpos>
        #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
my $calls = $mockprinter->{calls};
my @calls_hashes = map { my %hash = @$_; \%hash } @{$mockprinter->{calls}};
ok( (           ref $calls eq 'ARRAY'
            and @$calls == 1
            and ref $calls->[0] eq 'ARRAY'
            and eq_hash($calls_hashes[0], {
                utf8ImagedText  => '1x|||product A|||9,00',
                separator       => '|||',
                tag             => 'tr',
            })
    ),
    'XML translated correctly'
);

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
            <escpos>
                <table>
                    <td>1x</td>
                    <td>product A</td>
                    <td>9,00</td>
                </table>
            </escpos>
        #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong table tag usage: some tags are not allowed', 'correct error message';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
            <escpos>
                <table>
                    <tr>text</tr>
                </table>
            </escpos>
        #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong table tag usage: some attributes are not allowed', 'correct error message';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
            <escpos>
                <table>
                    <tr>
                        <bold>1x</bold>
                    </tr>
                </table>
            </escpos>
        #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong table tag usage: some attributes are not allowed', 'correct error message';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
          <escpos>
            <table
                separator = "|"
            >
                <tr>
                    <td align="right">1x</td>
                    <td>product A</td>
                    <td align="right">9,00</td>
                </tr>
                <tr>
                    <td align="right">2x</td>
                    <td>product B (each 5,00)</td>
                    <td align="right">10,00</td>
                </tr>
                <hr />
                <tr fontStyle="Bold">
                    <td colspan="2a">sum</td>
                    <td align="right">19,00</td>
                </tr>
            </table>
          </escpos>
        #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong table tag usage: attribute colspan must be a positive number', 'correct error message';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
          <escpos>
            <table>
                <tr>
                    <td right="1">sum</td>
                </tr>
            </table>
          </escpos>
        #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong table tag usage: some attributes are not allowed', 'correct error message';

$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
          <escpos>
            <table>
                <tr>
                    <td colspan="0">sum</td>
                </tr>
            </table>
          </escpos>
        #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong table tag usage: attribute colspan must be a positive number', 'correct error message';

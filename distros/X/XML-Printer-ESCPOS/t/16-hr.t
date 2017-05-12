#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use XML::Printer::ESCPOS;
use lib 't/lib';
use Mock::Printer::ESCPOS;

plan tests => 12;

my $mockprinter = Mock::Printer::ESCPOS->new();
my $parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

my $ret = $parser->parse(
    q#
            <escpos>
              <text>text</text>
              <hr />
              <text>text</text>
            </escpos>
        #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
my $calls = $mockprinter->{calls};
ok( (          ref $calls eq 'ARRAY'
            and @$calls == 3
            and ref $calls->[0] eq 'ARRAY'
            and is_deeply $calls->[0], [ text => 'text' ]
            and ref $calls->[1] eq 'ARRAY'
            and @{$calls->[1]} == 2
            and $calls->[1]->[0] eq 'image'
            and ref $calls->[1]->[1] eq 'GD::Image'
            and ref $calls->[2] eq 'ARRAY'
            and is_deeply $calls->[2], [ text => 'text' ]
    ),
    'XML translated correctly'
);


$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
            <escpos>
              <text>text</text>
              <hr thickness="3" />
              <text>text</text>
            </escpos>
        #
);
ok $ret => 'parsing successful';
is $parser->errormessage(), undef, 'errormessage is empty';
$calls = $mockprinter->{calls};
ok( (          ref $calls eq 'ARRAY'
            and @$calls == 3
            and ref $calls->[0] eq 'ARRAY'
            and is_deeply $calls->[0], [ text => 'text' ]
            and ref $calls->[1] eq 'ARRAY'
            and @{$calls->[1]} == 2
            and $calls->[1]->[0] eq 'image'
            and ref $calls->[1]->[1] eq 'GD::Image'
            and ref $calls->[2] eq 'ARRAY'
            and is_deeply $calls->[2], [ text => 'text' ]
    ),
    'XML translated correctly'
);


$mockprinter = Mock::Printer::ESCPOS->new();
$parser = XML::Printer::ESCPOS->new( printer => $mockprinter );

$ret = $parser->parse(
    q#
            <escpos>
              <text>text</text>
              <hr thickness="a" />
              <text>text</text>
            </escpos>
        #
);
is $ret, undef, 'parsing stopped';
is $parser->errormessage() => 'wrong hr tag usage: thickness attribute must be a positive integer', 'correct error message';
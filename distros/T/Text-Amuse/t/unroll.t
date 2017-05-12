use strict;
use warnings;
use Test::More;
use Text::Amuse::Document;
use File::Spec::Functions;
use Data::Dumper;

plan tests => 28;

my $doc = Text::Amuse::Document->new(file => catfile(t => testfiles => 'unroll.muse'));

my @expected = (
                {
                 'string' => '',
                 'type' => 'startblock',
                 'block' => 'quote'
                },
                {
                 'string' => 'hello
',
                 'type' => 'regular',
                 'block' => 'regular'
                },
                {
                 'string' => '',
                 'type' => 'stopblock',
                 'block' => 'quote'
                },
                {
                 'string' => '',
                 'type' => 'startblock',
                 'block' => 'center'
                },
                {
                 'string' => 'center
',
                 'type' => 'regular',
                 'block' => 'regular'
                },
                {
                 'string' => '',
                 'type' => 'stopblock',
                 'block' => 'center'
                },
                {
                 'string' => '',
                 'type' => 'startblock',
                 'block' => 'right'
                },
                {
                 'string' => 'right
',
                 'type' => 'regular',
                 'block' => 'regular'
                },
                {
                 'string' => '',
                 'type' => 'stopblock',
                 'block' => 'right'
                }
               );

my @got = grep { $_->type ne 'null' } $doc->elements;

is scalar(@got), scalar(@expected), "Element count is ok";
my $count = 0;
while (my $exp = shift @expected) {
    my $el = shift @got;
    # diag "testing " . ++$count . ' ' .  $el->rawline;
    is $el->type, $exp->{type}, "type $exp->{type}" or die Dumper($el, $exp);
    is $el->block, $exp->{block}, "block $exp->{block}" or die Dumper($el, $exp);
    is $el->string, $exp->{string}, "string $exp->{string}" or die Dumper($el, $exp);
}

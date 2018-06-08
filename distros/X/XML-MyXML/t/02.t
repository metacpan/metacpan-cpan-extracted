use strict;
use warnings;
use utf8;

use Test::More;

use XML::MyXML ':all';

my $simple = {
    a => [
        b => 1,
        c => 2,
    ],
};
my $xml = simple_to_xml($simple);
is $xml, '<a><b>1</b><c>2</c></a>', 'simple_to_xml of simple';

$simple = {
    a => [
        ['b'] => 1,
    ],
};
$xml = simple_to_xml($simple);
is $xml, '<a><b>1</b></a>', 'simple_to_xml of tag arrayref';

$simple = {
    a => [
        [b => {c => '2 > 3', d => undef}] => 1,
        [b => [c => '2 > 3']] => 2,
        {b => {c => '2 > 3'}} => 3,
        {b => [c => '2 > 3']} => 4,
        [b =>  c => '2 > 3' ] => 5,
    ],
};
$xml = simple_to_xml($simple);
is $xml, '<a><b c="2 &gt; 3">1</b><b c="2 &gt; 3">2</b><b c="2 &gt; 3">3</b><b c="2 &gt; 3">4</b><b c="2 &gt; 3">5</b></a>', 'tag arrayref with attrs';

my @simples;
push @simples, [
    [a => b => 1, c => 2, d => undef] => 1,
];
push @simples, [
    [a => {b => 1, c => 2}] => 1,
];
push @simples, [
    [a => [b => 1, c => 2]] => 1,
];
push @simples, [
    [a => [b => 1], {c => 2}, {d => undef}] => 1,
];
foreach my $i (1..@simples) {
    my $simple = $simples[$i - 1];
    is xml_to_object(simple_to_xml($simple))->attr('b'), 1, "attribute b of simple $i is 1";
    is xml_to_object(simple_to_xml($simple))->attr('c'), 2, "attribute c of simple $i is 2";
    is xml_to_object(simple_to_xml($simple))->attr('d'), undef, "attribute d of simple $i does not exist";
}

done_testing;

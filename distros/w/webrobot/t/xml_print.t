#!/usr/bin/perl
use strict;
use warnings;
use Carp;
$SIG{__DIE__} = \&confess;

use Test::More;
use WWW::Webrobot::XML2Tree;


my @input = (

    ["Nested expression", <<'EOS'],
<WWW.Webrobot.Assert>
    <and>
        <status value='200'/>
        <regex value='^GET$'/>
    </and>
</WWW.Webrobot.Assert>
EOS

    ["Multiple attributes", <<'EOS'],
<assert>
    <header name='Content-type' value='text/html'/>
    <not>
        <header name='xxx' value='bla'/>
    </not>
</assert>
EOS

    ["CDATA content", <<'EOS'],
<assert>
    <header name='Content-type' value='text/html'/>
    <not>
        <header name='xxx'>
bla
        </header>
    </not>
</assert>
EOS

);

plan tests => 1 + scalar @input;


foreach (@input) {
    my ($description, $input) = @$_;
    my $parser = WWW::Webrobot::XML2Tree->new();
    my $tree = $parser->parse($input);
    shift @$tree;
    my $output = WWW::Webrobot::XML2Tree::print_xml($tree);
    is($output, $input, $description);
}


my $two_elements_tree = [
   'status',
    [
        {
            'value' => '200'
        }
    ],
    'regex',
    [
        {
            'value' => 'GET'
        }
    ],
];
my $two_elements_string = <<'EOS';
<status value='200'/>
<regex value='GET'/>
EOS

is(WWW::Webrobot::XML2Tree::print_xml(
    $two_elements_tree),
    $two_elements_string,
    "two elements (XML without root element)"
);

1;

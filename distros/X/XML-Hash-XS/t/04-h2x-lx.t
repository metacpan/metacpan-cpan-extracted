
use strict;
use warnings;

use Test::More tests => 15;

use XML::Hash::XS 'hash2xml';

$XML::Hash::XS::method = 'LX';
$XML::Hash::XS::trim   = 1;

our $xml_decl = qq{<?xml version="1.0" encoding="utf-8"?>\n};

{
    is
        hash2xml( { root => { '#text' => ' zzzz ' } } ),
        qq{$xml_decl<root>zzzz</root>},
        'text',
    ;
}
{
    is
        hash2xml( { root => { sub => 'test' } } ),
        qq{$xml_decl<root><sub>test</sub></root>},
        'node',
    ;
}
{
    is
        hash2xml( { root => { -attr => "test < > & \" \t \n \r end" } } ),
        qq{$xml_decl<root attr="test &lt; &gt; &amp; &quot; &#9; &#10; &#13; end"></root>},
        'attr',
    ;
}
{
    is
        hash2xml( { root => { _attr => "test" } }, attr => '_' ),
        qq{$xml_decl<root attr="test"></root>},
        'attr _',
    ;
}
{
    is
        hash2xml( { root => { '~' => "zzzz < > & \r end" } }, text => '~' ),
        qq{$xml_decl<root>zzzz &lt; &gt; &amp; &#13; end</root>},
        'text ~',
    ;
}
{
    is
        hash2xml( { root => " \t\ntest" }, trim => 1 ),
        qq{$xml_decl<root>test</root>},
        'trim 1',
    ;
    is
        hash2xml( { root => " \t\ntest" }, trim => 0 ),
        qq{$xml_decl<root> \t\ntest</root>},
        'trim 0',
    ;
}
{
    is
        hash2xml( { root => { sub => { '@' => "cdata < > & \" \t \n \r end" } } }, cdata => '@' ),
        qq{$xml_decl<root><sub><![CDATA[cdata < > & \" \t \n \r end]]></sub></root>},
        'cdata @',
    ;
}
{
    is
        hash2xml( { root => { sub => { '/' => "comment < > & \" \t \n \r end" } } },comm => '/' ),
        qq{$xml_decl<root><sub><!--comment < > & \" \t \n \r end--></sub></root>},
        'comm /',
    ;
}
{
    is
        hash2xml( { root => { -attr => undef } } ),
        qq{$xml_decl<root attr=""></root>},
        'empty attr',
    ;
}
{
    is
        hash2xml( { root => { '#cdata' => undef } }, cdata => '#cdata' ),
        qq{$xml_decl<root></root>},
        'empty cdata',
    ;
}
{
    is
        hash2xml( { root => { '/' => undef } }, comm => '/' ),
        qq{$xml_decl<root><!----></root>},
        'empty comment',
    ;
}
{
    is
        hash2xml( { root => { x=>undef } } ),
        qq{$xml_decl<root><x/></root>},
        'empty tag',
    ;
}
{
    is
        hash2xml( { root => { item => [1, 2, 3, { -attr => 4, node => 5 }, [6, 7] ] } } ),
        qq{$xml_decl<root><item>1</item><item>2</item><item>3</item><item attr="4"><node>5</node></item><item><item>6</item><item>7</item></item></root>},
        'array',
    ;
}
SKIP: {
    my $data;
    eval { $data = hash2xml( { root => {  test => "Тест" } }, encoding => 'cp1251' ) };
    my $err = $@;
    chomp $err;
    skip $err, 1 if $err;
    is
        $data,
        qq{<?xml version="1.0" encoding="cp1251"?>\n<root><test>\322\345\361\362</test></root>},
        'encoding support',
    ;
}

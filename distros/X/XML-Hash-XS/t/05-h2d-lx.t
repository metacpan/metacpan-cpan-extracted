
use strict;
use warnings;

use Test::More;

use XML::Hash::XS;

our $c;
eval { $c = XML::Hash::XS->new(doc => 1, method => 'LX', trim => 1) };
if ($@) {
    plan skip_all => "Option 'doc' is not supported";
}
else {
    plan tests => 14;
    require XML::LibXML;
}

our $xml_decl = qq{<?xml version="1.0" encoding="utf-8"?>\n};

## no critic (Subroutines::ProhibitSubroutinePrototypes)
sub fix_xml($) { my $xml = shift; chomp $xml; $xml =~ s|(<\w[^</>]*[^/])></\w+>|$1/>|g; $xml }
## use critic

{
    is
        fix_xml $c->hash2xml( { root => { '#text' => ' zzzz ' } } )->toString(),
        qq{$xml_decl<root>zzzz</root>},
        'text',
    ;
}
{
    is
        fix_xml $c->hash2xml( { root => { sub => 'test' } } )->toString(),
        qq{$xml_decl<root><sub>test</sub></root>},
        'node',
    ;
}
{
    is
        fix_xml $c->hash2xml( { root => { -attr => "test < > & \" \t \n \r end" } } )->toString(),
        qq{$xml_decl<root attr="test &lt; &gt; &amp; &quot; &#9; &#10; &#13; end"/>},
        'attr',
    ;
}
{
    is
        fix_xml $c->hash2xml( { root => { _attr => "test" } }, attr => '_' )->toString(),
        qq{$xml_decl<root attr="test"/>},
        'attr _',
    ;
}
{
    is
        fix_xml $c->hash2xml( { root => { '~' => "zzzz < > & \r end" } }, text => '~' )->toString(),
        qq{$xml_decl<root>zzzz &lt; &gt; &amp; &#13; end</root>},
        'text ~',
    ;
}
{
    is
        fix_xml $c->hash2xml( { root => " \t\ntest" }, trim => 1 )->toString(),
        qq{$xml_decl<root>test</root>},
        'trim 1',
    ;
    is
        fix_xml $c->hash2xml( { root => " \t\ntest" }, trim => 0 )->toString(),
        qq{$xml_decl<root> \t\ntest</root>},
        'trim 0',
    ;
}
{
    is
        fix_xml $c->hash2xml( { root => { sub => { '@' => "cdata < > & \" \t \n \r end" } } }, cdata => '@' )->toString(),
        qq{$xml_decl<root><sub><![CDATA[cdata < > & \" \t \n \r end]]></sub></root>},
        'cdata @',
    ;
}
{
    is
        fix_xml $c->hash2xml( { root => { sub => { '/' => "comment < > & \" \t \n \r end" } } },comm => '/' )->toString(),
        qq{$xml_decl<root><sub><!--comment < > & \" \t \n \r end--></sub></root>},
        'comm /',
    ;
}
{
    is
        fix_xml $c->hash2xml( { root => { -attr => undef, '#text' => 'text' } } )->toString(),
        qq{$xml_decl<root attr="">text</root>},
        'empty attr',
    ;
}
{
    is
        fix_xml $c->hash2xml( { root => { '#cdata' => undef, '#text' => 'text' } }, cdata => '#cdata' )->toString(),
        qq{$xml_decl<root>text</root>},
        'empty cdata',
    ;
}
{
    is
        fix_xml $c->hash2xml( { root => { '/' => undef } }, comm => '/' )->toString(),
        qq{$xml_decl<root><!----></root>},
        'empty comment',
    ;
}
{
    is
        fix_xml $c->hash2xml( { root => { item => [1, 2, 3, { -attr => 4, node => 5 }, [6, 7] ] } } )->toString(),
        qq{$xml_decl<root><item>1</item><item>2</item><item>3</item><item attr="4"><node>5</node></item><item><item>6</item><item>7</item></item></root>},
        'array',
    ;
}
SKIP: {
    my $data;
    eval { $data = fix_xml $c->hash2xml( { root => {  test => "Тест" } }, encoding => 'cp1251' )->toString() };
    my $err = $@;
    chomp $err;
    skip $err, 1 if $err;
    chomp $data;
    is
        $data,
        qq{<?xml version="1.0" encoding="cp1251"?>\n<root><test>\322\345\361\362</test></root>},
        'encoding support',
    ;
}

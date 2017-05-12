package main;
use strict;
use warnings;

use Test::More tests => 10;
use Data::Dumper;
$Data::Dumper::Indent = 0;
$Data::Dumper::Sortkeys = 1;

use XML::Hash::XS 'xml2hash';

our $xml_decl_utf8 = qq{<?xml version="1.0" encoding="utf-8"?>};

{
    is
        Dumper(xml2hash(<<"XML", keep_root => 1, content => 'text', trim => 1)),
<root attr1="1" attr2="2">
    <node1>value1</node1>
    <node2 attr1="1">value2</node2>
    <node3>
        content1
        <!-- comment -->
        content2
    </node3>
    <node4>
        content1
        <empty_node4/>
        content2
    </node4>
    <item>1</item>
    <item>2</item>
    <item>3</item>
    <cdata><![CDATA[
        abcde!@#$%^&*<>
    ]]></cdata>
    <cdata2><![CDATA[ abc ]]]></cdata2>
    <cdata3><![CDATA[ [ abc ] ]> ]]]]]]></cdata3>
</root>
XML
        Dumper({
root => {
    attr1  => '1',
    attr2  => '2',
    cdata  => 'abcde!@#0^&*<>',
    cdata2 => 'abc ]',
    cdata3 => '[ abc ] ]> ]]]]',
    item   => ['1', '2', '3'],
    node1  => 'value1',
    node2  => {
        attr1 => '1',
        text  => 'value2',
    },
    node3  => ['content1', 'content2'],
    node4  => {
        text        => ['content1', 'content2'],
        empty_node4 => '',
    },
}
}),
        'complex',
    ;
}

{
    use utf8;
    my $xml = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<note>Test</note>
XML
    no warnings qw(void);
    substr $xml, 0, 0; # this will cause error in XS param type definition
    is
        xml2hash(\$xml, trim => 1),
        'Test',
        'check validation parameters',
    ;
}

{
    my $xml=qq[<?xml version="1.0" encoding="utf-8"?>\x0D\x0A<aaaa>\x0D\x0Aasdasdsa\x0D\x0A</aaaa>];
    is
        xml2hash(\$xml, trim => 1),
        'asdasdsa',
        'bug RT#103002',
    ;
}

{
    my $xml=qq[<a>\x0D\x0Aasd\x0D\x0Aasd\x0D\x0D\x0Aasd\x0D\x0A</a>];
    is
        xml2hash(\$xml, trim => 1),
        "asd\x0Aasd\x0A\x0Aasd",
        'normalize line feeds',
    ;
}

{
    is
        Dumper(xml2hash(<<"XML")),
<root>
    <aaa>bbb<!-- ccc -->ddd<eee>fff</eee>ggg</aaa>
</root>
XML
        Dumper({aaa => { content => ['bbb', 'ddd', 'ggg'], eee => 'fff' }}),
        'bug with many contents in the one node',
    ;
}

{
    eval { xml2hash("<root></root><root2></root2>") };
    ok($@, 'invalid xml');
}

{
    eval { xml2hash("<root></root><root2>") };
    ok($@, 'invalid xml2');
}

{
    eval { xml2hash("</root>") };
    ok($@, 'invalid xml3');
}

{
    eval { xml2hash("<root></root>text") };
    ok($@, 'invalid xml4');
}

{
    is
        Dumper(xml2hash(<<"XML")),
<root>
    <row>
        <cell text="test&apos;s"/>
    </row>
    <row>
        <cell text=" test&apos;s"/>
    </row>
</root>
XML
        Dumper({
            row => [
                {cell => {'text' => "test's"}},
                {cell => {'text' => " test's"}},
            ],
        }),
        'memory allocation bug',
    ;
}

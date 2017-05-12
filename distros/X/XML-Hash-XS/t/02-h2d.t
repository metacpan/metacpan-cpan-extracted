package main;
use strict;
use warnings;

use Test::More;
use File::Temp qw(tempfile);

use XML::Hash::XS;

our $c;
eval { $c = XML::Hash::XS->new(doc => 1) };
if ($@) {
    plan skip_all => "Option 'doc' is not supported";
}
else {
    plan tests => 13;
    require XML::LibXML;
}

## no critic (Subroutines::ProhibitSubroutinePrototypes)
sub fix_xml($) { my $xml = shift; chomp $xml; $xml =~ s|(<\w[^</>]*[^/])></\w+>|$1/>|g; $xml }
## use critic

our $xml_decl = qq{<?xml version="1.0" encoding="utf-8"?>};

{
    is
        fix_xml $c->hash2xml( { node1 => [ 'value1', { node2 => 'value2' } ] } )->toString(),
        qq{$xml_decl\n<root><node1>value1</node1><node1><node2>value2</node2></node1></root>},
        'default',
    ;
}

{
    is
        fix_xml $c->hash2xml( { node3 => 'value3', node1 => 'value1', node2 => 'value2' }, canonical => 1 )->toString(),
        qq{$xml_decl\n<root><node1>value1</node1><node2>value2</node2><node3>value3</node3></root>},
        'canonical',
    ;
}

{
    is
        fix_xml $c->hash2xml( { node1 => [ 1, '2', '2' + 1 ] } )->toString(),
        qq{$xml_decl\n<root><node1>1</node1><node1>2</node1><node1>3</node1></root>},
        'integer, string, integer + string',
    ;
}

{
    my $x = 1.1;
    my $y = '2.2';
    is
        fix_xml $c->hash2xml( { node1 => [ $x, $y, $y + $x ] } )->toString(),
        qq{$xml_decl\n<root><node1>1.1</node1><node1>2.2</node1><node1>3.3</node1></root>},
        'double, string, double + string',
    ;
}

{
    is
        fix_xml $c->hash2xml( { 1 => 'value1' } )->toString(),
        qq{$xml_decl\n<root><_1>value1</_1></root>},
        'quote tag name',
    ;
}

SKIP: {
    my $data;
    eval { $data = fix_xml $c->hash2xml( { node1 => 'Тест' }, encoding => 'cp1251' )->toString(); };
    my $err = $@;
    chomp $err;
    skip $err, 1 if $err;
    is
        $data,
        qq{<?xml version="1.0" encoding="cp1251"?>\n<root><node1>\322\345\361\362</node1></root>},
        'encoding support',
    ;
}

{
    is
        fix_xml $c->hash2xml( { node1 => "< > & \r" } )->toString(),
        qq{$xml_decl\n<root><node1>&lt; &gt; &amp; &#13;</node1></root>},
        'escaping',
    ;
}

{
    is
        fix_xml $c->hash2xml( { node => " \t\ntest "  }, trim => 0 )->toString(),
        qq{$xml_decl\n<root><node> \t\ntest </node></root>},
        'trim 0',
    ;
    is
        fix_xml $c->hash2xml( { node => " \t\ntest "  }, trim => 1 )->toString(),
        qq{$xml_decl\n<root><node>test</node></root>},
        'trim 1',
    ;
}

{
    is
        fix_xml $c->hash2xml(
            {
                node1 => 'value1"',
                node2 => 'value2&',
                node3 => { node31 => 'value31', t => [ 'text' ] },
                node4 => [ { node41 => 'value41', t => [ 'text' ] }, { node42 => 'value42', t => [ 'text' ] } ],
                node5 => [ 51, 52, { node53 => 'value53', t => [ 'text' ] } ],
                node6 => [],
            },
            use_attr  => 1,
            canonical => 1,
            indent    => 2,
        )->toString(),
        qq{$xml_decl\n<root node1="value1&quot;" node2="value2&amp;"><node3 node31="value31"><t>text</t></node3><node4 node41="value41"><t>text</t></node4><node4 node42="value42"><t>text</t></node4><node5>51</node5><node5>52</node5><node5 node53="value53"><t>text</t></node5></root>},
        'use attributes',
    ;
}

{
    is
        fix_xml $c->hash2xml(
            {
                content => 'content&1',
                node2   => [ 21, {
                    node22  => "value22 < > & \" \t \n \r",
                    content => "content < > & \r",
                } ],
            },
            use_attr  => 1,
            canonical => 1,
            indent    => 2,
            content   => 'content',
        )->toString(),
        qq{$xml_decl\n<root>content&amp;1<node2>21</node2><node2 node22="value22 &lt; &gt; &amp; &quot; &#9; &#10; &#13;">content &lt; &gt; &amp; &#13;</node2></root>},
        'content',
    ;
}

{
    my @arr = (1, 2, 3, { att1 => 1, att2 => 2});
    my $obj = new Iterator sub { shift @arr };
    is
        fix_xml $c->hash2xml(
            {
                iterator => $obj,
            },
            use_attr  => 1,
            canonical => 1,
            indent    => 2,
            content   => 'content',
        )->toString(),
        qq{$xml_decl\n<root><iterator>1</iterator><iterator>2</iterator><iterator>3</iterator><iterator att1="1" att2="2"/></root>},
        'content & attr',
    ;
}

{
    my @arr = (1, 2, 3, { att1 => 1, att2 => 2});
    my $obj = new Iterator sub { shift @arr };
    is
        fix_xml $c->hash2xml(
            {
                iterator => $obj,
            },
            use_attr  => 0,
            canonical => 1,
            indent    => 2,
            content   => 'content',
        )->toString(),
        qq{$xml_decl\n<root><iterator>1</iterator><iterator>2</iterator><iterator>3</iterator><iterator><att1>1</att1><att2>2</att2></iterator></root>},
        'iterator',
    ;
}

package Iterator;

sub new {
    my ($class, $cb) = @_;
    return bless { cb => $cb }, $class;
}

sub iternext {
    return shift->{cb}->();
}

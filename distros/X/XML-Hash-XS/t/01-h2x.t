package main;
use strict;
use warnings;

use Test::More tests => 25;
use File::Temp qw(tempfile);

use XML::Hash::XS 'hash2xml';

our $xml_decl = qq{<?xml version="1.0" encoding="utf-8"?>};

{
    is
        hash2xml( { node1 => [ 'value1', { node2 => 'value2' } ] } ),
        qq{$xml_decl\n<root><node1>value1</node1><node1><node2>value2</node2></node1></root>},
        'default',
    ;
}

{
    is
        hash2xml( { node1 => [ 'value1', { node2 => 'value2' } ] }, keep_root => 0, xml_decl => 0 ),
        qq{<node1>value1</node1><node1><node2>value2</node2></node1>},
        'rootless',
    ;
}

{
    is
        hash2xml( { node3 => 'value3', node1 => 'value1', node2 => 'value2' }, canonical => 1 ),
        qq{$xml_decl\n<root><node1>value1</node1><node2>value2</node2><node3>value3</node3></root>},
        'canonical',
    ;
}

{
    is
        hash2xml( { node1 => [ 'value1', { node2 => 'value2' } ] }, indent => 2 ),
        <<"EOT",
$xml_decl
<root>
  <node1>value1</node1>
  <node1>
    <node2>value2</node2>
  </node1>
</root>
EOT
        'indent',
    ;
}

{
    is
        hash2xml( { node1 => [ 1, '2', '2' + 1 ] } ),
        qq{$xml_decl\n<root><node1>1</node1><node1>2</node1><node1>3</node1></root>},
        'integer, string, integer + string',
    ;
}

{
    my $x = 1.1;
    my $y = '2.2';
    is
        hash2xml( { node1 => [ $x, $y, $y + $x ] } ),
        qq{$xml_decl\n<root><node1>1.1</node1><node1>2.2</node1><node1>3.3</node1></root>},
        'double, string, double + string',
    ;
}

{
    is
        hash2xml( { 1 => 'value1' } ),
        qq{$xml_decl\n<root><_1>value1</_1></root>},
        'quote tag name',
    ;
}

{
    is
        hash2xml( { node1 => \'value1' } ),
        qq{$xml_decl\n<root><node1>value1</node1></root>},
        'scalar reference',
    ;
}

{
    is
        hash2xml( { node1 => sub { 'value1' } } ),
        qq{$xml_decl\n<root><node1>value1</node1></root>},
        'code reference',
    ;
}

{
    is
        hash2xml( { node1 => sub { undef } } ),
        qq{$xml_decl\n<root><node1/></root>},
        'code reference with undef',
    ;
}

{
    is
        hash2xml( { node1 => sub { [ 'value1' ] } } ),
        qq{$xml_decl\n<root><node1>value1</node1></root>},
        'code reference with array',
    ;
}

SKIP: {
    my $data;
    eval { $data = hash2xml( { node1 => 'Тест' }, encoding => 'cp1251' ) };
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
        hash2xml( { node1 => "< > & \r" } ),
        qq{$xml_decl\n<root><node1>&lt; &gt; &amp; &#13;</node1></root>},
        'escaping',
    ;
}

{
    is
        hash2xml( { node => " \t\ntest "  }, trim => 0 ),
        qq{$xml_decl\n<root><node> \t\ntest </node></root>},
        'trim 0',
    ;
    is
        hash2xml( { node => " \t\ntest "  }, trim => 1 ),
        qq{$xml_decl\n<root><node>test</node></root>},
        'trim 1',
    ;
}

{
    my $data;
    my $fh = tempfile();
    hash2xml( { node1 => 'value1' }, output => $fh );
    seek($fh, 0, 0);
    { local $/; $data = <$fh> }
    is
        $data,
        qq{$xml_decl\n<root><node1>value1</node1></root>},
        'filehandle output',
    ;
}

{
    my $data = '';
    tie *STDOUT, "Trapper", \$data;
    hash2xml( { node1 => 'value1' }, output => \*STDOUT );
    untie *STDOUT;
    is
        $data,
        qq{$xml_decl\n<root><node1>value1</node1></root>},
        'tied filehandle output',
    ;
}

{
    is
        hash2xml(
            {
                node1 => 'value1"',
                node2 => 'value2&',
                node3 => { node31 => 'value31' },
                node4 => [ { node41 => 'value41' }, { node42 => 'value42' } ],
                node5 => [ 51, 52, { node53 => 'value53' } ],
                node6 => {},
                node7 => [],
            },
            use_attr  => 1,
            canonical => 1,
            indent    => 2,
        ),
        <<"EOT",
$xml_decl
<root node1="value1&quot;" node2="value2&amp;">
  <node3 node31="value31"/>
  <node4 node41="value41"/>
  <node4 node42="value42"/>
  <node5>51</node5>
  <node5>52</node5>
  <node5 node53="value53"/>
  <node6/>
</root>
EOT
        'use attributes',
    ;
}

{
    is
        hash2xml(
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
        ),
        <<"EOT",
$xml_decl
<root>
  content&amp;1
  <node2>21</node2>
  <node2 node22="value22 &lt; &gt; &amp; &quot; &#9; &#10; &#13;">
    content &lt; &gt; &amp; &#13;
  </node2>
</root>
EOT
        'content',
    ;
}

{
    my $o = TestObject->new();
    is
        hash2xml(
            { object => $o },
        ),
        qq{$xml_decl\n<root><object><root attr="1">value1</root></object></root>},
        'object',
    ;
}

{
    my $o = TestObjectWithOverloadedStringification->new('test');
    is
        hash2xml({ object => $o }),
        qq{$xml_decl\n<root><object>test</object></root>},
        'object with overloaded stringification',
    ;
}

{
    $XML::Hash::XS::indent    = 2;
    $XML::Hash::XS::use_attr  = 1;
    $XML::Hash::XS::canonical = 1;
    $XML::Hash::XS::content   = 'content';
    is
        hash2xml(
            {
                content => 'content&1',
                node2   => [ 21, { node22 => 'value23', 'content' => 'content2' } ],
            },
        ),
        <<"EOT",
$xml_decl
<root>
  content&amp;1
  <node2>21</node2>
  <node2 node22="value23">
    content2
  </node2>
</root>
EOT
        'global options',
    ;
}

{
    $XML::Hash::XS::indent    = 2;
    $XML::Hash::XS::use_attr  = 1;
    $XML::Hash::XS::canonical = 1;
    $XML::Hash::XS::content   = 'content';
    $XML::Hash::XS::xml_decl  = 0;
    is
        hash2xml(
            {
                node1 => 'value1',
            },
        ),
        <<"EOT",
<root node1="value1"/>
EOT
        'xml declaration',
    ;
}

{
    $XML::Hash::XS::indent    = 2;
    $XML::Hash::XS::use_attr  = 1;
    $XML::Hash::XS::canonical = 1;
    $XML::Hash::XS::xml_decl  = 0;
    my @arr = (1, 2, 3, { att1 => 1, att2 => 2 });
    my $obj = new Iterator sub { shift @arr };
    is
        hash2xml(
            {
                iterator => $obj,
            },
        ),
        <<"EOT",
<root>
  <iterator>1</iterator>
  <iterator>2</iterator>
  <iterator>3</iterator>
  <iterator att1="1" att2="2"/>
</root>
EOT
        'iterator & attr',
    ;
}

{
    $XML::Hash::XS::indent    = 2;
    $XML::Hash::XS::use_attr  = 0;
    $XML::Hash::XS::canonical = 1;
    $XML::Hash::XS::xml_decl  = 0;
    my @arr = (1, 2, 3, { att1 => 1, att2 => 2});
    my $obj = new Iterator sub { shift @arr };
    is
        hash2xml(
            {
                iterator => $obj,
            },
        ),
        <<"EOT",
<root>
  <iterator>1</iterator>
  <iterator>2</iterator>
  <iterator>3</iterator>
  <iterator>
    <att1>1</att1>
    <att2>2</att2>
  </iterator>
</root>
EOT
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

package TestObject;

sub new {
    return bless [], shift;
}

sub toString {
    return '<root attr="1">value1</root>';
}

package TestObjectWithOverloadedStringification;

use overload '""' => sub { shift->stringify }, fallback => 1;

sub new {
    my ($class, $value) = @_;
    return bless { value => $value }, $class;
}

sub stringify {
    return shift->{value};
}

package Trapper;

sub TIEHANDLE {
    my ($class, $str) = @_;
    return bless [$str], $class;
}

sub WRITE {
    my ($self, $buf, $len, $offset) = @_;

    $len    ||= length($buf);
    $offset ||= 0;

    ${$self->[0]} .= substr($buf, $offset, $len);

    return $len;
}

sub PRINT {
    ${shift->[0]} .= join('', @_);
}

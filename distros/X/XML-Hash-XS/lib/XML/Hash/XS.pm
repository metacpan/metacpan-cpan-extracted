package XML::Hash::XS;

use 5.008008;
use strict;
use warnings;
use vars qw($VERSION @EXPORT @EXPORT_OK);
use base 'Exporter';
@EXPORT_OK = @EXPORT = qw( hash2xml xml2hash );

$VERSION = '0.62';

require XSLoader;
XSLoader::load('XML::Hash::XS', $VERSION);

use vars qw($method $output $root $version $encoding $utf8 $indent $canonical
    $use_attr $content $xml_decl $doc $max_depth $attr $text $trim $cdata
    $comm $buf_size $keep_root $force_array $force_content $merge_text
    $suppress_empty
);

# 'NATIVE' or 'LX'
$method         = 'NATIVE';

# native options
$output         = undef;
$root           = 'root';
$version        = '1.0';
$encoding       = '';
$utf8           = 1;
$indent         = 0;
$canonical      = 0;
$use_attr       = 0;
$content        = undef;
$xml_decl       = 1;
$keep_root      = 1;
$doc            = 0;
$max_depth      = 1024;
$buf_size       = 4096;
$trim           = 0;
$force_array    = undef;
$force_content  = 0;
$merge_text     = 0;
$suppress_empty = 0;

# XML::Hash::LX options
$attr           = '-';
$text           = '#text';
$cdata          = undef;
$comm           = undef;

1;
__END__
=head1 NAME

XML::Hash::XS - Simple and fast hash to XML and XML to hash conversion written in C

=begin HTML

<p><a href="https://metacpan.org/pod/XML::Hash::XS" target="_blank"><img alt="CPAN version" src="https://badge.fury.io/pl/XML-Hash-XS.svg"></a> <a href="https://travis-ci.org/yoreek/XML-Hash-XS" target="_blank"><img title="Build Status Images" src="https://travis-ci.org/yoreek/XML-Hash-XS.svg"></a></p>

=end HTML

=head1 SYNOPSIS

    use XML::Hash::XS;

    my $xmlstr = hash2xml \%hash;
    hash2xml \%hash, output => $fh;

    my $hash = xml2hash $xmlstr;
    my $hash = xml2hash \$xmlstr;
    my $hash = xml2hash 'test.xml', encoding => 'cp1251';
    my $hash = xml2hash $fh;
    my $hash = xml2hash *STDIN;

Or OOP way:

    use XML::Hash::XS qw();

    my $conv   = XML::Hash::XS->new(utf8 => 0, encoding => 'utf-8')
    my $xmlstr = $conv->hash2xml(\%hash, utf8 => 1);
    my $hash   = $conv->xml2hash($xmlstr, encoding => 'cp1251');

=head1 DESCRIPTION

This module implements simple hash to XML and XML to hash conversion written in C.

During conversion uses minimum of memory, XML or hash is written directly without building DOM.

Some features are optional and are available with appropriate libraries:

=over 2

=item * XML::LibXML library is required  in order to build DOM

=item * ICU or iconv library is required in order to perform charset conversions

=back

=head1 FUNCTIONS

=head2 hash2xml $hash, [ %options ]

$hash is reference to hash

    hash2xml
        {
            node1 => 'value1',
            node2 => [ 'value21', { node22 => 'value22' } ],
            node3 => \'value3',
            node4 => sub { return 'value4' },
            node5 => sub { return { node51 => 'value51' } },
        },
        canonical => 1,
        indent    => 2,
    ;

will convert to:

    <?xml version="1.0" encoding="utf-8"?>
    <root>
      <node1>value1</node1>
      <node2>value21</node2>
      <node2>
        <node22>value22</node22>
      </node2>
      <node3>value3</node3>
      <node4>value4</node4>
      <node5>
        <node51>value51</node51>
      </node5>
    </root>

and (use_attr=1):

    hash2xml
        {
            node1 => 'value1',
            node2 => [ 'value21', { node22 => 'value22' } ],
            node3 => \'value3',
            node4 => sub { return 'value4' },
            node5 => sub { return { node51 => 'value51' } },
        },
        use_attr  => 1,
        canonical => 1,
        indent    => 2,
    ;

will convert to:

    <?xml version="1.0" encoding="utf-8"?>
    <root node1="value1" node3="value3" node4="value4">
      <node2>value21</node2>
      <node2 node22="value22"/>
      <node5 node51="value51"/>
    </root>


=head2 xml2hash $xml, [ %options ]

$xml may be string, reference to string, file handle or tied file handle:

    xml2hash '<root>text</root>';
    # output: 'text'

    xml2hash '<root a="1" b="2">text</root>';
    # output: { a => '1', b => '2', content => 'text' }

    open(my $fh, '<', 'test.xml');
    xml2hash $fh;

    xml2hash *STDIN;

=head1 OPTIONS

=over 4

=item doc [ => 0 ] I<# hash2xml>

if doc is '1', then returned value is L<XML::LibXML::Document>.

=item root [ = 'root' ] I<# hash2xml>

Root node name.

=item version [ = '1.0' ] I<# hash2xml>

XML document version

=item encoding [ = 'utf-8' ] I<# hash2xml+xml2hash>

XML input/output encoding

=item indent [ = 0 ] I<# hash2xml>

if indent great than "0", XML output should be indented according to its hierarchic structure.
This value determines the number of spaces.

if indent is "0", XML output will all be on one line.

=item output [ = undef ] I<# hash2xml>

XML output method

if output is undefined, XML document dumped into string.

if output is FH, XML document writes directly to a filehandle or a stream.

=item canonical [ = 0 ] I<# hash2xml>

if canonical is "1", converter will be write hashes sorted by key.

if canonical is "0", order of the element will be pseudo-randomly.

=item use_attr [ = 0 ] I<# hash2xml>

if use_attr is "1", converter will be use the attributes.

if use_attr is "0", converter will be use tags only.

=item content [ = undef ] I<# hash2xml+xml2hash>

if defined that the key name for the text content(used only if use_attr=1).

=item force_array => [ = undef ] I<# xml2hash>

This option is similar to "ForceArray" from XML::Simple module: L<https://metacpan.org/pod/XML::Simple#ForceArray-=%3E-1-%23-in-important>.

=item force_content => [ = 0 ] I<# xml2hash>

This option is similar to "ForceContent" from XML::Simple module: L<https://metacpan.org/pod/XML::Simple#ForceContent-=%3E-1-%23-in-seldom-used>.

=item merge_text [ = 0 ] I<# xml2hash>

Setting this option to "1" will cause merge adjacent text nodes.

=item xml_decl [ = 1 ] I<# hash2xml>

if xml_decl is "1", output will start with the XML declaration '<?xml version="1.0" encoding="utf-8"?>'.

if xml_decl is "0", XML declaration will not be output.

=item trim [ = 0 ] I<# hash2xml+xml2hash>

Trim leading and trailing whitespace from text nodes.

=item suppress_empty => [ = 0 ] I<# xml2hash>

This option is similar to "SuppressEmpty" from XMl::Simple module: L<https://metacpan.org/pod/XML::Simple#SuppressEmpty-=%3E-1-%7C-''-%7C-undef-%23-in+out-handy>.

=item utf8 [ = 1 ] I<# hash2xml+xml2hash>

Turn on utf8 flag for strings if enabled.

=item max_depth [ = 1024 ] I<# xml2hash>

Maximum recursion depth.

=item buf_size [ = 4096 ] I<# hash2xml+xml2hash>

Buffer size for reading end encoding data.

=item keep_root [ = 1 ] I<# hash2xml+xml2hash>

Keep root element.

=item filter [ = undef ] I<# xml2hash>

Filter nodes matched by pattern and return reference to array of nodes.

Sample:

    my $xml = <<'XML';
        <root>
           <item1>111</item1>
           <item2>222</item2>
           <item3>333</item3>
        </root>
    XML

    my $nodes = xml2hash($xml, filter => '/root/item1');
    # $nodes = [ 111 ]

    my $nodes = xml2hash($xml, filter => ['/root/item1', '/root/item2']);
    # $nodes = [ 111, 222 ]

    my $nodes = xml2hash($xml, filter => qr[/root/item\d$]);
    # $nodes = [ 111, 222, 333 ]

It may be used to parse large XML because does not require a lot of memory.

=item cb [ = undef ] I<# xml2hash>

This option is used in conjunction with "filter" option and defines callback
that will called for each matched node.

Sample:

    xml2hash($xml, filter => qr[/root/item\d$], cb => sub {
        print $_[0], "\n";
    });
    # 111
    # 222
    # 333

=item method [ = 'NATIVE' ] I<# hash2xml>

experimental support the conversion methods other libraries

if method is 'LX' then conversion result is the same as using L<XML::Hash::LX> library

Note: for 'LX' method following additional options are available:
    attr
    cdata
    text
    comm

=back

=head1 OBJECT SERIALISATION(hash2xml)

=over 2

=item 1. When object has a "toString" method

In this case, the <toString> method of object is invoked in scalar context.
It must return a single scalar that can be directly encoded into XML.

Example:

    use XML::LibXML;
    local $XML::LibXML::skipXMLDeclaration = 1;
    my $doc = XML::LibXML->new->parse_string('<foo bar="1"/>');
    print hash2xml({ doc => $doc }, indent => 2, xml_decl => 0);
    =>
    <root>
      <doc><foo bar="1"/></doc>
    </root>

=item 2. When object has overloaded stringification

In this case, the stringification method of object is invoked and result is directly encoded into XML.

Example:

    package Test {
        use overload '""' => sub { shift->stringify }, fallback => 1;
        sub new {
            my ($class, $str) = @_;
            bless { str => $str }, $class;
        }
        sub stringify {
            shift->{str}
        }
    }
    my $obj = Test->new('test string');
    print hash2xml({ obj => $obj }, indent => 2, xml_decl => 0);
    =>
    <root>
      <obj>test string</obj>
    </root>

=item 3. When object has a "iternext" method ("NATIVE" method only)

In this case, the <iternext> method method will invoke a few times until the return value is not undefined.

Example:

    my $count = 0;
    my $o = bless {}, 'Iterator';
    *Iterator::iternext = sub { $count++ < 3 ? { count => $count } : undef };
    print hash2xml({ item => $o }, use_attr => 1, indent => 2, xml_decl => 0);
    =>
    <root>
      <item count="1"/>
      <item count="2"/>
      <item count="3"/>
    </root>

This can be used to generate a large XML using minimum memory, example with DBI:

    my $sth = $dbh->prepare('SELECT * FROM foo WHERE bar=?');
    $sth->execute(...);
    my $o = bless {}, 'Iterator';
    *Iterator::iternext = sub { $sth->fetchrow_hashref() };
    open(my $fh, '>', 'data.xml');
    hash2xml({ row => $o }, use_attr => 1, indent => 2, xml_decl => 0, output => $fh);
    =>
    <root>
      <row bar="..." ... />
      <row bar="..." ... />
      ...
    </root>

=back

=head1 BENCHMARK

Performance benchmark in comparison with some popular modules(hash2xml):

                    Rate     XML::Hash XML::Hash::LX   XML::Simple XML::Hash::XS
    XML::Hash     65.0/s            --           -6%          -37%          -99%
    XML::Hash::LX 68.8/s            6%            --          -33%          -99%
    XML::Simple    103/s           58%           49%            --          -98%
    XML::Hash::XS 4879/s         7404%         6988%         4658%            --

Benchmark was done on L<http://search.cpan.org/uploads.rdf>

=head1 AUTHOR

Yuriy Ustushenko, E<lt>yoreek@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2021 Yuriy Ustushenko

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package XML::GenericJSON;
use Exporter;

@ISA = ('Exporter');
@EXPORT = qw();
our $VERSION = 0.05;

use strict;
use warnings;

use XML::LibXML;
use JSON::XS;

=head1 NAME

XML::GenericJSON - for turning XML into JSON, preserving as much XMLness as possible.

=head1 SYNOPSIS

my $json_string = XML::GenericJSON::string2string($xml_string);

my $json_string = XML::GenericJSON::file2string($xml_filename);

XML::GenericJSON::string2file($xml_string,$json_filename);

XML::GenericJSON::file2file($xml_filename,$json_filename);

=head1 DESCRIPTION

XML::GenericJSON provides functions for turning XML into JSON. It uses LibXML to parse
the XML and JSON::XS to turn a perlish data structure into JSON. The perlish data structure
preserves as much XML information as possible. (In other words, an application-specific JSON filter
would almost certainly produce more compact JSON.)

The module was initially developed as part of the Xcruciate project (F<http://www.xcruciate.co.uk>)
to produce JSON output via the Xteriorize webserver. It turns the entire XML document into a DOM tree,
which may not be what you want to do if your XML document is 3 buzillion lines long.

=head1 AUTHOR

Mark Howe, E<lt>melonman@cpan.orgE<gt>

=head2 EXPORT

None

=head1 BUGS

The best way to report bugs is via the Xcruciate bugzilla site (F<http://www.xcruciate.co.uk/bugzilla>).

=head1 PREVIOUS VERSIONS

=cut

my @types=(0,
           'element', #1
           'attribute', #2
           'text', #3
           'cdata', #4
           'entity_ref', #5
           'entity_node', #6
           'pi', #7
           'comment', #8
           'document', #9
           'document_type', #10
           'document_frag', #11
           'notation', #12
           'html_document', #13
           'dtd', #14
           'element_decl', #15
           'attribute_decl', #16
           'entity_decl', #17
           'namespace_decl', #18
           'xinclude_start', #19
           'xinclude_end', #20
           'docb_document' #21
    );

my $simple_types = {4=>1,
		    7=>1,
		    8=>1};

my $xml_parser = new XML::LibXML;

=head2 string2string(xml_string [,preserve_whitespace])

Returns a JSON representation of an XML string. The second argument should be false if you want to preserve non-semantic whitespace.

=cut

sub string2string {
    my $xml_string = shift;
    my $strip_whitespace = 1;
    $strip_whitespace = shift if defined $_[0];
    my $dom = $xml_parser->parse_string($xml_string);
    return (encode_json dom2perlish($dom->getDocumentElement,$strip_whitespace));
}

=head2 file2string(xml_filename [,preserve_whitespace])

Returns a JSON representation of an XML file. The second argument should be false if you want to preserve non-semantic whitespace.

=cut

sub file2string {
    my $xml_filename = shift;
    my $strip_whitespace = 1;
    $strip_whitespace = shift if defined $_[0];
    my $dom = $xml_parser->parse_file($xml_filename);
    return (encode_json dom2perlish($dom->getDocumentElement,$strip_whitespace));
}

=head2 string2file(xml_string, json_filename [,preserve_whitespace])

Writes a JSON file based on an XML string. The third argument should be false if you want to preserve non-semantic whitespace.

=cut

sub string2file {
    my $xml_string = shift;
    my $json_filename = shift;
    my $strip_whitespace = 1;
    $strip_whitespace = shift if defined $_[0];
    my $dom = $xml_parser->parse_string($xml_string);
    my $json = (encode_json dom2perlish($dom->getDocumentElement,$strip_whitespace));
    open(OUT,">$json_filename") or die "Could not write JSON to '$json_filename' :$!";
    print OUT $json;
    close OUT;
}

=head2 file2file(xml_filename, json_filename [,preserve_whitespace])

Writes a JSON file based on an XML file. The third argument should be false if you want to preserve non-semantic whitespace.

=cut

sub file2file {
    my $xml_filename = shift;
    my $json_filename = shift;
    my $strip_whitespace = 1;
    $strip_whitespace = shift if defined $_[0];
    my $dom = $xml_parser->parse_file($xml_filename);
    my $json = (encode_json dom2perlish($dom->getDocumentElement,$strip_whitespace));
    open(OUT,">$json_filename") or die "Could not write JSON to '$json_filename' :$!";
    print OUT $json;
    close OUT;
}

=head2 dom2perlish(node)

The function that does the work of turning XML into a perlish data structure suitable for treatment by JSON::XS.

=cut

sub dom2perlish {
    my $xml_node = shift;
    my $strip_whitespace = 1;
    $strip_whitespace = shift if defined $_[0];
    my $perlish_node = {};
    if ($xml_node->nodeType == 3) {#text - just store the scalar
	return $xml_node->data;
    }elsif (defined $simple_types->{$xml_node->nodeType}) {#cdata,pi,comment - store type plus data
	$perlish_node->{type} = $types[$xml_node->nodeType];
	$perlish_node->{data} = $xml_node->nodeValue;
	return $perlish_node;
    } else {#Probably an element, but it should work regardless
	$perlish_node->{type} = $types[$xml_node->nodeType];
	$perlish_node->{namespaces} = list_namespaces($xml_node) if $xml_node->getNamespaces;
	$perlish_node->{prefix} = $xml_node->prefix if $xml_node->prefix;
	$perlish_node->{name} = $xml_node->localname;
	$perlish_node->{attributes} = hash_attributes($xml_node) if $xml_node->hasAttributes;
	$perlish_node->{children} = list_children($xml_node,$strip_whitespace) if $xml_node->hasChildNodes;
	return $perlish_node
    }
}

=head2 hash_attributes(node)

Makes a hash of attributes.

=cut

sub hash_attributes {
    my $xml_node = shift;
    my $hash = {};
    foreach ($xml_node->attributes) {
	$hash->{$_->name}=$_->value}
    return $hash;
}

=head2 list_namespaces($node)

Makes a list of namespaces.

=cut

sub list_namespaces {
    my $xml_node = shift;
    my @namespaces_list = ();
    foreach ($xml_node->namespaces) {
	my $namespace_hash={};
	$namespace_hash->{prefix} = $_->getLocalName;
	$namespace_hash->{uri} = $_->getData;
	push @namespaces_list,$namespace_hash;
    }
    return [@namespaces_list];
}

=head2 list_children(node)

Makes a list of child nodes.

=cut

sub list_children {
    my $xml_node = shift;
    my $strip_whitespace = shift;
    my @children = ();
    foreach ($xml_node->childNodes) {
	next if $strip_whitespace and ($_->nodeType == 3) and ($_->textContent=~/^\s*$/s);
	push @children,dom2perlish($_,$strip_whitespace);
    }
    return [@children];
}

=head1 PREVIOUS VERSIONS

=over

B<0.01>: First upload

B<0.02>: Get dependencies right

B<0.03>: Get path to abstract right

B<0.04>: ported to use Module::Build

B<0.05>: fixed unit test

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by SARL Cyberporte/Menteith Consulting

This library is distributed under BSD licence (F<http://www.xcruciate.co.uk/licence-code>).

=cut

1;

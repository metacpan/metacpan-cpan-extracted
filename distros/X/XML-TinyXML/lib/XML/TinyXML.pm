=head1 NAME

XML::TinyXML - Little and efficient Perl module to manage xml data. 

=head1 SYNOPSIS

  use XML::TinyXML;

  # First create an XML Context
  $xml = XML::TinyXML->new();
    
  # and add a root node
  $xml->addRootNode('nodelabel', 'somevalue', { attr1 => v1, attr2 => v2 });

  # if you want to reuse a previously created node object ...
  #
  # ( you can create one calling :
  #    * %attrs = ( attr1 => v1, attr2 => v2 );
  #    * $node = XML::TinyXML::Node->new('nodelabel', param => 'somevalue', attrs => \%attrs);
  # )
  #
  # the new XML Context can be created giving the root node directly to the constructor
  $xml = XML::TinyXML->new($node);

  ######
  
  # A better (and easier) option is also to let the context constructor create the rootnode for you:
  $xml = XML::TinyXML->new('rootnode', param => 'somevalue', attrs => { attr1 => v1, attr2 => v2 });

  # an empty root node can be created as well:
  $xml = XML::TinyXML->new('rootnode');

  # You can later obtain a reference to the node object using the getNode() method
  $node = $xml->getNode('/rootnode'); 

  # the leading '/' is optional ... since all paths will be considered absolute and 
  # first element is assumed to be always a root node
  $node = $xml->getNode('rootnode');

  # xpath-like predicates are also supported so you can also do something like
  $node->addChildNode('child', 'value1');
  $node->addChildNode('child', 'value2');
  $child2 = $xml->getNode('/rootnode/child[2]');

  # or even 
  $node->addChildNode('child', 'value3', { attr => 'val' });
  # the 3rd 'child' has an attribute
  $child3 = $xml->getNode('/rootnode/child[@attr="val"]');

  #### IMPORTANT NOTE: #### 
  # this is not xpath syntax. use XML::TinyXML::Selector::XPath 
  # if you want to use an xpath-compliant syntax

  # see XML::TinyXML::Node documentation for further details on possible
  # operations on a node reference

  ########                                            #########
  ########## hashref2xml and xml2hashref facilities ###########
  ########                                            #########
  
  # An useful facility is loading/dumping of hashrefs from/to xml
  # for ex:
  $hashref = { some => 'thing', someother => 'thing' };
  my $xml = XML::TinyXML->new($hashref, param => 'mystruct');

  # or to load on an existing XML::TinyXML object
  $xml->loadHash($hashref, 'mystruct');

  # we can also create and dump to string all at once :
  my $xmlstring = XML::TinyXML->new($hashref, param => 'mystruct')->dump;

  # to reload the hashref back
  my $hashref = $xml->toHash;

=head1 DESCRIPTION

Since in some environments it could be desirable to avoid installing 
Expat, XmlParser and blahblahblah, needed by most XML-related perl modules,
my main scope was to obtain a fast xml library usable from perl
(so with the possibility to expose a powerful api) but without the need to install 
a lot of other modules (or even C libraries) to have it working.

The actual version of XML::TinyXML (0.18 when I'm writing this) 
implements an xpath selector and supports encodings (through iconv).

The OO Tree-based api allows to :

    - create a new document programmaticaly
    - import an existing document from a file
    - import an existing document by parsing a memory buffer
    - modify the loaded/created document programmatically
    - export the document to an xml file
    - bidirectional conversion between xml documents and perl hashrefs

There are other "no-dependencies" tiny xml implementations on CPAN.
Notably : XML::Easy and XML::Tiny but both are still missing some key
features which are actually implemented in this module and are required 
by the projects where I use it, in particular :

    - an OO api to allow changing and re-exporting the xml document,
    - an easy-to-use bidirectional xml<->hashref conversion 
    - encoding-conversion capabilities
    - xpath selectors
    - small memory footprint (well... it's always a perl module)

The underlying xml implementation resides in txml.c and is imported in the perl
context through XS. It uses a linkedlist implementation took out of freebsd kernel
and is supposed to be fast enough to represent and access 'not-huge' xml trees.
If at some stage there will be need for more preformance in accessing the xml data
(especially when using the xpath selector) an hash-table based index could be built
on top of the tree structure to speed-up access to inner parts of the tree when using
paths.

An Event-based api is actually missing, but will be provided in future releases.

=head1 METHODS

=over

=cut

package XML::TinyXML;

use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

use XML::TinyXML::Node;
our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use XML::TinyXML ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	XML_BADARGS
	XML_GENERIC_ERR
	XML_LINKLIST_ERR
	XML_MEMORY_ERR
	XML_NOERR
	XML_OPEN_FILE_ERR
	XML_PARSER_GENERIC_ERR
        XML_MROOT_ERR
        XML_NODETYPE_SIMPLE
        XML_NODETYPE_COMMENT
        XML_NODETYPE_CDATA
        XML_BAD_CHARS
        XML_UPDATE_ERR
	XXmlAddAttribute
	XmlAddChildNode
	XmlAddRootNode
	XmlCountAttributes
	XmlCountBranches
	XmlCountChildren
	XmlCreateContext
	XmlDestroyContext
        XmlResetContext
	XmlCreateNode
	XmlDestroyNode
	XmlDump
	XmlDumpBranch
	XmlGetBranch
	XmlGetChildNode
	XmlGetChildNodeByName
	XmlGetNode
	XmlGetNodeValue
        XmlNextSibling
	XmlParseBuffer
	XmlParseFile
        XmlPrevSibling
	XmlRemoveBranch
        XmlRemoveChildNode
        XmlRemoveChildNodeAtIndex
	XmlRemoveNode
	XmlSave
	XmlSetNodeValue
        XmlSetOutputEncoding
	XmlSubstBranch
        XmlCreateNamespace
        XmlDestroyNamespace
        XmlGetNamespaceByName
        XmlGetNamespaceByUri
        XmlAddNamespace
        XmlGetNodeNamespace
        XmlSetNodeNamespace
        XmlSetNodeCNamespace
        XmlSetCurrentNamespace
);

our $VERSION = '0.34';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&XML::TinyXML::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('XML::TinyXML', $VERSION);

# Preloaded methods go here.

=item * new ($arg, %params)

Creates a new XML::TinyXML object.

$root can be any of :

    XML::TinyXML::Node
    XmlNodePtr
    HASHREF
    SCALAR

and if present will be used as first root node of the newly created
xml document.

%params is an optional hash parameter used only
if $arg is an HASHREF or a scalar

    %params = (
        param =>  * if $root is an hashref, this will be
                      name of the root node (it will be passed 
                      as second argument to loadHash())
                  * if $root is a scalar, this will be 
                      the value of the root node.
        attrs =>  attributes of the 'contextually added' $root node 
        encoding => output encoding to use (among iconv supported ones)
    );

=cut

sub new {
    my ($class, $root, %params ) = @_;
    my $self = {} ;
    bless($self, $class);

    # default encoding (the same used as default in the C library
    $self->{_encoding} = "utf-8"; 
    $self->{_ctx} = XmlCreateContext();
    $self->setOutputEncoding($params{encoding}) if ($params{encoding});
    $self->allowMultipleRootNodes($params{multipleRootNodes}) if ($params{multipleRootNodes});
    $self->ignoreBlanks($params{ignoreBlanks}) if (defined($params{ignoreBlanks}));
    $self->ignoreWhiteSpaces($params{ignoreWhiteSpaces}) if (defined($params{ignoreWhiteSpaces}));
    if($root) {
        if(UNIVERSAL::isa($root, "XML::TinyXML::Node")) {
            XmlAddRootNode($self->{_ctx}, $root->{_node});
        } elsif(UNIVERSAL::isa($root, "XmlNodePtr")) {
            XmlAddRootNode($self->{_ctx}, $root);
        } elsif(ref($root) eq "HASH") {
            $self->loadHash($root, $params{param});
        } elsif(defined($root) && (!ref($root) || ref($root) eq "SCALAR")) {
            $self->addRootNode($root, $params{param}, $params{attrs});
        }
    }
    
    return $self;
}

sub open {
    my ($class, $file) = @_;
    my $self = $class->new();
    return $self->loadFile($file) == $self->XML_NOERR
           ? $self
           : undef;
}

=item * addNodeAttribute ($node, $key, $value)

Adds an attribute to a specific $node

$node MUST be an XML::TinyXML::Node object.

$key is the name of the attribute
$value is the value of the attribute

This method is just an accessor. See XML::TinyXML::Node::addAttributes() instead.

=cut

sub addNodeAttribute {
    my ($self, $node, $key, $value) = @_;
    return undef unless($node && UNIVERSAL::isa("XML::TinyXML::Node", $node));
    return $node->addAttributes($key => $value);
}

=item * removeNodeAttribute ($node, $index)

Removes from $node the attribute at $index if present.

$node MUST be a XML::TinyXML::Node object.

This method is just an accessor. See XML::TinyXML::Node::removeAttribute() instead.

=cut

sub removeNodeAttribute {
    my ($self, $node, $index) = @_;
    return undef unless($node && UNIVERSAL::isa("XML::TinyXML::Node", $node));
    return $node->removeAttribute($index);
}

=item * addRootNode ($name, $val, $attrs)

Adds a new root node. 
(This can be considered both as a new tree in the forest represented in the xml document
or as a new branch in the xml tree represented by the document itself)

=cut

sub addRootNode {
    my ($self, $name, $val, $attrs) = @_;

    $val = ""
        unless(defined($val));

    return $self->XML_BADARGS 
        if($attrs && ref($attrs) ne "HASH");

    my $node = XML::TinyXML::Node->new($name, $val, $attrs);

    return $self->XML_GENERIC_ERR
        unless($node);

    return XmlAddRootNode($self->{_ctx}, $node->{_node});
}

=item * addChildNode ($parent, $name, $val, $attrs)

Adds a new child node. 
This method is exactly like addRootNode but first argument must be a valid XML::TinyXML::Node
which will be the parent of the newly created node

=cut

sub addChildNode {
    my ($self, $node, $name, $val, $attrs) = @_;

    return $self->XML_BADARGS
        unless (ref($node) && UNIVERSAL::isa("XML::TinyXML::Node", $node)); 

    return $self->XML_BADARGS 
        if($attrs && ref($attrs) ne "HASH");

    $val = ""
        unless(defined($val));

    my $child = XML::TinyXML::Node->new($name, $val, $attrs, $node);

    return $self->XML_GENERIC_ERR
        unless($child);

    return XmlAddChildNode($self->{_ctx}, $node->{_node});
}

=item * dump ()

Returns a stringified version of the XML structure represented internally

=cut

sub dump {
    my $self = shift;
    return XmlDump($self->{_ctx});
}

=item * loadFile ($path)

Load the xml structure from a file

=cut

sub loadFile {
    my ($self, $path) = @_;
    return XmlParseFile($self->{_ctx}, $path);
}

=item * loadHash ($hash, $root)

Load the xml structure from an hashref (AKA: convert an hashref to an xml document)

if $root is specified, it will be the entity name of the root node
in the resulting xml document.

=cut

sub loadHash {
    my ($self, $hash, $root) = @_;
    $root = "txml"
        unless($root);

    my $cur = undef;
    if(ref($root) && UNIVERSAL::isa("XML::TinyXML::Node", $root)) {
        XmlAddRootNode($self->{_ctx}, $root->{_node});
        $cur = $root;
    } else {
        $self->addRootNode($root);
        $cur = $self->allowMultipleRootNodes
             ? $self->getNode($root)
             : $self->getRootNode(0);
    }
    return $cur->loadHash($hash);
}

=item * toHash ()

Dump the xml structure represented internally in the form of an hashref

=cut

sub toHash {
    my ($self) = shift;
    # only first branch will be parsed ... This means that if multiple root 
    # nodes are present (which is anyway not allowed by the xml spec), only 
    # the first one will be parsed and translated into an hashref
    my $node = $self->getRootNode(0);
    return $node->toHash;
}

=item * loadBuffer ($buf)

Load the xml structure from a preloaded memory buffer

=cut

sub loadBuffer {
    my ($self, $buf) = @_;
    return XmlParseBuffer($self->{_ctx}, $buf);
}

=item * getNode ($path)

Get a node at a specific path.

$path must be of the form: '/rootnode/child1/child2/leafnod'
and the leading '/' is optional (since all paths will be interpreted
as absolute)

Returns an XML::TinyXML::Node object

=cut

sub getNode {
    my ($self, $path) = @_;
    return XML::TinyXML::Node->new(XmlGetNode($self->{_ctx}, $path));
}

=item * getChildNode ($node, $index)

Get the child of $node at index $index.

Returns an XML::TinyXML::Node object

=cut

sub getChildNode {
    my ($self, $node, $index) = @_;
    return XML::TinyXML::Node->new(XmlGetChildNode($node, $index));
}

=item * countChildren ()

Returns the number of $node's children

=cut

sub countChildren {
    my ($self, $node) = @_;
    if(UNIVERSAL::isa($node, "XML::TinyXML::Node")) {
        return XmlCountChildren($node->{_node});
    } elsif(UNIVERSAL::isa($node, "XmlNodePtr")) {
        return XmlCountChildren($node);
    } else {
        # assume we have been provided a path
        my $node = XmlGetNode($self->{_ctx}, $node);
        return XmlCountChildren($node)
            if ($node);
    }
    return undef;
}

=item * removeNode ($path)

Remove the node at specific $path, if present.
See getNode() documentation for some notes on the $path format.

Returns XML_NOERR (0) if success, error code otherwise.

See Exportable constants for a list of possible error codes

=cut

sub removeNode {
    my ($self, $path) = @_;
    return XmlRemoveNode($self->{_ctx}, $path);
}

=item * getBranch ($index)

alias for getRootNode

=cut

sub getBranch {
    my ($self, $index) = @_;
    return XML::TinyXML::Node->new(XmlGetBranch($self->{_ctx}, $index));
}

=item * getRootNode ($index) 

Get the root node at $index.

Returns an XML::TinyXML::Node object if present, undef otherwise

=cut

sub getRootNode {
    my ($self, $index) = @_;
    return $self->getBranch($index);
}

=item * removeBranch ($index)

Alias for removeRootNode

=cut

sub removeBranch {
    my ($self, $index) = @_;
    return XmlRemoveBranch($self->{_ctx}, $index);
}

=item * removeRootNode ($index)

Remove the rootnode (and all his children) at $index.

=cut

sub removeRootNode {
    my ($self, $index) = @_;
    return $self->removeBranch($index);
}

=item * countRootNodes 

Returns the number of root nodes within this context

=cut

sub countRootNodes {
    my ($self) = @_;
    return XmlCountBranches($self->{_ctx});
}

=item * rootNodes ()

Returns an array containing all rootnodes. 
In scalar context returns an arrayref.

=cut

sub rootNodes {
    my ($self) = @_;
    my @nodes;
    for (my $i = 0; $i < XmlCountBranches($self->{_ctx}); $i++) {
        push (@nodes, XML::TinyXML::Node->new(XmlGetBranch($self->{_ctx}, $i)));
    }
    return wantarray?@nodes:\@nodes;
}

=item * getChildNodeByName ($node, $name)

Get the child of $node with name == $name.

Returns an XML::TinyXML::Node object if there is such a child, undef otherwise

=cut

sub getChildNodeByName {
    my ($self, $node, $name) = @_;
    if ($node) {
        return XML::TinyXML::Node->new(XmlGetChildNodeByName($node, $name));
    } else {
        my $count = XmlCountBranches($self->{_ctx});
        for (my $i = 0 ; $i < $count; $i++ ){
            my $res = XmlGetChildNodeByName(XmlGetBranch($self->{_ctx}, $i), $name);
            return XML::TinyXML::Node->new($res) if($res);

        }
    }
    return undef;
}

sub cNode {
    my ($self, $value) = @_;
    return $value
           ? $self->{_ctx}->cNode($value)
           : $self->{_ctx}->cNode;
}

=item * save ($path)

Save the xml document represented internally into $path.

Returns XML_NOERR if success, a specific error code otherwise

=cut

sub save {
    my ($self, $path) = @_;
    return XmlSave($self->{_ctx}, $path);
}

=item * setOutputEncoding ($encoding)

Sets the output encding to the specified one

(any iconv-supported encoding is a valid argument for this method)

Returns XML_NOERR if success, a specific error code otherwise

=cut

sub setOutputEncoding {
    my ($self, $encoding) = @_;
    $self->{_encoding} = $encoding;
    XmlSetOutputEncoding($self->{_ctx}, $encoding);
}

=item * allowMultipleRootNodes ($bool)

Allow to control if the document can contain multiple root nodes (out of xml spec)
or if it will support only one single root node. Default is 0

=cut

sub allowMultipleRootNodes {
    my ($self, $val) = @_;
    return defined($val)
           ? $self->{_ctx}->allowMultipleRootNodes($val)
           : $self->{_ctx}->allowMultipleRootNodes;
}

=item * ignoreBlanks ($bool)

Controls the behaviour of both the parser and the dumper.

- Parser :

If ignoreBlanks is true any 'tab', 'newline' and 'carriage-return' ("\t", "\n", "\r"),
between two tags will be ignored, unless surrounded by non-whitespace character.
For example, considering the following node:

    <parent>
            <child>value</child>
    </parent>

( literally : "<parent>\n\t<child>value</child>\n</parent>" )

the parser will ignore the newlines and the tab between two nodes.
So, the resulting structure would be :

    $node = {
              value => undef,
              children => [ { child => "value" } ]
            }

If ignoreBlanks is false, all characters between the node tags will be part of the 
value and the result would be : 

    $node = {
              value => "\n\t\n",
              children => [ { child => "value" } ]
            }

- Dumper :

If ignoreBlanks is true, both newlines and tabs will be used to prettify text formatting,
so the node in the previous example will be printed out as:

    <parent>
            <child>value</child>
    </parent>

If ignoreBlanks is false, no extra characters will be added to the xml data
(so no newlines, indentation or such). 
The previous example would be dumped as follows:

    <parent><child>value</child></parent>

Default is 1.

=cut

sub ignoreBlanks {
    my ($self, $val) = @_;
    return defined($val)
           ? $self->{_ctx}->ignoreBlanks($val)
           : $self->{_ctx}->ignoreBlanks;
}

=item * ignoreWhiteSpaces ($bool)

Controls the behaviour of the parser.

This flag includes the literal whitespace ' ' among the ignored characters 
commended by ignoreBlanks()

consider the following examples:

    <child> </child> 

 - if true:
     value = ""

 - if false:
     value = " "

The parser will ignore the whitespace if this flag is true.

    <child> a value </child>

    <child> a value</child>

    <child>a value </child>

 - if true:
     value = "a value"

 - if false:
     value = " a value "
             " a value"
             "a value "

The whitespace will be part of the value if this flag is false.

The dumper is not affected by this flag.

Default is 1

=cut

sub ignoreWhiteSpaces {
    my ($self, $val) = @_;
    return defined($val)
           ? $self->{_ctx}->ignoreWhiteSpaces($val)
           : $self->{_ctx}->ignoreWhiteSpaces;
}

sub hasIconv {
    my $self = shift;
    return $self->{_ctx}->hasIconv;
}

sub DESTROY {
    my $self = shift;
    XmlDestroyContext($self->{_ctx})
        if($self->{_ctx});
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=back

=head2 EXPORT

None by default.

=head2 Exportable constants

  XML_BADARGS
  XML_GENERIC_ERR
  XML_LINKLIST_ERR
  XML_MEMORY_ERR
  XML_NOERR
  XML_OPEN_FILE_ERR
  XML_PARSER_GENERIC_ERR
  XML_UPDATE_ERR
  XML_BAD_CHARS
  XML_MROOT_ERR
  XML_NODETYPE_SIMPLE
  XML_NODETYPE_COMMENT
  XML_NODETYPE_CDATA

=head2 Exportable C functions

  TXml *XmlCreateContext()
  void XmlDestroyContext(TXml *xml)
  XmlNode *XmlCreateNode(char *name,char *val,XmlNode *parent);
  char *XmlGetNodeValue(XmlNode *node);
  XmlErr XmlSetNodeValue(XmlNode *node,char *val);
  void XmlDestroyNode(XmlNode *node);
  int XmlAddAttribute(XmlNode *node, char *name, char *val)
  int XmlAddRootNode(TXml *xml, XmlNode *node)
  int XmlRemoveNode(TXml *xml,char *path);
  void XmlRemoveChildNodeAtIndex(XmlNode *node, unsigned long index);
  void XmlRemoveChildNode(XmlNode *parent, XmlNode *child);
  XmlErr XmlAddChildNode(XmlNode *parent,XmlNode *child);
  XmlNode *XmlGetChildNode(XmlNode *node, unsigned long index)
  XmlNode *XmlGetChildNodeByName(XmlNode *node,char *name);
  XmlNode *XmlGetNode(TXml *xml,  char *path)
  unsigned long XmlCountBranches(TXml *xml)
  int XmlRemoveBranch(TXml *xml, unsigned long index)
  XmlNode *XmlGetBranch(TXml *xml,unsigned long index);
  int XmlSubstBranch(TXml *xml,unsigned long index, XmlNode *newBranch);
  int XmlParseBuffer(TXml *xml, char *buf)
  int XmlSave(TXml *xml, char *path)
  char *XmlDump(TXml *xml, int *outlen)

=head1 SEE ALSO

  XML::TinyXML::Node

You should also see libtinyxml documentation (mostly txml.h, redistributed with this module)

If you need a more complete and featureful XML implementation try looking at 
XML::LibXML XML::Parser XML::API XML::XPath or other modules based on either expat or libxml2

=head1 AUTHOR

xant, E<lt>xant@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by xant

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

package XML::SimpleObject::LibXML;

use strict;
use XML::LibXML 1.53;
use XML::LibXML::Common;

our $VERSION = '0.60';

sub attributes {
    my $self = shift;
    my $name = shift;
    my %attributes;
    my @attrs = $self->{_DOM}->getAttributes;
    foreach my $attribute (@attrs) {
        $attributes{$attribute->getName} = $attribute->value;
    }
    return %attributes;
}

sub attribute {
    my $self = shift;
    my $name = shift;
    my $newvalue = shift;
    if ($self->hasNamespaces()) {
      my ($namespaceURI, $localName) = $self->_parseTagName($name, ATTRIBUTE_NODE);

      if (defined($namespaceURI)) { # Attribute has an explicit namespace
         my ($found) = $self->{_DOM}->getAttributeNodeNS($namespaceURI, $localName);
         if ($found) { 
           if ($newvalue) {
             $found->setValue($newvalue);
           } else {
             return $found->value; 
           }
         }
      } else {                      # Attribute has no namespace
            my ($found) = $self->{_DOM}->getAttributeNode($name);
            if ($found) {
              if ($newvalue) {
                $found->setValue($newvalue);
              } else {
                return $found->value; 
              }
            }
      }

    } else {
      my ($found) = $self->{_DOM}->findnodes("\@$name");
      if ($found) { 
        if ($newvalue) {
          $found->setValue($newvalue);
        } else {
          return $found->value;  
        }
      }
    }
}

sub add_attribute {
    my $self = shift;
    $self->{_DOM}->setAttribute( $_[0], $_[1] );
    return $self;
}

sub value {
    my $node = shift;
    my $newvalue = shift;
    my ($found) = $node->{_DOM}->findnodes("text()");
    if ($found) {
        if (defined $newvalue) {
          return $found->setData($newvalue);
        } else {
          return $found->getData();
        }
    }
}

sub name {
    my $node = shift;
    my $newname = shift;
    if ($newname) {
      $node->{_DOM}->setNodeName($newname);
    } else {
      $node->{_DOM}->getName;
    }
}

sub type {
  $_[0]->{_DOM}->nodeType;
}

sub xpath_search {
  my $self = shift;
  my $xpath = shift;
  my @nodes;
  foreach my $node ($self->{_DOM}->findnodes($xpath)) {
    my $newobj = new XML::SimpleObject::LibXML ($node);
    return $newobj unless wantarray;
    push @nodes, $newobj;
  }
  return @nodes;
}

sub namespaceURI() {
  $_[0]->{_DOM}->getNamespaceURI();
}

sub namespace() {
  my $node = shift;
  my $namespaceURI = $node->namespaceURI();

  return unless (defined $namespaceURI);

  my (@found) = $node->{_DOM}->findnodes("namespace::*"); for (@found) { 
    return $_->getLocalName() if $namespaceURI eq $_->getData(); 
  }
}

sub hasNamespaces() {
  return $_[0]->{_NAMESPACES};
}

sub _parseTagName($$) {
    my ($self, $tag, $type) = @_;

    my ($namespaceURI, $localName);

    if ($tag =~ /^([^:]+):(.*)/) {
        # Tag has an explicit namespace
        $namespaceURI = $self->{_NAMESPACES}->{$1};
        $localName = $2;
        die("Unknown namespace $1") unless ($namespaceURI);
    } 
    else {
        $localName = $tag;
        # Tag has no explicit namespace.
        if ($type eq ELEMENT_NODE) {
            # Elements live in the default namespace.  
            # Go with the default namespace.  If one was specified, it will be ''.
            $namespaceURI = $self->{_NAMESPACES}->{''};
        } 
        elsif ($type eq ATTRIBUTE_NODE) {
            # The default namespace does not apply to attribute names.
            # (See http://www.w3.org/TR/1998/PR-xml-names-19981117, section 5.3)
        } 
        else {
            # Nothing else has tagnames.
            die("Unexpected type $type");
        }
    }

    return ($namespaceURI, $localName);
}

sub child {
    my $self = shift;
    my $tag  = shift;
    if (ref $self->{_DOM} eq "XML::LibXML::Document") {
        my $node = new XML::SimpleObject::LibXML ($self->{_DOM}->documentElement());
        return $node;
    }
    elsif ($self->hasNamespaces()) {
        my ($namespaceURI, $localName) = $self->_parseTagName($tag, ELEMENT_NODE);
        my ($element) = $self->{_DOM}->getElementsByTagNameNS($namespaceURI, $localName);
        return unless ($element);
        my $node = new XML::SimpleObject::LibXML ($element);
        return $node;
    }
    else
    {
        my ($element) = $self->{_DOM}->getElementsByTagName($tag);
        return unless ($element);
        my $node = new XML::SimpleObject::LibXML ($element);
        return $node;
    }
}

sub add_child {
    my $self = shift;
    my $element = $self->{_DOM}->addNewChild( undef, $_[0]);
    if ($_[1]) {
       $element->appendTextNode($_[1]);
    }
    my $node = new XML::SimpleObject::LibXML ($element);
    return $node;
}

sub delete {
    my $self = shift;
    $self->{_DOM}->unbindNode;
}

sub children_names {
    my $self = shift;
    my @elements;
    foreach my $node ($self->{_DOM}->getChildnodes)
    {
        next if ($node->nodeType == 3);
        push @elements, $node->getName;
    }
    return @elements;
}

sub children {
    my $self = shift;
    my $tag  = shift;
    if (ref $self->{_DOM} eq "XML::LibXML::Document") {
        my $node = new XML::SimpleObject::LibXML ($self->{_DOM}->documentElement());
        return $node;
    }
    elsif (defined($tag)) { # tag: return matching children
        if ($self->hasNamespaces()) {
            my ($namespaceURI, $localName) = $self->_parseTagName($tag, ELEMENT_NODE);
            my @nodelist;
            foreach my $node ($self->{_DOM}->getElementsByTagNameNS($namespaceURI, $localName)) {
                next if ($node->nodeType == TEXT_NODE);
                push @nodelist, new XML::SimpleObject::LibXML ($node);
            }
            return @nodelist;
        } 
        else {
            my @nodelist;
            foreach my $node ($self->{_DOM}->getElementsByTagName($tag)) {
                next if ($node->nodeType == TEXT_NODE);
                push @nodelist, new XML::SimpleObject::LibXML ($node);
            }
            return @nodelist;
        }
    }
    else # no tag: return all children
    {
        my @nodelist;
        foreach my $node ($self->{_DOM}->getChildnodes()) {
            next if ($node->nodeType == 3);
            push @nodelist, new XML::SimpleObject::LibXML ($node);
        }
        return @nodelist;
    }
}

sub output_xml {
    my $self = shift;
    my %args = @_;
    return $self->{_DOM}->toString($args{indent},$args{original_encoding});
}

sub output_xml_file {
    my $self = shift;
    my %args = @_;
    open FILE, ">" . $args{file} or die $!;
    print FILE $self->output_xml(%args);
    close FILE;
}

sub replace_names_values {
  my $self = shift;
  my %args = @_;
  foreach my $node ($self->{_DOM}->findnodes($args{xpath})) {
    $args{name} && do { $node->setNodeName($args{name}) };
    my $nodetype = $node->nodeType;
    if ($nodetype == 1) {      # Element, try text node
      $args{value} && do {
        my ($found) = $node->findnodes("text()");
        $found->setData($args{value});
      };
    } elsif ($nodetype == 2) { # Attribute
      $args{value} && do { $node->setValue($args{value}) };
    } elsif ($nodetype == 3) { # Text
      $node->setData($args{value});
    }
  }
}

sub delete_nodes {
  my $self = shift;
  my %args = @_;
  foreach my $node ($self->{_DOM}->findnodes($args{xpath})) {
    $node->unbindNode();
  }
}

sub _build_namespace_map() {
    my $self = shift;
    return if $self->{_NAMESPACES};

    my %map = map { my $key = $_->getLocalName(); $key = '' unless defined $key; $key  => $_->getData() } $self->{_DOM}->findnodes("namespace::*");
    $self->{_NAMESPACES} = \%map if (scalar(%map));
}

sub _init() {
    my $self = shift;
    $self->_build_namespace_map();
}

sub new {
    my $class = shift;
    if (ref($_[0]) =~ /^XML\:\:LibXML/) {
        my $self = {};
        bless ($self,$class);
        $self->{_DOM}  = $_[0];
        $self->_init();
        return $self;
    } else {
        my %args   = @_;
        my $parser = new XML::LibXML;
        my $dom;
        if ($args{XML}) {
          $dom  = $parser->parse_string($args{XML});
        } elsif ($args{file}) {
          $dom = $parser->parse_file($args{file});
        } else {
          die "new() not called with DOM, XML string, or filename"; 
        } 
        my $self   = {};
        bless ($self,$class);
        $self->{_NAME} = "";
        $self->{_DOM}  = $dom;
        $self->_init();
        return $self;
    }
}


1;
__END__

=head1 NAME

XML::SimpleObject::LibXML - Perl extension allowing a simple(r) object representation of an XML::LibXML DOM object.

=head1 SYNOPSIS

  use XML::SimpleObject::LibXML;

  # Construct with the key/value pairs as argument; this will create its 
  # own XML::LibXML object.
  my $xmlobj = new XML::SimpleObject::LibXML(XML => $XML);
  my $xmlobj = new XML::SimpleObject::LibXML(file => "./listing.xml");
  my $xmlobj = new XML::SimpleObject::LibXML(); # empty DOM

  # ... or construct with the parsed tree as the only argument, having to 
  # create the XML::LibXML object separately.
  my $parser = new XML::LibXML;
  my $dom = $parser->parse_file($file);
  my $xmlobj = new XML::SimpleObject::LibXML ($dom);

  my $filesobj = $xmlobj->child("files")->child("file");

  # read values
  $filesobj->name;
  $filesobj->value;
  $filesobj->attribute("type");

  %attributes    = $filesobj->attributes;
  @children      = $filesobj->children;
  @some_children = $filesobj->children("some");
  @children_names = $filesobj->children_names;

  # set values
  $filesobj->name("Files");               # set name
  $filesobj->value("test");               # set text value
  $filesobj->attribute("type", "bin"); # set existing attribute's value

  # add/delete nodes
  $filesobj->add_child
          ("owner" => "me"); # add new element
  $filesobj->add_attribute
          ("size" => "4");   # add new attribute 
  $filesobj->delete;         # unbinds node from parent

  # document processing
  $xmlobj->replace_names_values(xpath => "/files/file[0]/title", 
        value => "places.txt", name => "newtitle");
  $xmlobj->delete_nodes(xpath => "/files/file/size");

  # output 
  $xmlobj->output_xml;
  $xmlobj->output_xml_file("./newfile.xml");

=head1 DESCRIPTION

This is a short and simple class allowing simple object access to a parsed XML::LibXML tree, with methods for fetching children and attributes in as clean a manner as possible. My apologies for further polluting the XML:: space; this is a small and quick module, with easy and compact usage. Some will rightfully question placing another interface over the DOM methods provided by XML::LibXML, but my experience is that people appreciate the total simplicity provided by this module, despite its limitations. These limitations include a minor loss of speed compared to the DOM, loss of control over node types, and protection (aka lack of knowledge) about the DOM. I encourage those who want more control and understanding over the DOM to study XML::LibXML; this module's source can be instructive, too.

=head1 USAGE

B<Read Processing>

   $xmlobj = new XML::SimpleObject::LibXML($parser->parse_string($XML)) 
   # $parser is an XML::LibXML object

   $xmlobj = new XML::SimpleObject::LibXML(XML => '<xml/>')

   $xmlobj = new XML::SimpleObject::LibXML(file => '/path/to/file.xml')

After creating $xmlobj, this object can now be used to browse the XML tree with the following methods. Every returned node is also an object of this type, and may be processed identically. This allows you to chain together object method calls.

   $xmlobj->child('NAME')

This will return a new XML::SimpleObject::LibXML object using the child element NAME.

   $xmlobj->children('NAME')

Called with an argument NAME, children() will return an array of XML::SimpleObject::LibXML objects of element NAME. Thus, if $xmlobj represents the top-level XML element, 'children' will return an array of all elements directly below the top-level that have the element name NAME.

   $xmlobj->children

Called without arguments, 'children()' will return an array of XML::SimpleObjects::LibXML objects for all children elements of $xmlobj. Unlike XML::SimpleObject, XML::SimpleObject::LibXML retains the order of these children.

   $xmlobj->children_names

This will return an array of all the names of child elements for $xmlobj. You can use this to step through all the children of a given element (see EXAMPLES), although multiple elements of the same name will not be identified. Use 'children()' instead.

   $xmlobj->name([NEWNAME])

Returns the string name for the element. Adding an argument will change that name to the argument.

   $xmlobj->value([NEWVALUE])

If the element represented by $xmlobj contains any PCDATA, this method will return that text data. Adding an argument will change the value to the provided string.

   $xmlobj->attribute('NAME',[VALUE])

This returns the text for an attribute NAME of the XML element represented by $xmlobj. Adding a second argument will change the value of the attribute to the supplied string.

   $xmlobj->attributes

This returns a hash of key/value pairs for all elements in element $xmlobj.

   $xmlobj->xpath_search('XPATH')

This searches for nodes matching XPATH and returns objects for each match. (See XML::LibXML POD on findnodes()). In scalar context it will return only the first match, even if there are more.

B<Write Processing>

   $xmlobj->add_child(NAME => VALUE)

Adds a child to the current node with name NAME, value VALUE. This node may be subsequently fetched with child(NAME) or xpath_search, and in turn appended to or manipulated. If no VALUE is supplied, an empty node will be added.

   $xmlobj->add_attribute(NAME => VALUE)

Adds an attribute to the current node, name NAME, value VALUE.

   $xmlobj->delete

Deletes node.

B<Enhanced Document Processing>

   $xmlobj->replace_names_values(xpath => 'XPATH', name => 'NEW_NAME', 
       value => 'NEW_VALUE')

Replaces all context names and/or values matching XPATH with NEW_VALUE. This can be used for both elements and attributes. It will not operate on document, comment, processing instruction, and other node types. You can replace only names, only values, or both names and values.

   $xmlobj->delete_nodes('XPATH')

Deletes all context nodes matching XPATH.

B<Output>

   $xmlobj->output_xml(indent=>1, original_encoding=>1)

This outputs the XML as an XML string. The arguments are optional; 'indent' will define the indentation for the document output (by default the same as the input doc), 'original_encoding' will force output in the encoding of the original document, rather than utf8.

   $xmlobj->output_xml_file(file=>FILEPATH, indent=>1, 
         original_encoding=>1)

This writes the XML output to the provided file path. The other arguments function like output_xml().

=head1 EXAMPLES

Given this XML document:

  <files>
    <file type="symlink">
      <name>/etc/dosemu.conf</name>
      <dest>dosemu.conf-drdos703.eval</dest>
    </file>
    <file>
      <name>/etc/passwd</name>
      <bytes>948</bytes>
    </file>
  </files>

You can then interpret the tree as follows:

  my $parser = new XML::LibXML;
  my $xmlobj = new XML::SimpleObject::LibXML 
        ($parser->parse_string($XML));

  print "Files: \n";
  foreach my $element ($xmlobj->child("files")->children("file"))
  {
    print "  filename: " . $element->child("name")->value . "\n";
    if ($element->attribute("type"))
    {
      print "    type: " . $element->attribute("type") . "\n";
    }
    print "    bytes: " . $element->child("bytes")->value . "\n";
  }  

This will output:

  Files:
    filename: /etc/dosemu.conf
      type: symlink
      bytes: 20
    filename: /etc/passwd
      bytes: 948

You can use 'children()' without arguments to step through all children of a given element:

  my $filesobj = $xmlobj->child("files")->child("file");
  foreach my $child ($filesobj->children) {
    print "child: ", $child->name, ": ", $child->value, "\n";
  }

For the tree above, this will output:

  child: bytes: 20
  child: dest: dosemu.conf-drdos703.eval
  child: name: /etc/dosemu.conf

Using 'children_names()', you can step through all children for a given element:

  my $filesobj = $xmlobj->child("files");
  foreach my $childname ($filesobj->children_names) {
      print "$childname has children: ";
      print join (", ", $filesobj->child($childname)
            ->children_names), "\n";
  }

This will print:

    file has children: bytes, dest, name

By always using 'children()', you can step through each child object, retrieving them with 'child()'.

To jump straight to the value for the first filename in this XML tree, use xpath_search():

  print $xmlobj->xpath_search("/files/file/name[0]")->value;

You can also use an xpath_search() in array context to process a return list.

=head1 AUTHOR

Dan Brian <dan@brians.org>

=head1 SEE ALSO

perl(1), XML::LibXML.

=cut


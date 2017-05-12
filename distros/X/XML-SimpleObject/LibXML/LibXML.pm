package XML::SimpleObject::LibXML;

use strict;
use XML::LibXML;

our $VERSION = '0.53';

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
    my ($found) = $self->{_DOM}->findnodes("\@$name");
    if ($found) { return $found->value; }
}

sub value {
    my $node = shift;
    my ($found) = $node->{_DOM}->findnodes("text()");
    if ($found) {
        return $found->getData();
    }
}

sub name {
    $_[0]->{_DOM}->getName;
}

sub child {
    my $self = shift;
    my $tag  = shift;
    if (ref $self->{_DOM} eq "XML::LibXML::Document") {
        my $node = new XML::SimpleObject::LibXML ($self->{_DOM}->documentElement());
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
    else 
    {
        if ($tag) {
            my @nodelist;
            foreach my $node ($self->{_DOM}->getElementsByTagName($tag)) {
                next if ($node->nodeType == 3);
                push @nodelist, new XML::SimpleObject::LibXML ($node);
            }
            return @nodelist;
        } else {
            my @nodelist;
            foreach my $node ($self->{_DOM}->getChildnodes()) {
                next if ($node->nodeType == 3);
                push @nodelist, new XML::SimpleObject::LibXML ($node);
            }
            return @nodelist;
        }
    }
}

sub new {
    my $class = shift;
    if (ref($_[0]) =~ /^XML\:\:LibXML/) {
        my $self = {};
        bless ($self,$class);
        $self->{_DOM}  = $_[0];
        return $self;
    } else {
        my %args   = @_;
        my $parser = new XML::LibXML;
        my $dom    = $parser->parse_string($args{XML});
        my $self   = {};
        bless ($self,$class);
        $self->{_NAME} = "";
        $self->{_DOM}  = $dom;
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
  my $xmlobj = new XML::SimpleObject(XML => $XML);

  # ... or construct with the parsed tree as the only argument, having to 
  # create the XML::Parser object separately.
  my $parser = new XML::LibXML;
  my $dom    = $parser->parse_file($file); # or $parser->parse_string($xml);
  my $xmlobj = new XML::SimpleObject::LibXML ($dom);

  my $filesobj = $xmlobj->child("files")->child("file");

  $filesobj->name;
  $filesobj->value;
  $filesobj->attribute("type");
  
  %attributes    = $filesobj->attributes;
  @children      = $filesobj->children;
  @some_children = $filesobj->children("some");
  @children_names = $filesobj->children_names;

=head1 DESCRIPTION

This is a short and simple class allowing simple object access to a parsed XML::LibXML tree, with methods for fetching children and attributes in as clean a manner as possible. My apologies for further polluting the XML:: space; this is a small and quick module, with easy and compact usage. Some will rightfully question placing another interface over the DOM methods provided by XML::LibXML, but my experience is that people appreciate the total simplicity provided by this module, despite its limitations.

=head1 USAGE

=item $xmlobj = new XML::SimpleObject::LibXML($parser->parse_string($XML))


$parser is an XML::LibXML object.

After creating $xmlobj, this object can now be used to browse the XML tree with the following methods.

=item $xmlobj->child('NAME')


This will return a new XML::SimpleObject::LibXML object using the child element NAME.


=item $xmlobj->children('NAME')


Called with an argument NAME, children() will return an array of XML::SimpleObject::LibXML objects of element NAME. Thus, if $xmlobj represents the top-level XML element, 'children' will return an array of all elements directly below the top-level that have the element name NAME.


=item $xmlobj->children

Called without arguments, 'children()' will return an array of XML::SimpleObjects::LibXML objects for all children elements of $xmlobj. Unlike XML::SimpleObject, XML::SimpleObject::LibXML retains the order of these children.


=item $xmlobj->children_names


This will return an array of all the names of child elements for $xmlobj. You can use this to step through all the children of a given element (see EXAMPLES), although multiple elements of the same name will not be identified. Use 'children()' instead.


=item $xmlobj->value


If the element represented by $xmlobj contains any PCDATA, this method will return that text data.

=item $xmlobj->attribute('NAME')


This returns the text for an attribute NAME of the XML element represented by $xmlobj.

=item $xmlobj->attributes


This returns a hash of key/value pairs for all elements in element $xmlobj.

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
  my $xmlobj = new XML::SimpleObject::LibXML ($parser->parse_string($XML));

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
      print join (", ", $filesobj->child($childname)->children_names), "\n";
  }

This will print:

    file has children: bytes, dest, name

By always using 'children()', you can step through each child object, retrieving them with 'child()'.

=head1 AUTHOR

Dan Brian <dan@brians.org>

=head1 SEE ALSO

perl(1), XML::SimpleObject, XML::Parser, XML::LibXML.

=cut


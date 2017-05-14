package XML::XPathToXML;
###
#
# Name: XML::XPathToXML
# Version: 0.01
# Description: Parses a list of XPath/value pairs and returns an XML::LibXML note-tree.
# Author: Kurt George Gjerde
# Copyright: InterMedia, University of Bergen (2002)
# Licence: Same as Perl
#
###

### POD at bottom.


###

use XML::LibXML;

my $PACKAGE = 'XML::XPathToXML';


### NEW
#
sub new {
  my ($class, %args) = @_;
  my $self = \%args;
  bless $self, $class;

  $self->{version} ||= '1.0';
  $self->{debug} ||= 0;
  $self->{maxAutoSiblings} = 256 if not defined $self->{maxAutoSiblings};

  $self->init();

  return $self;
}


### CLOSE
#
sub close {
  my $self = shift;
  undef $self->{tree};
  undef $self->{doc};
}


### INIT
#
sub init {
  my $self = shift;
  $self->{doc} = XML::LibXML::Document->createDocument( $self->{version}, $self->{encoding} );
  $self->{doc}->setDocumentElement( $self->{doc}->createElement('root') );
  $self->{tree} = {};
}


### RESET
#
sub reset {
  my $self = shift;
  $self->close;
  $self->init;
}


### GET IT
#
sub document { shift->{doc} }
sub documentElement { shift->{doc}->documentElement }
  

### PARSE
#
sub parse {
  my ($self, $data, $value) = @_;
  
  if (ref($data) eq 'HASH') {
    foreach my $xpath (sort keys %{$data}) {
      print "$xpath\n" if $self->{debug};
      $self->_createNode( $xpath, $data->{$xpath} );
    }
  }
  elsif (ref($data) eq 'ARRAY') {
    die "[$PACKAGE] Array not implemented.\n";
  }
  else {
    $self->_createNode( $data, $value );
  }
  
  return $self->{doc}->documentElement();
}




### _CREATE NODE
#
# Creates nodes, text nodes and attributes from an xpath and a value.
#
sub _createNode {
  my ($self, $xpath, $value) = @_;

  my $name = $xpath;
  $name =~ s{^.*\/(.*)$}{$1};
  $name =~ s{\[.*\]$}{};
  
  my $parent = $xpath;
  $parent =~ s{^(.*)\/.*$}{$1};

  my $xpathDisplay;
  if ($self->{debug}) {
    $xpathDisplay = $xpath;
    $xpathDisplay =~ s{\[.*\]$}{};
  }

  if ($parent && !$self->{doc}->find($parent)->size) {
    $self->_createNode($parent,undef);
  }

  my $parentNode;
  if ($parent) {
    $parentNode = $self->{doc}->find($parent)->get_node(1);
    die "[$PACKAGE] Parent node '$parent' to '$xpath' not found!\n" if !$parentNode;
  }
  
  if ($name =~ /^@(.*)$/) {
    print "   addAttribute: $xpathDisplay\n" if $self->{debug};
    $parentNode->setAttribute($1,$value);
  }    
  else {

    my $newNode = $self->{doc}->find($xpath)->get_node(1);

    my $cnt;

    while (!$newNode) {
      print "  createElement: $xpathDisplay\n" if $self->{debug};
  
      $cnt++;
      if ($self->{maxAutoSiblings} && $cnt>$self->{maxAutoSiblings}) {
        die "[$PACKAGE] Max automatic creation of siblings overflow ($self->{maxAutoSiblings}) for '$xpath'!\n";
      }
  
      $newNode = $self->{doc}->createElement($name);  
    
      if ($parent) {
        $parentNode->appendChild( $newNode );
      } else {
        $self->{doc}->setDocumentElement( $newNode );
      }
  
      $newNode = $self->{doc}->find($xpath)->get_node(1);
    
    }
    
    $newNode->appendTextNode($value) if $value;

  }
    
  return undef;
}



### 
#
# The following method use a hash to store all the xpaths and their nodes.
# Locating a node is purely based on looking up its xpath the way it's been
# written. Thus 'somenode[1]' and 'somenode[position()=1]' will be treated as
# two different nodes!
#
# Using proper xpath doc->find to retrieve nodes instead of the hash will
# eliminate this problem.
#
# Anyway:
#   - if you have a 'node[1]' and a 'node[3]' a 2nd node will not be 
#     created inbetween.
#   - if you have a 'node[position()=1]' and a 'node[2]' the nodes will
#     be reversed in the doc (all xpaths are created in alphabetical order).
#
# ALL OF THESE PROBLEMS HAVE BEEN FIXED IN THE _createNode METHOD ABOVE!
#
#
sub _createNode_simple {
  my ($self, $xpath, $value) = @_;

  my $name = $xpath;
  $name =~ s{^.*\/(.*)$}{$1};
  $name =~ s{\[.*\]$}{};
  
  my $parent = $xpath;
  $parent =~ s{^(.*)\/.*$}{$1};

  if ($parent && !defined $self->{tree}->{$parent}) {
    $self->_createNode_simple($parent, undef);
  }
  
  # Attribute
  if ($name =~ /^@/) {
    print "   addAttribute: $xpath\n" if $self->{debug};
    $self->{tree}->{$parent}->setAttribute($name,$value);
  } 
  # Element
  else {
    print "  createElement: $xpath\n" if $self->{debug};

    $self->{tree}->{$xpath} = $self->{doc}->createElement($name);  
  
    if ($parent) {
      $self->{tree}->{$parent}->appendChild( $self->{tree}->{$xpath} );
    } else {
      $self->{doc}->setDocumentElement( $self->{tree}->{$xpath} );
    }
  
    $self->{tree}->{$xpath}->appendTextNode($value) if $value;
  }

  return undef;
}


###########
451;


__END__


=head1 NAME

XML::XPathToXML - Generates XML document from XPath expressions

=head1 SYNOPSIS

  my %data = (
    '/project/name'         => 'The Ultimate Question',
    '/project/start'        => '2002-09-08',
    '/project/end'          => '7002002-09-08',
    '/project/@id'          => '42',
    '/project/temp/pre'     => '41',
    '/project/temp/pre[position()=6]' => '46',
    '/project/temp/pre[3]'  => '43',
  );

  my $xpx = new XML::XPathToXML( debug=>1 );

  $xpx->parse( \%data );

  $xpx->parse( '/project/temp/pre[last()]/@guess', 'tooHigh' );

  print $xpx->documentElement->toString(1)."\n";

Result:

  <project id="42">
    <name>The Ultimate Question</name>
    <start>2002-09-08</start>
    <end>7002002-09-08</end>
    <temp>
      <pre>41</pre>
      <pre/>
      <pre>43</pre>
      <pre/>
      <pre/>
      <pre guess="tooHigh">46</pre>
    </temp>
  </project>


=head1 DESCRIPTION

Generates an XML document or node tree from one or more XPath expressions.
Returnes an XML::LibXML::Document or XML::LibXML::Element.

Has not been tested with all kinds of XPath expressions. It will most likely
fail on complex ones. In the tradition of XML::LibXML errors must be trapped 
with eval() (it dies on error).




=head2 Methods

=over 4


=item new(%args)

Generates a new XML::XPathToXML object.

Arguments:

B<version> sets the XML version; default is "1.0".

B<encoding> sets the XML encoding; default is none (meaning UTF8).

B<debug> turns debugging on/off; default is off.

B<maxAutoSiblings> sets the maximum number of siblings that are automatically
generated for a single XPath expression; default is 256.


=item parse( $hashref )

=item parse( $xpath, $value )

Parse XPath/value pairs and generate nodes.


=item document()

Returns the document as an XML::LibXML::Document.


=item documentElement()

Returns the document element as an XML::LibXML::Element.


=item reset()

Resets the parser.


=item close()

Closes the parser. After this you have to call C<init()> before using the parser.


=item init()

Initiates the parser. Only needed after C<close()>.


=back

=head1 AUTHOR

Kurt George Gjerde

=head1 COPYRIGHT

2002 (c) InterMedia, University of Bergen.

Available under the same conditions as Perl.

















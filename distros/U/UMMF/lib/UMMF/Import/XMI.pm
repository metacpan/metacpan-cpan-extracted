package UMMF::Import::XMI;

use 5.6.0;
use strict;

our $AUTHOR = q{ kstephens@users.sourceforge.net 2003/04/19 };
our $VERSION = do { my @r = (q$Revision: 1.15 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::Import::XMI - Importer for XMI documents.

=head1 SYNOPSIS

  use UMMF::Import::XMI;
  my $fh = IO::File->new("< $some_xmi_file");
  my $factory = UMMF::Boot::MetaModel->factory; # Or UMMF::UML_1_5
  my $importer = UMMF::Import::XMI->new('factory' = { 'UML' => $factory' });
  my $content = $importer->import_input($fh);
  my $model = grep($_->isaModel, @$content);

=head1 DESCRIPTION

This package imports XMI version 1.0 and 1.2.

=head1 USAGE

=head1 PATTERNS

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@users.sourceforge.net 2003/04/19

=head1 SEE ALSO

L<XML::Import|XML::Import>

=head1 VERSION

$Revision: 1.15 $

=head1 METHODS

=cut
#######################################################################

use base qw(UMMF::Import);

use Carp qw(confess);
use Parse::RecDescent;
use UMMF::Core::Builder;
use IO::File;

use UMMF::Core::Util qw(:all);


#######################################################################

sub initialize
{
  my ($self) = @_;

  $self->SUPER::initialize;

  $self->{'debugParser'} ||= 0;

  $self->{'verbose'} ||= 1;

  # Define mappers for pre-UML 1.5 XMI documents.
  $self->{'mapper'} ||= {

    'UML 1.3 UMMF::UML::MetaModel::Foundation::Core::AssociationEnd set_type' => 
    # In UML 1.3 an AssociationEnd's target Classifier is called 'type';
    # In UML 1.5 it is called 'participant'.
    sub {
      my ($self, $obj, $meth, @args) = @_;

      ($obj, 'set_participant', @args);
    },

    'UML 1.3 UMMF::UML::MetaModel::Foundation::Extension_Mechanisms::TaggedValue set_tag' => 
    # In UML 1.3 a TaggedValue's name is called 'tag';
    # In UML 1.5 a TaggedValue has a TagDefinition that has a name.
    sub {
      my ($self, $obj, $meth, @args) = @_;

      $DB::single = 1;

      # Punt on model context, we don't know where it is!
      my $td = TagDefinition_for_name(undef, $args[0], $self->factory_ns('UML'));

      ($obj, 'set_type', $td);
    },

    'UML 1.3 UMMF::UML::MetaModel::Foundation::Extension_Mechanisms::TaggedValue set_value' => 
    # In XMI 1.0 UML 1.3 a TaggedValue's value is called 'value';
    # In UML 1.5 it's called 'dataValue'.
    sub {
      my ($self, $obj, $meth, @args) = @_;

      # $DB::single = 1;
      ($obj, 'set_dataValue', @args);
    },

    'UML 1.3 UMMF::UML::MetaModel::Foundation::Data_Types::MultiplicityRange set_upper' => 
    # Some UML modellers use '-1' for '*'.
    sub {
      my ($self, $obj, $meth, $val, @args) = @_;

      # die('WHEEE -1') if $val < 0;
      $val = '*' if $val < 0;

      ($obj, 'set_upper', $val, @args);
    },


  };

  $self;
}



sub import_input_file
{
  my ($self, $file) = @_;

  my $fh;
  unless ( ref($file) ) {
    $fh = IO::File->new;
    $fh->open("< $file") || die("Cannot read '$file': $!");
    $file = $fh;
  }

  my $result = $self->import_input_string($file);

  $fh->close if $fh;

  $result;
}


sub import_input_string
{
  my ($self, $input) = @_;

  use XML::DOM; # XML::DOM::Parser

  $_[1] = undef; # Help Devel::StackTrace

  # $DB::single = 1;

  # Parse an XML::DOM.  
  $self->message("parsing");
  my $xml_parser = new XML::DOM::Parser;
  my $xml_dom = $xml_parser->parse($input);
  $self->message("parsing: DONE");

  # Prepare the XML dom and get the document node.
  $self->message("preparing");
  my $doc = $self->prepare_xml_dom($xml_dom);
  $self->message("preparing: DONE");

  # Prepare factory.
  unless ( $self->{'factory'} ) {
    my $meta_model = "$self->{metamodel_name}-$self->{metamodel_version}";
    
    # FIXME Need some kind of registry.
    $meta_model =~ s/[^A-Za-z0-9]/_/sg;
    $meta_model = "UMMF::${meta_model}";

    eval qq{ use $meta_model; }; die $@ if $@;
    $self->{'factory'} = $meta_model->factory;
  }

  $self->{'factory'} = {
    '*' => $self->{'factory'},
  } unless ref($self->{'factory'}) eq 'HASH';

  #$DB::single = 1;

  # Get the XMI.content nodes.
  my ($content) = $doc->getElementsByTagName('XMI.content', 0);
  my @content_nodes = $content->getChildNodes;


  # Scan the XML doc to create instances.
  $self->message("create instances");
  grep($self->scan_xml_1($_), @content_nodes);
  $self->message("create instances: DONE");

  # $DB::single = 1;

  # Scan the XML doc to initialize instances.
  $self->message("initialize instances");
  my $results = [
		 grep(defined,
		      map($self->scan_xml_2($_),
			  @content_nodes)
		      )
		 ];
  $self->message("initialize instances: DONE");

  # Get rid of the XML DOM.
  $xml_dom->dispose;

  # Get rid of the id to obj mapping.
  delete $self->{'idobj'};

  delete $self->{'.cannot_do'};

  # $DB::single = 1;

  # Return the results.
  $results;
}


#######################################################################

sub scan_xml_1
{
  my ($self, $node) = @_;

  # $DB::single = 1;
  my $xmi_version;
  if ( ($xmi_version = $self->{'xmi_version'}) eq '1.0' ) {
    $self->scan_xmi_1_0_pass_1($node);
  } elsif ( $xmi_version eq '1.1' ) {
    $self->scan_xmi_1_1_pass_1($node);
  } else {
    $self->scan_xmi_1_2_pass_1($node);
  }
}


sub scan_xml_2
{
  my ($self, $node) = @_;

  my $xmi_version;
  if ( ($xmi_version = $self->{'xmi_version'}) eq '1.0' ) {
    $self->scan_xmi_1_0_pass_2($node);
  } elsif ( $xmi_version eq '1.1' ) {
    $self->scan_xmi_1_1_pass_2($node);
  } else {
    $self->scan_xmi_1_2_pass_2($node);
  }
}


#######################################################################
# XMI version 1.0 support
#

sub scan_xmi_1_0_pass_1
{
  my ($self, $node) = @_;

  return unless $node->isElementNode;

  my $name = $node->getNodeName;
  $name =~ /^(.+)\.([^\.]+)$/;

  my $pkg = $1;
  my $cls = $2;

  my $id = $node->getAttribute('xmi.id');
  
  # Only Elements with xmi.id can be referenced.
  if ( $id ) {
    # $DB::single = 1;
    
    my $type = join('::', split(/\./, $pkg), $cls);
    my $obj = $self->create_instance($self->{'metamodel_name'}, $type);
    return undef unless $obj;
    
    $self->{'idobj'}{$id} = $obj;
    
    #print STDERR "scan_xml_1: $id => $obj\n";
  }

  for my $subnode ( $node->getChildNodes ) {
    $self->scan_xmi_1_0_pass_1($subnode);
  }

  $self;
}


# Return value is the value to be added to parent object.
sub scan_xmi_1_0_pass_2
{
  my ($self, $node) = @_;

  return $node->getData if $node->isTextNode;

  return unless $node->isElementNode;

  my $name = $node->getNodeName;

  # Handle <XMI.field>DATA</XMI.field>
  if ( $name eq 'XMI.field' ) {
    return $node->getData;
  }
  if ( $name eq 'XMI.any' ) {
    return $node->getData;
  }

  $name =~ /^(.+)\.([^\.]+)$/;
  my $pkg = $1;
  my $cls = $2;

  my $obj;

  my $id = $node->getAttribute('xmi.idref');
  # $DB::single = 1;
  if ( $id ) {
    $obj = $self->{'idobj'}{$id};
    confess("No object for " . $node->getNodeName . " xmi.idef='$id'") 
      unless $obj;

    return $obj;
  }

  my $id = $node->getAttribute('xmi.id');
  # Only Elements with xmi.id can be referenced.
  if ( $id ) {
    $obj = $self->{'idobj'}{$id};
    confess("Internal error: No object for " . $node->getNodeName . "xmi.id='$id'") 
      unless $obj;
    #print STDERR "scan_xml_2: $obj => '$id'\n";
  } else {
    # Is probably a Data_Types class.
    my $type = join('::', split(/\./, $pkg), $cls);
    $obj = $self->create_instance('UML', $type);
    #print STDERR "scan_xml_2: $obj\n";
  }
  return $obj unless $obj;

  # Process attributes from XML elements.
  for my $subnode ( $node->getChildNodes ) {
    my $subnode_name = $subnode->getNodeName;

    # $DB::single = 1;
    next unless $subnode_name =~ /^(.+)\.([^\.]+)\.([^\.]+)$/;
    my $pkg = $1;
    my $cls = $2;
    my $attr = $3;

    my $val;
    if ( length($val = $subnode->getAttribute('xmi.value')) ) {
      $val = [ $val ];
    } else {
      # $DB::single = 1;
      # $DB::single = 1 if $attr eq 'lower';
      $val = [
	      grep(defined,
		   map($self->scan_xmi_1_0_pass_2($_),
		       $subnode->getChildNodes,
		       )
		   )
	      ];
    }

    eval {
      $self->can_do($obj, "set_$attr", @$val);
    };
    if ( $@ ) {
      confess("While processing XMI node: '$subnode_name'\n" . $@);
    }
  }

  # $DB::single = 1;

  $obj;
}


#######################################################################
# XMI version 1.1 support - PRELIMINARY
#

sub scan_xmi_1_1_pass_1
{
  my ($self, $node) = @_;

  return unless $node->isElementNode;

  my $name = $node->getNodeName;

  return unless $name =~ /^([^:]+):(.*)$/;

  my $xml_ns = $1;
  my $type = $2;

  if ( $type !~ /\./ ) {
    my $id = $node->getAttribute('xmi.id');
    
    # Only Elements with xmi.id can be referenced.
    if ( $id ) {
      # $DB::single = 1;

      my $obj = $self->create_instance($xml_ns, $type);
      return undef unless $obj;

      $self->{'idobj'}{$id} = $obj;

      #print STDERR "scan_xml_1: $id => $obj\n";
    }
  }

  for my $subnode ( $node->getChildNodes ) {
    $self->scan_xmi_1_1_pass_1($subnode);
  }

  $self;
}


# Return value is the value to be added to parent object.
sub scan_xmi_1_1_pass_2
{
  my ($self, $node) = @_;

  return $node->getData if $node->isTextNode;

  return unless $node->isElementNode;

  my $name = $node->getNodeName;

  # Handle <XMI.field>DATA</XMI.field>
  if ( $name eq 'XMI.field' ) {
    return $node->getData;
  }
  if ( $name eq 'XMI.any' ) {
    return $node->getData;
  }

  return unless $name =~ /^([^:]+):(.+)$/;

  my $xml_ns = $1;
  my $type = $2;

  my $obj;

  my $id = $node->getAttribute('xmi.idref');
  # $DB::single = 1;
  if ( $id ) {
    $obj = $self->{'idobj'}{$id};
    confess("No object for " . $node->getNodeName . " xmi.idef='$id'") 
      unless $obj;
    return $obj;
  }

  my $id = $node->getAttribute('xmi.id');
  # Only Elements with xmi.id can be referenced.
  if ( $id ) {
    $obj = $self->{'idobj'}{$id};
    confess("Internal Error: No object for " . $node->getNodeName . " xmi.id='$id'") 
      unless $obj;
    #print STDERR "scan_xml_2: $obj => '$id'\n";
  } else {
    # Is probably a Data_Types class.
    $obj = $self->create_instance($xml_ns, $type);
    #print STDERR "scan_xml_2: $obj\n";
  }
  return $obj unless $obj;

  # Process attributes from XML attributes.
  my $nodeMap = $node->getAttributes;
  my @attr = map($nodeMap->item($_), 0 .. $nodeMap->getLength - 1);
  #$nodeMap->dispose;

  for my $attr ( grep($_->getName ne 'xmi.id', @attr) ) {
    my $val = $attr->getValue;
    my $setter = 'set_' . $attr->getName;
    # Was an Object value expected?
    eval {
      $self->can_do($obj, $setter, $val);
    };
    # Retry.
    if ( $@ =~ /typecheck: /) {
      $val = $self->{'idobj'}{$val};
    confess("Internal Error: No object for " . $node->getNodeName . " xmi.id='$id'") 
      unless $val;
      $self->can_do($obj, $setter, $val);
    }
  }

  # Process attributes from XML elements.
  for my $subnode ( $node->getChildNodes ) {
    my $subnode_name = $subnode->getNodeName;
    next unless $subnode_name =~ /^([^:]+):([^\.]+)\.(.*)$/;
    my $xml_ns = $1;
    my $type = $2;
    my $attr = $3;

    my $val = [
	       grep(defined,
		    map($self->scan_xmi_1_1_pass_2($_),
			$subnode->getChildNodes,
			)
		    )
	       ];

    $self->can_do($obj, "set_$attr", @$val);
  }

  # $DB::single = 1;

  $obj;
}




#######################################################################
# XMI version 1.2 support
#

sub scan_xmi_1_2_pass_1
{
  my ($self, $node) = @_;

  return unless $node->isElementNode;

  my $name = $node->getNodeName;

  return unless $name =~ /^([^:]+):(.*)$/;

  my $xml_ns = $1;
  my $type = $2;

  if ( $type !~ /\./ ) {
    my $id = $node->getAttribute('xmi.id');
    
    # Only Elements with xmi.id can be referenced.
    if ( $id ) {
      # $DB::single = 1;

      my $obj = $self->create_instance($xml_ns, $type);
      return undef unless $obj;

      $self->{'idobj'}{$id} = $obj;

      #print STDERR "scan_xml_1: $id => $obj\n";
    }
  }

  for my $subnode ( $node->getChildNodes ) {
    $self->scan_xmi_1_2_pass_1($subnode);
  }

  $self;
}


# Return value is the value to be added to parent object.
sub scan_xmi_1_2_pass_2
{
  my ($self, $node) = @_;

  return $node->getData if $node->isTextNode;

  return unless $node->isElementNode;

  my $name = $node->getNodeName;

  # Handle <XMI.field>DATA</XMI.field>
  if ( $name eq 'XMI.field' ) {
    return $node->getData;
  }
  if ( $name eq 'XMI.any' ) {
    return $node->getData;
  }

  return unless $name =~ /^([^:]+):(.+)$/;

  my $xml_ns = $1;
  my $type = $2;

  my $obj;

  my $id = $node->getAttribute('xmi.idref');
  # $DB::single = 1;
  if ( $id ) {
    $obj = $self->{'idobj'}{$id};
    confess("No object for " . $node->getNodeName . " xmi.idef='$id'") 
      unless $obj;
    return $obj;
  }

  my $id = $node->getAttribute('xmi.id');
  # Only Elements with xmi.id can be referenced.
  if ( $id ) {
    $obj = $self->{'idobj'}{$id};
    confess("Internal Error: No object for " . $node->getNodeName . " xmi.id='$id'") 
      unless $obj;
    #print STDERR "scan_xml_2: $obj => '$id'\n";
  } else {
    # Is probably a Data_Types class.
    $obj = $self->create_instance($xml_ns, $type);
    #print STDERR "scan_xml_2: $obj\n";
  }
  return $obj unless $obj;

  # Process attributes from XML attributes.
  my $nodeMap = $node->getAttributes;
  my @attr = map($nodeMap->item($_), 0 .. $nodeMap->getLength - 1);
  #$nodeMap->dispose;

  for my $attr ( grep($_->getName ne 'xmi.id', @attr) ) {
    my $val = $attr->getValue;
    $self->can_do($obj,  'set_' . $attr->getName, $val);
  }

  # Process attributes from XML elements.
  for my $subnode ( $node->getChildNodes ) {
    my $subnode_name = $subnode->getNodeName;
    next unless $subnode_name =~ /^([^:]+):([^\.]+)\.(.*)$/;
    my $xml_ns = $1;
    my $type = $2;
    my $attr = $3;

    my $val = [
	       grep(defined,
		    map($self->scan_xmi_1_2_pass_2($_),
			$subnode->getChildNodes,
			)
		    )
	       ];

    $self->can_do($obj, "set_$attr", @$val);
  }

  # $DB::single = 1;

  $obj;
}


#######################################################################


sub new_multiplicity ($$) 
{
  my ($self, $range) = @_;

  my ($lower, $upper) = split( /\.\./, $range, 3 );
  
  # Use the factory to create the objects,
  # this avoids tying this XMI importer to any metamodel.
  #

  # use UMMF::UML_1_5::Foundation::Data_Types::Integer;
  $lower = $self->create_instance(undef, 
				  "Integer",
				  $lower);
  # use UMMF::UML_1_5::Foundation::Data_Types::UnlimitedInteger;
  $upper = $self->create_instance(undef,
				  "UnlimitedInteger",
				  $upper);

  # use UMMF::UML_1_5::Foundation::Data_Types::MultiplicityRange;
  my $mr = $self->create_instance(undef, 
				  'MultiplicityRange',
				  'lower' => $lower,
				  'upper' => $upper,
				  );
  # use UMMF::UML_1_5::Foundation::Data_Types::Multiplicity;
  my $m = $self->create_instance(undef, 
				 'Multiplicity',
				 'range' => [ $mr ],
				 );
  print "mr:", %$mr, "\tref:", ref($mr), "\n";
  $m;
}


sub can_do
{
  my ($self, $obj, $meth, @args) = @_;

  my $val;

  my $cls = ref($obj);

  my $key = "$self->{metamodel_name} $self->{metamodel_version} $cls $meth";
  # $DB::single = 1 if $cls =~ /TagDefinition/;

  my $mapper = $self->{'mapper'}{$key};
  if ( $mapper ) {
    ($obj, $meth, @args) = $mapper->($self, $obj, $meth, @args);
  }

  if ( $obj->can($meth) ) {
    if ( $meth eq 'set_stereotype' || $meth eq 'set_child' || $meth eq 'set_parent') {
      # hack for umbrello 1.4.2 (missing 'xmi.' prefix in idrefs to these)
      if ( ! ref($args[0]) ) {
	@args = $self->{'idobj'}{$args[0]};
      }
    }
    if ( $meth eq 'set_initialValue' ) {
      # we can not set empty initial values
      if ( ! ref($args[0]) && (defined $args[0] && $args[0] eq '') ) {
	undef @args;
      }
    }
    if ( $meth eq 'set_type' ) { #for DataType Attributes
      if ( ! ref($args[0]) ) {
	@args = $self->{'idobj'}{$args[0]};
      }
    }
    if ( $meth eq 'set_multiplicity' ) { #short notations
      if ( ! ref($args[0]) ) {
	$args[0] = $self->new_multiplicity($args[0]);
      }
    }
    $val = $obj->$meth(@args);
  } else {
    $self->warning("$cls cannot do $meth") unless $cls =~ /::Unimplemented::/;
    ++ $self->{'warnings'};
  }
  
  $val;
}


sub factory_ns
{
  my ($self, $xml_ns) = @_;

  my $factory = $self->{'factory'}{$xml_ns};
  $factory ||= $self->{'factory'}{'*'};
  
  unless ( $self->{'.factory_loaded'} ) {
    $self->{'.factory_loaded'} = 1;

    unless ( ref($factory) ) {
      eval "use $factory";
      die("Cannot use $factory: $@") if $@;
    }
  }

  $factory;
}


sub create_instance
{
  my ($self, $xml_ns, $type, @args) = @_;

  my $obj;

  # print STDERR substr($type, 0, 1);

  my $factory;
  eval {
    $factory = $self->factory_ns($xml_ns);
    # Support Primitive construction (one scalar arg).
    $obj = (
	    @args == 1 ? 
	    $factory->create($type, @args) : 
	    $factory->create_instance($type, @args)
	    );
  };
  if ( $@ ) {
    if ( $@ =~ /Unknown Classifier/ ) {
      $self->warning("Cannot find Classifer for '$xml_ns:$type'; using Unimplemented stub") unless $type =~ /Diagram|SimpleSemanticModelElement|GraphNode|Property|Uml1SemanticModelBridge|GraphConnector|GraphEdge|Polyline|TextElement/;

      # Create a stub class for unimplemented Classifier.
      my $cls = UMMF::Import::XMI::Unimplemented->__new_class($type);

      # Install in factory classMap.
      $factory->class_add($type, $cls);

      # Create stub object.
      $obj = $cls->new();
    } else {
      die($@);
    }
  }

  $obj;
}


#######################################################################

our $default_xmi_version = '1.2';

=head2 prepare_xml_dom

  my $parser = new XML::DOM::Parser;
  my $doc = $parser->parseFile($xml_file);
  my $xmi = prepare_xml_dom($doc);

Prepares an XML::DOM::Document object as an UMMF::UML::XMI::Document.

=cut
sub prepare_xml_dom
{
  my ($self, $doc) = @_;
  
  # $DB::single = 1;

  my $doc = $doc->getDocumentElement;

  # Get XMI version.
  my $xmi_version = $self->{'xmi_version'} || $doc->getAttribute('xmi.version');
  # $DB::single = 1;
  if ( $xmi_version eq '1.0' ) {
    # ok
  } elsif ( $xmi_version eq '1.1' ) { 
    die("Error: XMI version = \"$xmi_version\": not supported");
  } elsif ( $xmi_version eq '1.2' ) {
    # ok
  } else {
    $self->warning("XMI version = \"$xmi_version\": not specified; defaulting to '$default_xmi_version'");
    $xmi_version = $default_xmi_version;
  }
  $self->{'xmi_version'} = $xmi_version;

  # Get metamodel name and version.
  my ($xmi_metamodel) = $doc->getElementsByTagName('XMI.metamodel');
  $self->{'xmi_metamodel_name'} ||= $xmi_metamodel && $xmi_metamodel->getAttribute('xmi.name');
  $self->{'xmi_metamodel_version'} ||= $xmi_metamodel && $xmi_metamodel->getAttribute('xmi.version');

  $self->{'metamodel_name'} ||= $self->{'xmi_metamodel_name'} || 'UML'; # CONFIG
  $self->{'metamodel_version'} ||= $self->{'xmi_metamodel_version'} || '1.5'; # CONFIG

  # Get exporter name and version.
  my ($xmi_exporter) = $doc->getElementsByTagName('XMI.exporter');
  $self->{'exporter_name'} ||= $xmi_exporter || '*';
  my ($xmi_exporterVersion) = $doc->getElementsByTagName('XMI.exporterVersion');  $self->{'exporter_version'} ||= $xmi_exporterVersion || '*';


  # $DB::single = 1;

  # Normalize the document.
  $doc->normalize;

  # Remove unnessary whitespace text.
  $self->remove_whitespace_text($doc);

  # Generate map for 'xmi.idref' value => node.
  my $id_map = { };
  my $id_last;
  $self->gen_id_map($doc, $id_map, \$id_last);
  $self->{'id_map'} = $id_map;

  # Return the XML document.
  $doc;
}


sub remove_whitespace_text
{
  my $self = shift;

  for my $node ( @_ ) {
    if ( $node->isTextNode ) {
      my $x = $node->getData;
      # $DB::single = 1 if $x eq '1';
      my $y = trimws($x);
      
      my $ps = $node->getPreviousSibling;
      my $ns = $node->getNextSibling;
      
      if ( 0 ) {
	no warnings;
	print STDERR $ps, '<', $node, '>', $ns, "\n";
      }
      
      if ( $ps || $ns ) {
	unless ( length($y) ) {
	  print STDERR "removed '$x' => '$y'\n" if ( 0 );
	  $node->getParentNode->removeChild($node);
	  $node->dispose;
	  next;
	}
      }
      elsif ( $x ne $y ) {
	print STDERR "replaced '$x' => '$y'\n" if ( 0 );
	$node->setData($y);
      }
    } else {
      $self->remove_whitespace_text($node->getChildNodes);
    }
  }
}


sub gen_id_map
{
  my $self = shift;
  my $id_last = pop;
  my $id_map = pop;
  for my $node ( @_ ) {
    unless ( $node->isTextNode ) {
      if ( my $id = $node->getAttribute('xmi.id') ) {
	$id_map->{$id} = $node;
	$$id_last = $id;
      }
      $self->gen_id_map($node->getChildNodes, $id_map, $id_last);
    }
  }
}


#######################################################################


sub xmi_true
{
  my ($x) = @_;
  
  $x = trimws($x);
  
  no warnings;
  $x ne '' && $x ne 'false' && $x ne 'no' && $x ne '0';
}


#######################################################################


sub warning
{
  my ($self, @args) = @_;

  my $x = join('', @args);

  unless ( $self->{'.warning'}{$x} ++ ) {
    $self->message('Warning: ', $x);
  }

  $self;
}


sub message
{
  my ($self, @args) = @_;

  print STDERR 'UMMF: XMI: ', @args, "\n";

  $self;
}


#######################################################################


package UMMF::Import::XMI::Unimplemented;

#######################################################################

my %cls;

sub __new_class
{
  my ($self, $cls) = @_;

  unless ( $cls{$cls} ++ ) {
    my $expr = q{
      package __PACKAGE__::__CLS__;
      our @ISA = qw(__PACKAGE__);

      sub isa__CLS__ { 1 }

      1;
    };
    $expr =~ s/__PACKAGE__/__PACKAGE__/esg;
    $expr =~ s/__CLS__/$cls/esg;
    
    eval $expr; die $@ if $@;
  }

  $self = __PACKAGE__ . '::' . $cls;

  $self;
}


sub new 
{
  my ($self, %slot) = @_;
  bless(\%slot, $self);
}



*__new_instance = \&new;


our $AUTOLOAD;

sub AUTOLOAD
{
  
  no strict 'refs';
  
  my ($self, @args) = @_;
  local ($1, $2);
  
  my ($package, $operation) = $AUTOLOAD =~ m/^(?:(.+)::)([^:]+)$/;
  return if $operation eq 'DESTROY';
  
  # DO NOTHING!
  return;
}


#######################################################################


1;

#######################################################################


### Keep these comments at end of file: kstephens@users.sourceforge.net 2003/04/06 ###
### Local Variables: ###
### mode:perl ###
### perl-indent-level:2 ###
### perl-continued-statement-offset:0 ###
### perl-brace-offset:0 ###
### perl-label-offset:0 ###
### End: ###


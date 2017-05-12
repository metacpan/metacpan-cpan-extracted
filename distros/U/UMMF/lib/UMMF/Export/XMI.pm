package UMMF::Export::XMI;

use 5.6.1;
use strict;

our $AUTHOR = q{ kstephens@users.sourceforge.net 2003/04/15 };
our $VERSION = do { my @r = (q$Revision: 1.12 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::Export::XMI - An exporter for XMI.

=head1 SYNOPSIS

  use base qw(UMMF::Export::XMI);

  my $coder = UMMF::Export::XMI->new('output' => *STDOUT);
  my $coder->export_Model($model);

=head1 DESCRIPTION

This package allow UML models to be represented as XMI.
Actually anything that can supply its own meta-model.

=head1 USAGE

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@users.sourceforge.net 2003/04/15

=head1 SEE ALSO

L<UMMF::Core::MetaModel|UMMF::Core::MetaModel>

=head1 VERSION

$Revision: 1.12 $

=head1 METHODS

=cut

#######################################################################

use base qw(UMMF::Export);

use UMMF::Core::Util qw(:all);
use XML::Writer;

#######################################################################


sub initialize
{
  my ($self) = @_;

  # $DB::single = 1;

  $self->SUPER::initialize;

  $self->{'xmi_version'} ||= '1.2';
  $self->{'xml'} = XML::Writer->new('OUTPUT' => $self->{'output'},
				    #'NEWLINES' => 1,
				    'DATA_INDENT' => 1,
				    'DATA_MODE'=> 1,
				    );

  $self->{'id'} ||= '1';
  $self->{'id_prefix'} ||= 'xmi.';
  $self->{'objid'} ||= { };
  $self->{'idobj'} ||= { };

  $self;
}


our $ns = {
};

$ns->{'UML'}{'*'}{'nstag'} = 'UML';
$ns->{'UML'}{'*'}{'nsdef'} = 'org.omg.xmi.namespace.UML';

$ns->{'MOF'}{'*'}{'nstag'} = 'MOF';
$ns->{'MOF'}{'*'}{'nsdef'} = 'org.omg.xmi.namespace.MOF'; # ???

$ns->{'*'}{'*'}{'nstag'} = $ns->{'UML'}{'*'}{'nstag'};
$ns->{'*'}{'*'}{'nsdef'} = $ns->{'UML'}{'*'}{'nsdef'};

#######################################################################

sub export_Model
{
  my ($self, $model) = @_;
  
  # $DB::single = 1;

  # Get metamodel from $model?

  # M1
  $self->{'model'} = $model;
  #print STDERR "model = $self->{model}\n";
  # M2
  $self->{'metamodel'} ||= $self->{'model'}->__metamodel;
  #print STDERR "metamodel = $self->{metamodel}\n";
  # M3
  $self->{'metametamodel'} ||= $self->{'metamodel'}->__metamodel;
  #print STDERR "metametamodel = $self->{metametamodel}\n";

  # Get model name from $model
  unless ( $self->{'model_name'} ) {
    my $x = $self->{'model'};
    $x &&= $x->name;
    $self->{'model_name'} = $x;
  }

  # Get model version from "ummf.version" TV.
  unless ( $self->{'model_version'} ) {
    my $x = $self->{'model'};
    $x &&= ModelElement_taggedValue_name($x, 'ummf.version') || ModelElement_taggedValue_name($x, 'version');
    $self->{'model_version'} = $x;
  }

  # Get metamodel name from $model
  unless ( $self->{'metamodel_name'} ) {
    my $x = $self->{'metamodel'};
    $x &&= $x->name;
    $x = $1 if $x =~ /^(\w+)/;
    $self->{'metamodel_name'} = $x;
  }

  # Get metamodel version from "ummf.version" TV.
  unless ( $self->{'metamodel_version'} ) {
    my $x = $self->{'metamodel'};
    $x &&= ModelElement_taggedValue_name($x, 'ummf.version') || ModelElement_taggedValue_name($x, 'version');
    $self->{'metamodel_version'} = $x;
  }

  # Get metametamodel name from $model
  unless ( $self->{'metametamodel_name'} ) {
    my $x = $self->{'metametamodel'};
    $x &&= $x->name;
    $x = $1 if $x =~ /^(\w+)/;
    $self->{'metametamodel_name'} = $x;
  }

  # Get metametamodel version from "ummf.version" TV.
  unless ( $self->{'metametamodel_version'} ) {
    my $x = $self->{'metametamodel'};
    $x &&= ModelElement_taggedValue_name($x, 'ummf.version') || ModelElement_taggedValue_name($x, 'version');
    $self->{'metametamodel_version'} = $x;
  }

  # Format timestamp
  $self->{'timestamp'} ||= time;
  $self->{'timestamp'} = scalar gmtime $self->{'timestamp'} if $self->{'timestamp'} =~ /^\d+$/;
  $self->{'timestamp'} =~ s/(:\d\d) (\d\d\d\d)$/\1 GMT \2/;

  # Initialize XML namespaces.
  $self->{'nstag'} ||= 
    ModelElement_taggedValue_name($self->{'model'}, 'ummf.xmi.nstag') ||
    $ns->{$self->{'metamodel_name'}}{$self->{'metamodel_version'}}{'nstag'} ||
    $ns->{$self->{'metamodel_name'}}{'*'}{'nstag'} ||
    $ns->{'*'}{'*'}{'nstag'};
    
  $self->{'nsdef'} ||=
    ModelElement_taggedValue_name($self->{'model'}, 'ummf.xmi.nsdef') ||
    $ns->{$self->{'metamodel_name'}}{$self->{'metamodel_version'}}{'nsdef'} ||
    $ns->{$self->{'metamodel_name'}}{'*'}{'nsdef'} ||
    $ns->{'*'}{'*'}{'nsdef'};

  # Start export.
  if ( $self->{'xmi_version'} eq '1.2' ) {
    $self->export_xmi_1_2_root($model);
  } else {
    confess("XMI version '$self->{xmi_version}' not supported");
  }

  $self->{'idobj'} = undef;
  $self->{'objid'} = undef;

  $self;
}


sub export_xmi_1_2_root
{
  my ($self, $model) = @_;

  my $x = $self->{'xml'};

  # XMI root tag.
  my $xml_nstag = $self->{'nstag'};
  my $xml_nsdef = $self->{'nsdef'};

  $x->startTag('XMI',
	       'xmi.version' => $self->{'xmi_version'},
	       "xmlns:$xml_nstag" => $xml_nsdef,
	       'timestamp' => $self->{'timestamp'},
	       );


  $x->startTag('XMI.header');

  $x->emptyTag('XMI.model', 
	       'xmi.name' => $self->{'model_name'}, 
	       'xmi.version' => $self->{'model_version'},
	      );

  $x->emptyTag('XMI.metamodel', 
	       'xmi.name' => $self->{'metamodel_name'}, 
	       'xmi.version' => $self->{'metamodel_version'},
	      );

  $x->emptyTag('XMI.metametamodel', 
	       'xmi.name' => $self->{'metametamodel_name'}, 
	       'xmi.version' => $self->{'metametamodel_version'},
	      );


  $x->startTag('XMI.documentation');

  my $t;
  $x->startTag($t = 'XMI.exporter');
  $x->characters(__PACKAGE__);
  $x->endTag($t);

  $x->startTag($t = 'XMI.exporterVersion');
  $x->characters(UMMF->version);
  $x->endTag($t);

  $x->endTag('XMI.documentation');
  $x->endTag('XMI.header');

  $x->startTag('XMI.content');

  $self->export_content($model);

  $x->endTag('XMI.content');

  $x->endTag('XMI');

  $self;
}

#######################################################################


sub export_content
{
  my ($self, $obj) = @_;

  # Is undefined?  Do nothing.
  return $self unless defined $obj;

  my $x = $self->{'xml'};

  my $ref = ref($obj);

  # Is an array?  Do each element.
  if ( $ref eq 'ARRAY' ) {
    # If all elements are SCALARs, use <XMI.field>.
    my $scalar_count = grep(! ref($_), @$obj);
    if ( $scalar_count > 1 && $scalar_count == @$obj ) {
      for ( @$obj ) {
	$x->startTag('XMI.field');
	$self->export_content($_);
	$x->endTag('XMI.field');
      }
    } else {
      grep($self->export_content($_), @$obj);
    }
    return $self;
  }
  # Is a Set::Object?  Do each element.
  elsif ( $ref eq 'Set::Object' ) {
    grep($self->export_content($_), $obj->members);
    return $self;
  }


  # Is an atom?  XML Characters.
  unless ( $ref ) {
    $x->characters($obj);
    return $self;
  }


  #######################################################
  # Get meta-model Classifier for XMI?
  #
  
  # $DB::single = 1;

  my $cls;
  if ( UNIVERSAL::can($obj, '__classifier') ) {
    # $DB::single = 1;
    $cls = $obj->__classifier;
  } else {
    $cls = $self->{'classifier'}{$ref};
  }

  $DB::single = 1 unless ref($cls) =~ /::/;


  #######################################################
  # Compute top-level tag name.
  #

  $DB::single = 1 if ref($cls) eq 'ARRAY' || ref($self) eq 'ARRAY';

  my $xml_ns = $cls->{'nstag'} || $self->{'nstag'};
  $xml_ns .= ':' if $xml_ns;

  my $tag = $cls->{'tag'};
  unless ( $tag ) {
    $tag = $ref;
    $tag =~ s/^.*:://;
  }

  $tag = "$xml_ns$tag";

  #######################################################
  # Look for existing id?
  #

  my $id;

  # Object already visited?
  my $objid = $self->{'objid'};
  if ( ($id = $objid->{$obj}) ) {
    # Do an id.ref tag.
    $x->emptyTag($tag, 'xmi.idref' => $id);
  } else {
    # Generate new id.
    my $idobj = $self->{'idobj'};
    do {
      $id = $self->{'id'} ++;
      $id = $self->{'id_prefix'} . $id;
    } while ( $idobj->{$id} );

    # Remember obj <-> id relationship.
    $objid->{$obj} = $id;
    $idobj->{$id} = $obj;

    # Generate a list of XML attributes and XML (sub)elements.
    my @attr = ('xmi.id' => $id);

    # Interpret the metamodel to determine if Attributes
    # should be XML Elements or XML Attributes.
    #
    $self->export_interpret_metamodel($obj, $cls, 'attr', \@attr);
    
    # Remove duplicate XML attributes.
    #
    # ARE DUPLICATES ATTRIBUTES BUG OR A SYMPTOM OF FLATENED XMI->XML attribute namespace?!?
    #    bin/ummf -e XMI -o - UML-1.5 
    # seems to work now!
    #  --KS 2006/05/09
    {
      my %attr = @attr;
      $x->startTag($tag, %attr);
    }

    $self->export_interpret_metamodel($obj, $cls, 'elem');
    
    $x->endTag($tag);
  }

  $self;
}


#######################################################################


sub export_interpret_metamodel
{
  my ($self, $obj, $cls, $mode, $coll, $visited) = @_;

  # Elide common parent generalizations.
  $visited ||= { };
  if ( ! $visited->{$cls} ) {
    $visited->{$cls} = 1;

    # print STDERR "\ncls = ". $cls->name, ", mode = $mode\n";
    # $DB::single = 1;
    # $DB::single = 1 unless ref $cls;

    # Visit Generalization parents.
    for my $parent ( GeneralizableElement_generalization_parent($cls) ) {
      $DB::single = 1 unless ( $parent && ref $parent);
      $self->export_interpret_metamodel($obj, $parent, $mode, $coll, $visited);
    }

    my @elem;

    # Do the Attributes first.
    for my $attr ( grep($_->isaAttribute, $cls->feature) ) {

      # Skip unless TV ummf.xmi
      next unless ModelElement_taggedValue_name_true($attr, 'ummf.xmi', 1);

      # FIX ME!!!
      # Need some way to determine if the attribute value is a
      # a primitive, without relying or ref()ness.
      my $op = $attr->name;
      my $value = $obj->$op;

      # If the value is a ref,
      # it's either a container of objects or a reference
      # to an object.
      # Otherwise, 
      # it must be primitive and can go into a XML attribute.
      #
      # It would be best if the metamodel could help with this decision,
      # since the object's hash fields may not be initialized,
      # but then that would be my fault.
      #
      if ( ref($value) ) {
	if ( $mode eq 'elem' ) {
	  push(@elem, [ $op, $value ]);
	}
      } else {
	if ( $mode eq 'attr' ) {
	  # Attempt to revert primitive objects back to their real representation.
	  # e.g. UML meta-model Boolean!!!
	  push(@$coll, $op, $value) if defined $value;
	}
      }
    }

    # Do the Associations.
    # Associations must be XML elements because they are either references
    # or collections of references.
    if ( $mode eq 'elem' ) {
      for my $assoc_end ( $cls->association ) {
	for my $other_end ( AssociationEnd_opposite($assoc_end) ) {

	  # Skip unless TV ummf.xmi
	  next unless ModelElement_taggedValue_name_true($other_end, 'ummf.xmi', 1);

	  my $o_name = $other_end->name;
	  # Only named ends can be visible.
	  if ( $o_name && $o_name !~ /_$/ ) {
	    my $value = $obj->$o_name;
	    push(@elem, [ $o_name, $value ]);
	  }
	}
      }

      if ( @elem ) {
	# Well we can't expect our caller to do everything.
	my $x = $self->{'xml'};
	
	my $xml_ns = $cls->{'nstag'} || $self->{'nstag'};
	$xml_ns .= ':' if $xml_ns;
	
	for my $elem ( @elem ) {
	  my $tag = $xml_ns . $cls->name . '.' . $elem->[0];
	  
	  my $v = $elem->[1];
	  if ( defined $v ) {
	    next if ref($v) eq 'ARRAY' && ! @$v;

	    $x->startTag($tag);
	    
	    $self->export_content($v);
	    
	    $x->endTag($tag);
	  }
	}
      }
    }
  }

  return $self;
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


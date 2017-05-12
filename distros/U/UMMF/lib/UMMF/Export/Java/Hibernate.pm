package UMMF::Export::Java::Hibernate;

use 5.6.1;
use strict;
use warnings;

use base qw(UMMF::Export::Java);

our $AUTHOR = q{ kstephens@sourceforge.net 2003/08/04 };
our $VERSION = do { my @r = (q$Revision: 1.6 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::Export::Java::Hibernate - A Hibernate .hbn.xml code generator.

=head1 SYNOPSIS


=head1 DESCRIPTION

This package generates XML mapping documents for Hibernate from UML documents.

=head1 USAGE

=head1 PATTERNS

=over 4

=item * a design pattern


=back

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@sourceforge.net 2003/08/04

=head1 SEE ALSO

L<UMMF::UML::MetaModel|UMMF::UML::MetaModel>, L<http://hibernate.bluemars.net|http://hibernate.bluemars.net>

=head1 VERSION

$Revision: 1.6 $

=head1 METHODS

=cut

#######################################################################

use XML::Writer;

use UMMF::UML::MetaMetaModel::Util qw(:all);
use Carp qw(confess);

#######################################################################


sub export_kind
{
  'Java.Hibernate';
}


sub java_type
{
  my ($self, $obj) = @_;

  $self->package_name($obj);
}


my $java_Collection =
{
  'java.util.HashMap' => 'map',
  'java.util.TreeMap' => 'map',
  'java.util.Vector' => 'list',
  'java.util.LinkedList' => 'list',
  'java.util.HashSet' => 'set',
  'java.util.LinkedHashSet' => 'set', # 'list' for iteration order preservation?
  'java.util.TreeSet' => 'set',
};


sub hbn_needsCollection
{
  my ($self, $x) = @_;

  my $x_multi = $x->multiplicity;
  my $x_multi_upper = Multiplicity_upper($x_multi);

  # Is $x an AssociationEnd?
  my $isaAssociationEnd = $x->isaAssociationEnd;

  # The type of the Attribute or AssociationEnd.
  my $type = $isaAssociationEnd ? $x->participant : $x->type;

  my $java_type = $self->java_type($type);

  # ArgoUML encodes Java arrays as a DataType with '[]' at the end of the name.
  if ( $java_type =~ /\[\]$/ ) {
    return 'array';
  }

  # Direct mapping of Java class name to a Hibernate collection type.
  my $result = $java_Collection->{$java_type};
  return $result if $result;

  # If $x's Multiplicity upper bound is not 1,
  # it will need a collection.
  if ( $x_multi_upper ne 1 ) {
    # Is $x an AssociationEnd>
    if ( $isaAssociationEnd ) {
      # Is it ordered?
      if ( $x->ordering eq 'ordered' ) {
	# Use list for ordered collections.
	return 'list';
      } else {
	# Use 'set' for unordered collections.
	return 'set';
      }
    } else {
      # Assume $x is an Attribute
      return 'array';
    }
  }

  0; # Does not need a collection.
}


#######################################################################

sub hbn_isEnabled
{
  my ($self, $node) = @_;

  $self->config_enabled($node);
}


sub hbn_isaPrimitiveType
{
  my ($self, $type) = @_;

  return 1 if $type->isaDataType;

  return 1 if $self->config_value_true($type, 'isaPrimitiveType');

  return 1 if $type->name =~ /\[\]$/;

  my $type_name = $self->java_type($type);

  grep($_ eq $type_name, 'java.lang.String', 'java.lang.Class');
}



sub hbn_hasStoredSuperclass
{
  my ($self, $cls) = @_;

  for my $supercls ( GeneralizableElement_generalization_parent($cls) ) {
    next if $self->hbn_isaPrimitiveType($supercls);
    return 1 if $self->hbn_isEnabled($supercls);
    return 1 if $self->hbn_hasStoredSuperclass($supercls);
  }

  0;
}


sub hbn_hasStoredSubclass
{
  my ($self, $cls) = @_;

  for my $subcls ( GeneralizableElement_generalization_child($cls) ) {
    next if $self->hbn_isaPrimitiveType($subcls);
    return 1 if $self->hbn_isEnabled($subcls);
    return 1 if $self->hbn_hasStoredSubclass($subcls);
  }

  0;
}


=head2 hbn_rootClasses

Returns a list of all root classes in the model that
are not directly specified to be stored.

=cut
sub hbn_rootClasses
{
  my ($self, $model) = @_;

  my @root_classes;

  for my $cls ( Namespace_class($model) ) {
    next if $self->hbn_isaPrimitiveType($cls);
    next if $self->hbn_hasStoredSuperclass($cls);
    push(@root_classes, $cls);
  }

  wantarray ? @root_classes : \@root_classes;
}


#######################################################################


sub hbn_attribute_1
{
  my ($self, $attrx, $cls, $cls_table_name) = @_;
  
  my $xml = $self->{'xml'};

  my $attr = $attrx->{'obj'};

  my $attr_name = $attrx->{'name'};
  my $attr_type = $attrx->{'type'};
  my $attr_multi = $attrx->{'multiplicity'};

  my $java_type = $attrx->{'java_type'};

  my $type = $self->config_value($attr, 'type');
  my $column = $self->config_value($attr, 'column');
  my $cascade = $self->config_value_inherited($attr, 'cascade');
  my $outer_join = $self->config_value_inherited($attr, 'outer-join');
  my $not_null = $self->config_value($attr, 'not-null');

  # What type of collection?
  my $collection = $self->config_value($attr, 'collection', '');

  my $needsCollection = $attrx->{'needsCollection'};
  $collection = $needsCollection if $needsCollection;

  # Should the attr be rendered as a component?
  # Check the attribute itself,
  # then check the attribute's type.
  my $component = $self->config_value_true
  ($attr, 'component', 
   sub {
     $self->config_value_true($attr_type, 'component')
   }
   );

  if ( $collection ) {
    my $table_name = 
    $self->config_value($attr, 'collection.table', join('_', $cls_table_name, $attr_name));
    
    my $lazy =
    $self->config_value_inherited($attr, 'collection.lazy');
    
    my $inverse =
    $self->config_value($attr, 'collection.inverse');
    
    my $cascade =
    $self->config_value_inherited($attr, 'collection.cascade');
    
    my $sort =
    $self->config_value($attr, 'collection.sort');
    
    my $order_by =
    $self->config_value($attr, 'collection.order-by');
    
    my $where =
    $self->config_value($attr, 'collection.where');
    
    # <map|list|set|bag|array|primitive-array ...>
    $xml->startTag($collection,
		   'name' => $attr_name,
		   'table' => $table_name,
		   $lazy     ? ( 'lazy' => $lazy ) : (),
		   $inverse  ? ( 'inverse' => $inverse ) : (),
		   $cascade  ? ( 'cascade' => $cascade ) : (),
		   $sort     ? ( 'sort' => $sort ) : (),
		   $order_by ? ( 'order-by' => $order_by ) : (),
		   $where    ? ( 'where' => $where ) : (),
		   );
    
    # <key .../>
    if ( grep($_ eq $collection, 'map', 'set') ) {
      my $column =
      $self->config_value($attr, 'collection.key.column', 'id');
      
      my $type = 
      $self->config_value($attr, 'collection.key.type');
      
      $xml->emptyTag('key',
		     'column' => $column,
		     $type ? ( 'type' => $type ) : (),
		     );
    }
    
    # <index .../>
    if ( grep($_ eq $collection, 'map', 'list', 'array', 'primitive-array') ) {
      my $column =
      $self->config_value($attr, 'collection.index.column', 'i');
      
      my $type =
      $self->config_value($attr, 'collection.index.type', 
			  $collection eq 'list' ? 'int' : 'java.lang.Object',
			  );
      
      
      $xml->emptyTag('index',
		     'column' => $column,
		     $type ? ( 'type' => $type ) : (),
		     );
    }
    
    # <element .../>
    if ( grep($_ eq $collection, 'map', 'set', 'list', 'bag', 'array', 'primitive-array') ) {
      my $column =
      $self->config_value($attr, 'collection.element.column', 'e');
      
      
      my $type =
      $self->config_value($attr, 'collection.element.type', $java_type);

      my $e_not_null =
      $self->config_value($attr, 'collection.element.not-null', $not_null);

      
      $xml->emptyTag('element',
		     'column' => $column,
		     'type' => $type,
		     $e_not_null ? ( 'not-null' => $not_null ) : (),
		     );
    }

    $xml->endTag($collection);
  } elsif ( $self->hbn_isaPrimitiveType($attr_type) ) {
    # See http://hibernate.bluemars.net/hib_docs/reference/html_single/#or-mapping-s1-7
    # for default property type mapping.
    # $type ||= $java_type;
    
    $xml->emptyTag('property',
		   'name' => $attr_name,
		   $column ? ( 'column' => $column ) : (),
		   $type ? ( 'type' => $type ) : (),
		   );
  } elsif ( $component ) {
    $self->hbn_class($attr_type, 'component', 
		     'name' => $attr_name,
		     'class' => $java_type,
		     );
  } else {
    # Default to many-to-one mapping, a reference to an object.
    $xml->emptyTag('many-to-one',
		   'name' => $attr_name,
		   $column ? ( 'column' => $column ) : (),
		   'class' => $java_type,
		   $cascade ? ( 'cascade' => $cascade ) : (),
		   $outer_join ? ( 'outer-join' => $outer_join ) : (),
		   );
  }

  $self;
}



sub hbn_attribute
{
  my ($self, $attr, $cls, $cls_table_name) = @_;

  return unless $self->hbn_isEnabled($attr);
  
  my $attrx = 
  {
    'obj' => $attr,
    'java_type' => $self->java_type($attr->type),
    'needsCollection' => $self->hbn_needsCollection($attr),
    map(($_ => $attr->$_),
	'name',
	'type',
	'multiplicity',
	),
      };
  

  $self->hbn_attribute_1($attrx, $cls, $cls_table_name);
}


sub hbn_operation
{
  my ($self, $op, $cls) = @_;

}


=head2 hbn_association_end

  $self->hbn_association_end($end, $cls, $cls_table_name);

Called by C<hbn_class()> for each AssociationEnd where C<$cls> is a participant.

=cut
sub hbn_association_end
{
  my ($self, $end, $cls, $cls_table_name) = @_;

  # AssociationEnds opposite an AssociationEnd that has a targetScope = 'classifier'
  # cannot be directly stored in Hibernate.
  # To get this to work we would probably have to create Classes that
  # have all the targetScope = 'classifier' Associations.
  return if $end->targetScope eq 'classifier';

  for my $oend ( AssociationEnd_opposite($end) ) {
    $self->hbn_association_end_1($oend, $cls, $cls_table_name);
  }
}



sub hbn_association_end_1
{
  my ($self, $end, $cls, $cls_table_name) = @_;

  # Is this $end enabled for Hibernate?
  return unless $self->hbn_isEnabled($end);

  # Is this $end navigable?
  return unless String_toBoolean($end->isNavigable);

  my $attrx =
  {
    'obj' => $end,
    'type' => $end->participant,
    'java_type' => $self->java_type($end->participant),
    'needsCollection' => $self->hbn_needsCollection($end),
    map(($_ => $end->$_),
	'name',
	'multiplicity',
	),
  };

  # Render it as an attribute.
  $self->hbn_attribute_1($attrx, $cls, $cls_table_name);
}


sub hbn_class
{
  my ($self, $cls, $hbn_type, %opts) = @_;
  
  $hbn_type ||= 'class';

  $DB::single = 1;
  
  my $xml = $self->{'xml'};
  
  my $cls_name = $self->java_type($cls);

  #print STDERR "\nhbn_class $cls_name $hbn_type $cls\n";
  #scalar <STDIN>;

  my $hbn_isEnabled = $self->hbn_isEnabled($cls);
  if ( $hbn_isEnabled ) {
    # $DB::single = 1;
    
    print STDERR "\nhbn_class $cls_name $hbn_type ENABLED\n";
    #scalar <STDIN>;

    my $table_name = $self->config_value_inherited($cls, 'table');
    unless ( defined $table_name ) {
      $table_name = $cls_name;
      $table_name =~ s/\./_/sg;
    }
    
    # True if the class needs to discriminate subclass instances.
    my $discriminator = 
    $self->config_value_inherited_true($cls, 'discriminator');

    $discriminator = $self->hbn_hasStoredSubclass($cls)
    unless defined $discriminator;

    # The value that should be used to discriminate this class.
    my $discriminator_value = 
    $self->config_value($cls, 'discriminator-value',
			$cls_name
			);

    # The name for the id field.
    my $id_name = 
    $self->config_value_inherited($cls, 'id.name', 'id');
    
    my $id_column = 
    $self->config_value_inherited($cls, 'id.column', $id_name);
    
    my $id_type = 
    $self->config_value_inherited($cls, 'id.type', 'long');

    my $id_unsaved_value = 
    $self->config_value_inherited($cls, 'id.unsaved-value', '0');
    
    my $id_generator_class =
    $self->config_value_inherited($cls, 'id.generator.class', 'native');
    # Good default for database independence.
    
    my $id_generator_param = 
    $self->config_value_inherited($cls, 'id.generator.param', join('_', $table_name, $id_name, 'seq'));


    # Begin tag: 'class' or 'subclass'
    $xml->startTag($hbn_type, 
		   $hbn_type eq 'component' ?
		   ( %opts )
		   :
		   (
		    'name' => $cls_name,
		    'table' => $table_name,
		    'discriminator-value' => $discriminator_value,
		    )
		    );
    
    if ( $hbn_type eq 'class' ) {
      # Root classes implement id.
      $xml->startTag('id',
		     'name' => $id_name,
		     'type' => $id_type,
		     'column' => $id_column,
		     'unsaved-value' => $id_unsaved_value,
		     );
      $xml->startTag('generator',
		     'class' => $id_generator_class,
		     );
      $xml->startTag('param');
      $xml->characters($id_generator_param);
      $xml->endTag('param');
      $xml->endTag('generator');
      $xml->endTag('id');
    }
    if ( $hbn_type eq 'subclass' ) {
    }
    
    # Discriminator column?
    if ( $hbn_type ne 'component' ) {
      if ( $discriminator ) {
	my $discriminator_type = $self->config_value_inherited($cls, 'discriminator.type');
	my $discriminator_column = $self->config_value_inherited($cls, 'discriminator.column');

	$xml->emptyTag('discriminator',
		       $discriminator_column ? ( 'column' => $discriminator_column ) : (),
		       $discriminator_type   ? ( 'type' => $discriminator_type ) : (),
		       );
      }
    }

    # Attributes
    for my $attr ( Classifier_attribute($cls) ) {
      $self->hbn_attribute($attr, $cls, $table_name);
    }
    
    # Operations
    for my $op ( Classifier_operation($cls) ) {
      $self->hbn_operation($op, $cls, $table_name);
    }
    
    # Associations
    for my $end ( $cls->association ) {
      $self->hbn_association_end($end, $cls, $table_name);
    }
  }
  
  # Recur on subclasses.
  for my $subcls ( GeneralizableElement_generalization_child($cls) ) {
    next if $subcls eq $cls;
    print STDERR "$cls subclass $subcls\n";
    $self->hbn_class($subcls, 'subclass');
  }

  # End tag.
  if ( $hbn_isEnabled ) {
    $xml->endTag($hbn_type);
  }
}



#######################################################################


sub export_Model
{
    my ($self, $model) = @_;

    $model = $self->model_filter($model);

    $DB::single = 1;
    
    my $file_suffix = $self->config_value_inherited($model, 'suffix', '.hbn.xml');
    my $file_name = $self->config_value_inherited($model, 'file', "ummf$file_suffix");

    my $out = $self->{'output'};

    my $xml = new XML::Writer(
			      OUTPUT => $out,
			      NEWLINES => 1,
			      DATA_INDENT => 2,
			      );
    $self->{'xml'} = $xml;

    print $out (qq@
//-// FILE BEGIN $file_name
//-// 
@);

    $xml->startTag('hibernate-mapping');
    
    $DB::single = 1;

    # Do all the root classes and subsequent subclasses.
    for my $cls ( $self->hbn_rootClasses($model) ) {
      $self->hbn_class($cls);
    }

    $xml->endTag('hibernate-mapping');

    print $out (qq@
}
//-// FILE END $file_name
@);

}



#######################################################################

1;

#######################################################################


### Keep these comments at end of file: ks.perl@kurtstephens.com 2003/04/06 ###
### Local Variables: ###
### mode:perl ###
### perl-indent-level:2 ###
### perl-continued-statement-offset:0 ###
### perl-brace-offset:0 ###
### perl-label-offset:0 ###
### End: ###


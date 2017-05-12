package UMMF::Core::Builder;

use 5.6.1;
use strict;
#use warnings;

our $AUTHOR = q{ kstephens@users.sourceforge.net 2003/04/14 };
our $VERSION = do { my @r = (q$Revision: 1.23 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::Core::Builder - Constructs a Model from an input stream.

=head1 SYNOPSIS

  use UMMF::Core::Factory;
  use UMMF::Core::Builder;
  my $factory = UMMF::Core::Factory->new(...);
  my $builder = UMMF::Core::Builder->new('factory' => $factory);

  my $parser = SomeModelParser->new(...);
  $parser->parse($builder);

=head1 DESCRIPTION

Typically a model parser constructs one of these for handling parsing events.

This class manages creation of Models by managing scoping contexts for Model and Namespace during parsing of a meta-model or model description.

Once all the objects are created, the links between the ModelElements are finalized.

L<UMMF::UML::Import::MetaMetaModel|UMMF::UML::Import::MetaMetaModel> uses this class during parsing of the UML meta-model specificiation file.

=head1 USAGE

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@users.sourceforge.net 2003/04/14

=head1 SEE ALSO

L<UMMF::UML::MetaModel|UMMF::UML::MetaModel>.

=head1 VERSION

$Revision: 1.23 $

=head1 METHODS

=cut


#######################################################################

use base qw(UMMF::Core::Object);

#######################################################################

use UMMF::Core::Util qw(:all);

use Carp qw(confess);

#######################################################################

# Use this value to denote a value that is "true" for Parser::RecDecent nodes,
# but can be tested for during building.
# Should be a unique value that has no other purpose.

my $default;
$default = \$default;

sub _default_value { $default; }
sub _default
{
  my ($ref, $value) = @_;

  $$ref = $value if ($$ref eq $default) || ! defined $$ref;
  $$ref;
}

#######################################################################

sub initialize
{
  my ($self) = @_;

  $self->SUPER::initialize;

  # Top-level model.
  $self->{'model_top_level'} ||= undef;

  # Current Model.
  $self->{'model'} ||= undef;
  $self->{'modelSaved'} ||= [ ];

  # Current Namespace.
  $self->{'namespace'} ||= undef;
  $self->{'namespaceSaved'} ||= [ ];

  # Current Generalization parents.
  $self->{'generalization_parent'} ||= [ ];
  $self->{'generalization_parentSaved'} ||= [ ];

  # Collection of top-level meta objects.
  # Which are later vivified after all Classifiers have been created.
  $self->{'.attribute'} ||= [ ];
  $self->{'.association'} ||= [ ];
  $self->{'.reference'} ||= [ ];
  $self->{'.usage'} ||= [ ];
  $self->{'.generalization'} ||= [ ];

  $self->{'debugInput'}  ||= $ENV{UMMF_BUILDER_DEBUG};
  $self->{'debugCreate'} ||= 0;

  $self;
}


#######################################################################
# Model Managment:
#
# A model has Classifiers.
# We cannot create all the Features (and Associations) until all the Classifiers 
# have been created, because some Features may reference
# Classifiers that have not been created yet.
#
# Once we have created all the Classifiers, we
# can back-patch the type name references
# and construct the Features and Associations.
#
# This code also assumes that setting (or adding) one end of an 
# AssociationEnd link will cause the opposite
# AssociationEnd links to be updated appropriately.
#
# The UMMF::Boot::MetaModel classes implement this protocol. 
# The generated UMMF::UML_* will implement this protocol by 
# definition.
#

=head2 begin_Model

  $self->begin_Model($meta, \%attr, \%opts);

Begins a new Model in the current Namespace.

Model is a Namespace, so a new Namespace context is started.

If a Model has not been created yet $self->model_top_level is set to the new Model.

=cut
sub begin_Model
{
  my ($self, $meta, $attr, $opts) = @_;

  _default(\$meta);

  print STDERR "Model ($meta) \"$attr->{name}\" {\n" if $self->{'debugInput'};

  #$DB::single = 1;
  my $model = $self->create_Model($meta, $attr, $opts);
  
  # Remember last Model.
  push(@{$self->{'modelSave'}}, $self->{'model'});
  $self->{'model'} = $model;

  # Remember the top-level Model.
  $self->{'model_top_level'} ||= $model;

  # A Model is a Namespace.
  $self->begin_Namespace($model, $opts);

  $model;
}


=head2 end_Model

  my $model = $self->end_Model();

Terminates the current Model context, and resumes the previous Model and Namespace context.

Calls $self->finish_Model($model);

=cut
sub end_Model
{
  my ($self) = @_;

  my $model = $self->{'model'};

  die("Too many end_Model") unless @{$self->{'modelSave'}};

  die("Not enough end_Namespace") if $self->namespace ne $model;

  # A Model is a Namespace.
  $self->end_Namespace();

  print STDERR "} // Model \"$model->{name}\"\n" if $self->{'debugInput'};

  # Finish the model.
  $model = $self->finish_Model($model);

  # Restore previous Model scope.
  $self->{'model'} = pop(@{$self->{'modelSave'}});
  
  # Return the finished model.
  $model;
}


=head2 model

  my $model = $self->model;

Returns the current Model.

=cut
sub model
{
  my ($self) = @_;
  
  # $DB::single = 1;
  
  $self->{'model'};
}


=head2 model_top_level

  my $model = $self->model_top_level;

Returns the top-level Model, i.e. the first Model created by $self->begin_Model().

=cut
sub model_top_level
{
  my ($self) = @_;
  
  # $DB::single = 1;
  
  $self->{'model_top_level'};
}


#######################################################################

=head2 begin_Package

  my $pkg = $self->begin_Package(\%attr, \%opts);

Creates a new Package and begins a new Namespace context using the new Package.

=cut
sub begin_Package
{
  my ($self, $meta, $attr, $opts) = @_;

  _default(\$meta);

  print STDERR "Package ($meta) \"$attr->{name}\" {\n" if $self->{'debugInput'};

  my $ns = $self->create_Package($meta, $attr, $opts);

  # Package is a Namespace.
  $self->begin_Namespace($ns, $opts);

  $ns;
}


=head2 end_Package

  my $pkg = $self->end_Package();

Terminates the current Package context, and resumes the previous Namespace context.

=cut
sub end_Package
{
  my ($self) = @_;

  my $ns = $self->{'namespace'};

  # Package is a Namespace.
  $self->end_Namespace;

  print STDERR "} // Package $ns->{name}\n" if $self->{'debugInput'};

  $ns;
}


#######################################################################
#

=head2 add_Usage

  $self->add_Usage($meta, \@ns);

Added Usage Dependencies for the current Namespace.

Each @ns is a fully-qualified ModelElement name.

=cut
sub add_Usage
{
  my ($self, $meta, $ns) = @_;

  _default(\$meta);

  # $DB::single = 1 if $self->{'namespace'} =~ /Package/;

  push(@{$self->{'.usage'}}, [ $self->{'namespace'}, $ns ]);

  $self;
}


#######################################################################
# Manage a block of default Generalizations.

=head2 begin_Generalization_parent

   $self->Generalization_parent(\@model_element_name);

Begins a new Generalization parent context.

Classifiers created within this new Generalization parent context will specialize each of the @model_element by name, by default; i.e. no generalization parents are specified in the messages to $self->begin_Classifier().

This allows a short-hand notation for causing all Classifiers in a group to speciailize a set of other Classifiers.

=cut
sub begin_Generalization_parent
{
  my ($self, $x) = @_;

  my $name = join(', ', @$x);
  print STDERR "Generalization $name { \n" if ( $self->{'debugInput'} );

  push(@{$self->{'generalization_parentSave'} ||= [ ]}, $self->{'generalization_parent'});
  $self->{'generalization_parent'} = [ @$x ];

  $self;
}


=head2 end_Generalization_parent

Restores the previous Generalization parent context.

=cut
sub end_Generalization_parent
{
  my ($self) = @_;
  
  # confess("Too many end_Generalization_parent") unless @{$self->{'generalization_parentSaved'}};

  $self->{'generalization_parent'} = pop(@{$self->{'generalization_parentSaved'}});

  print STDERR "} // Generalization\n" if ( $self->{'debugInput'} );

  $self;
}


#######################################################################

=head2 begin_Classifier

  my $cls = $self->begin_Classifier($name, $meta, $gens);

Creates a new Classifier and begins a new Namespace context using the new Classifier.

C<$meta> defaults to C<'Class'>;

C<$gens> defaults to the current Generalization_parent context.

=cut
sub begin_Classifier
{
  my ($self, $meta, $attr, $opts, $gens) = @_;

  # Defaults
  _default(\$meta);
  $gens = undef if $gens && ! @$gens;

  # Generalize the classifier.

  print STDERR "Classifier ($meta) \"$attr->{name}\" { \n" if ( $self->{'debugInput'} );

  # Create a new Classifier object.
  my $cls = $self->create_Classifier($meta, $attr, $opts);

  # Remember generalizations for later because
  # We could be importing from another package.
  $gens ||= $self->{'generalization_parent'};

  if ( $gens && @$gens ) {
    push(@{$self->{'.generalization'}}, [ $cls, [ @$gens ] ]);
  }

  # A Classifier is a Namespace.
  $self->begin_Namespace($cls, $opts);
 
  $cls;
}


=head2 end_Classifier

  my $cls->end_Classifier(@opts);

Terminates the current Classifier context, and resumes the previous Namespace context.

If $opts[1] is true, this quickly creates an empty Classifier before hand.

=cut

sub end_Classifier
{
  my ($self, @opts) = @_;

  # A quicky!!
  if ( $opts[0] ) {
    $self->begin_Classifier(@opts);
  }

  # A Classifier is a Namespace.
  my $cls = $self->end_Namespace;

  print STDERR "} // Classifier $cls->{name}\n" if ( $self->{'debugInput'} );

  $cls;
}


#######################################################################
# Add a attribute.
#
# Type resolution is elided until finish_Attribute.
#

=head2 add_Attribute

  my $x = add_Attribute($meta, \%attr, \%opts);

Adds a new Attribute to the current Classifier.

C<%attr> should have the same structure as an Attribute object would have.

=cut
sub add_Attribute
{
  my ($self, $meta, $attr, $opts) = @_;

  _default(\$meta);
  _default(\$attr->{'initialValue'});
  _default(\$attr->{'multiplicity'});

  $attr = $self->create_Attribute($meta, $attr, $opts);

  if ( $self->{'debugInput'} ) {
    print STDERR Attribute_asString($attr), "// Attribute ($meta)\n";
  }

  push(@{$self->{'.attribute'}}, $attr);
  
  $attr;
}


#######################################################################
# Literals are primitive so they can be added now.
#

=head2 add_Literal

  $self->add_Literal($meta, $attr, $opts);

Adds a new Literal to the current Classifier, which must be an Enumeration.

=cut
sub add_Literal
{
  my ($self, $meta, $attr, $opts) = @_;

  _default(\$meta);

  print STDERR "  $attr->{name}; // Literal ($meta)\n" if ( $self->{'debugInput'} );

  $attr = $self->create_Literal($meta, $attr, $opts);

  $attr;
}


#######################################################################
# Add an Association.
#

=head2 add_Association

  my $x = add_Association($meta, \%attr, \%opts);

Adds a new Association between two or more participant Classifiers.

C<%attr> should have the same structure as an Association object.

If an AssociationEnd's participant is '.' the current Namespace is used.

Each AssociationEnd's targetScope defaults to 'instance'.

Participant resolution is elided until C<finish_Association>.

=cut
sub add_Association
{
  my ($self, $meta, $attr, $opts) = @_;

  _default(\$meta);
  grep(_default(\$_->{'.meta'}), @{$attr->{'connection'}});
  grep(_default(\$_->{'multiplicity'}), @{$attr->{'connection'}});

  confess("Not enough AssociationEnds") 
  unless @{$attr->{'connection'}} > 1;

  # '/name' refers to Generlization parent implementation of Association
  return '' if grep($_->{'name'} =~ /^\//, @{$attr->{'connection'}});

  $attr = $self->create_Association($meta, $attr, $opts);

  push(@{$self->{'.association'}}, $attr);

  $attr;
}


#######################################################################
# Add an Reference.
#

=head2 add_Reference

  my $x = add_Reference($meta, \%attr, \%opts);

MOF only.

Adds a new Reference between a Classifer and an AssociationEnd.

C<%attr> should have the same structure as an Reference object.

Resolution is elided until C<finish_Reference>.

=cut
sub add_Reference
{
  my ($self, $meta, $attr, $opts) = @_;

  _default(\$meta);
  _default(\$attr->{'multiplicity'});

  $attr = $self->create_Reference($meta, $attr, $opts);

  push(@{$self->{'.reference'}}, $attr);

  $attr;
}

#######################################################################
# Namespace mgmt.
#

=head2 begin_Namespace

  my $ns = $self->begin_Namespace($ns);

Begins a new Namespace context.

=cut
sub begin_Namespace
{
  my ($self, $ns, $opts) = @_;

  # $DB::single = 1;

  # print STDERR "Namespace \"$ns->{name}\" {\n" if $self->{'debugInput'};

  if ( $self->{'namespace'} ) {
    my $x = Namespace_ownedElement_name($self->{'namespace'}, $ns->{'name'});
    if ( $x && $x ne $ns ) {
      confess("Namespace '" . $self->{'namespace'}->{'name'} . "' already has '$x' named '" . $ns->{'name'} . "'");
    }
  }

  $self->add_options($ns, $opts);

  push(@{$self->{'namespaceSaved'}}, $self->{'namespace'});
  $self->{'namespace'} = $ns;

  $ns;
}


=head2 end_Namespace

  my $ns = $self->end_Namespace();

Returns current namespace after restoring previous Namespace context.

=cut
sub end_Namespace
{
  my ($self) = @_;
  
  confess("Too many end_Namespace") unless @{$self->{'namespaceSaved'}};

  my $ns = $self->{'namespace'};

  $self->{'namespace'} = pop(@{$self->{'namespaceSaved'}});

  # print STDERR "} // Namespace \"$ns->{name}\"\n" if $self->{'debugInput'};

  $ns;
}


#######################################################################
# Subclasses can override these for specific metamodels.
# 


sub create_Model
{
  my ($self, $meta, $attr, $opts) = @_;

  $meta ||= 'Model';

  print STDERR "create_Model $meta \"$attr->{name}\"\n" if $self->{'debugInput'} > 1;

  #$DB::single = 1;
  my $model = $self->create($meta, 
			    'visibility' => 'public',
			    'isSpecification' => 'false',
			    'isRoot' => 'false',
			    'isLeaf' => 'false',
			    'isActive' => 'false',
			    'isAbstract' => 'false',
			    
			    'namespace' => $self->{'namespace'},
			    %$attr,
			    );

  $model;
}


sub create_Package
{
  my ($self, $meta, $attr, $opts) = @_;

  $meta ||= 'Package';

  print STDERR "create_Package  $meta \"$attr->{name}\"\n" if $self->{'debugInput'} > 1;

  my $ns = $self->create($meta,
			# Defaults.
			'visibility' => 'public',
			'isSpecification' => 'false',
			'isRoot' => 'false',
			'isLeaf' => 'false',
			'isActive' => 'false',
			'isAbstract' => 'false',

			'namespace' => $self->{'namespace'},

			%$attr,
			);

  $ns;
}


sub create_Classifier
{
  my ($self, $meta, $attr, $opts) = @_;

  confess("Classifer meta undefined") unless $meta;
  # $meta ||= 'Class';

  print STDERR "create_Classifier $meta \"$attr->{name}\"\n" if $self->{'debugInput'} > 1;

  # Create a new Classifier object.
  my $cls = $self->create($meta,
			  # Defaults.
			  'visibility' => 'public',
			  'isSpecification' => 'false',
			  'isRoot' => 'false',
			  'isLeaf' => 'false',
			  'isAbstract' => 'false',
			  'isActive' => 'false',

			  'namespace' => $self->{'namespace'},

			  %$attr,
			 );
  $cls;
}


sub create_Attribute
{
  my ($self, $meta, $attr, $opts) = @_;

  $meta ||= 'Attribute';

  print STDERR "create_Attribute $meta \"$attr->{name}\" : $attr->{type} [$attr->{multiplicity}] = $attr->{initialValue}\n" if $self->{'debugInput'} > 1;

  $attr->{'.meta'} = $meta;
  $attr->{'.options'} = $opts;

  confess("$meta name undefined") unless $attr->{'name'};
  confess("$meta type undefined") unless $attr->{'type'};

  $attr->{'owner'} ||= $self->namespace;

  $attr->{'multiplicity'} ||= '1';

  $attr;
}


sub create_Literal
{
  my ($self, $meta, $attr, $opts) = @_;

  $meta ||= 'EnumerationLiteral';

  print STDERR "create_Literal $meta \"$attr->{name}\"\n" if $self->{'debugInput'} > 1;

  my $e = $self->namespace;
  $DB::single == 1 && confess("Not an Enumeration") unless $e->isaEnumeration;

  my $l = $self->create($meta,
			# Defaults.
			'visibility' => 'public',
			'isSpecification' => 'false',
			'isRoot' => 'false',
			'isLeaf' => 'false',
			'isAbstract' => 'false',

			'enumeration' => $e,
			'namespace' => $e,

			%$attr,
			);

  $l;
}


sub create_Association
{
  my ($self, $meta, $attr, $opts) = @_;

  $meta ||= 'Association';
  
  print STDERR "create_Association $meta \"$attr->{name}\"\n" if $self->{'debugInput'} > 1;

  $attr->{'.meta'} = $meta;
  $attr->{'.options'} = $opts;

  # If associationClass is '.' then this Association
  # is the AssociationClass's connection data.
  if ( $attr->{'.associationClass'} eq '.' ) {
    $attr->{'.associationClass'} = $self->namespace;
    $DB::single = 1 unless $attr->{'.associationClass'}->isaAssociationClass;
    confess("Not an AssociationClass") unless $attr->{'.associationClass'}->isaAssociationClass;
  }
  
  my $connection = $attr->{'connection'};
  for my $end ( @$connection ) {
    my $meta = $end->{'.meta'};
    delete $end->{'.meta'};
    my $opts = $end->{'.options'};
    delete $end->{'.options'};

    $end = $self->create_AssociationEnd($meta, $end, $opts);
  }

  # If all ends->isNavigable is not specified,
  #   make them all navigable.
  if ( scalar @$connection == scalar grep(! defined $_->{'isNavigable'}, @$connection ) ) {
    # print STDERR "All ends have unspecified isNavigable; making them isNavigable = 'true'.\n";
    for my $end ( @$connection ) {
      $end->{'isNavigable'} = 'true';
    }
  # Otherwise,
  #   for each $end,
  #      set isNavigable = 'false' if not specified.
  } else {
    for my $end ( @$connection ) {
      unless ( defined $end->{'isNavigable'} ) { 
	# print STDERR "End '$end->{name}' has unspecified isNavigable; isNavigable = 'false'.\n";
	$end->{'isNavigable'} = 'false';
      }
    }
  }

  # Default to navigable.
  for my $end ( @$connection ) {
    $end->{'isNavigable'} = 'true'
    unless defined $end->{'isNavigable'};
  }
 
  # confess('Too many AssociationEnds') if @{$attr->{'connection'}} > 2;

  if ( $self->{'debugInput'} ) {
    print STDERR Association_asString($attr), "\n";
  }


  $attr;
}


sub create_AssociationEnd
{
  my ($self, $meta, $attr, $opts) = @_;

  $meta ||= 'AssociationEnd';

  print STDERR "create_AssociationEnd $meta \"$attr->{name}\"\n" if $self->{'debugInput'} > 1;

  $attr->{'.meta'} = $meta;
  $attr->{'.options'} = $opts;

  # If participant is '.' use the enclosing Namespace
  # (i.e.) Classifier!!.
  $attr->{'participant'} = $self->namespace
    if ( $attr->{'participant'} eq '.' );
  
  $attr->{'namespace'} ||= $self->namespace;
  
  $attr->{'targetScope'} ||= 'instance';
  
  $attr->{'changeability'} ||= 'changeable';
  
  $attr->{'isSpecification'} ||= 'false';
  
  #confess("Same AssociationEnd specified more than once") 
  #if grep($_ eq $attr, @{$attr->{'connection'}}) > 1;
 
  $attr;
}

# MOF only
sub create_Reference
{
  my ($self, $meta, $attr, $opts) = @_;

  $meta ||= 'Reference';

  print STDERR "create_Reference $meta \"$attr->{name}\"\n" if $self->{'debugInput'} > 1;

  $attr->{'.meta'} = $meta;
  $attr->{'.options'} = $opts;

  $attr->{'owner'} ||= $self->namespace; # MOF uses "container"!
  
  $attr;
}


################################################################################
# Finialization
#
# Subclasses can override these for different metamodels.
#

sub finish_Usage
{
  my ($self, $attr) = @_;

  print STDERR "finish_Usage $attr\n" if $self->{'debugInput'} > 1;

  my @ns = @{$attr->[1]};

  # $DB::single = 1;

  eval {
    my @all;
    for my $ns ( @ns ) {
      my @name = split('::', $ns);
      my $all;

      # print STDERR "$attr->[0]{name} <=== $ns\n";
      # $DB::single = 1;

      # Was it a wildcarded Usage?
      if ( $name[-1] eq '*' ) {
	# Get the Package,
	# using everything up until '::*'.
	pop @name;
	my $name = join('::', @name);
	$ns = $self->ownedElement_name_($name);

	# Import everything from that package.
	$all = 1;
      } else {
	# Get the item.
	$ns = $self->ownedElement_name_($ns);

	# If the item is a Package,
	# Import everything from that package.
	if ( $ns->isaPackage ) {
	  $all = 1;
	}
      }

      if ( $all ) {
	push(@all, $ns->ownedElement);
      } else {
	# Import only the item.
	push(@all, $ns);      
      }
    }
    
    confess("importedElement is not ref") if grep(! ref($_), @all);
    
    $attr->[0]->add_importedElement(@all);
  };
  if ( $@ ) {
    die("To " . ModelElement_name_qualified($attr->[0]) . ":\n$@");
  }

  $self;
}


sub finish_Generalization
{
  my ($self, $attr) = @_;

  my $cls = $attr->[0];
  my @gen = @{$attr->[1]};
  
  eval {
    # $DB::single = 1;
    # Look up Generalization parent in the namespace (i.e. Package)
    # of the Class.
    #$DB::single = 1 if grep($_ eq 'Expression', @gen);
    @gen = map($self->lookupType($_, $cls->{'namespace'}), @gen);

    @gen = map($self->create('Generalization',
			     # Defaults.
			     'visibility' => 'public',
			     'isSpecification' => 'false',

			     'namespace' => ModelElement_namespace_common($_, $cls),
			     'parent' => $_,
			     'child' => $cls,
			     ),
	       @gen);
  };
  if ( $@ ) {
    $cls = $cls->{'name'};
    die("in Classifier $cls: \n$@");
  }


  $self;
}


sub finish_Attribute
{
  my ($self, $attr) = @_;

  eval {
    # Extract options.
    my $meta = $attr->{'.meta'};
    delete $attr->{'.meta'};
    my $opts = $attr->{'.options'};
    delete $attr->{'.options'};

    $meta ||= 'Attribute';

    # print STDERR "finish_Attribute: ", Data::Dumper->new( [ $attr ])->Dump;

    confess("$meta name undefined") unless $attr->{'name'};
    confess("$meta type undefined") unless $attr->{'type'};

    # $DB::single = 1;

    $self->create_Multiplicity(\$attr->{'multiplicity'}, $self);

    # Lookup Attribute types in the Class namespace (i.e. Package).
    $self->lookupType(\$attr->{'type'}, $attr->{'owner'}->{'namespace'});

    # Handle initialValue.
    if ( defined $attr->{'initialValue'} ) {
      # local $self->{'debugCreate'} = 1;
      $attr->{'initialValue'} = $self->create('Expression',
					      'language' => undef, # Universal Language
					      'body'     => $attr->{'initialValue'},
					     );
    }

    $attr = $self->create($meta, 
			  # Defaults.
			  'visibility' => 'public',
			  'isSpecification' => 'false',
			  'ownerScope' => 'instance',
			  'targetScope' => 'instance', # ???
			  'ordering' => 'unordered',
			  'changeability' => 'changeable',

			  'namespace' => $attr->{'owner'},
			  %$attr,
			 );

    # Apply options.
    $self->add_options($attr, $opts);
  };
  if ( $@ ) {
    my $n = $attr->{'owner'}{'name'};
    die("  to Classifier $n:\n$@");
  }

  $attr;
}


sub finish_Association
{
  my ($self, $attr) = @_;

  # $DB::single = 1;

  # Extract options.
  my $meta = $attr->{'.meta'};
  delete $attr->{'.meta'};
  my $opts = $attr->{'.options'};
  delete $attr->{'.options'};

  $meta ||= 'Association';

  # Was this an AssociationClass?
  my $assoc = $attr->{'.associationClass'};
  delete $attr->{'.associationClass'};

  # Resolve AssociationEnd participants
  my $connection = $attr->{'connection'};

  for my $end ( @$connection ) {
    # If the namespace of the AssociationEnd is a Classifier 
    # (which it most likely is)
    # defer participant lookup to the Classifier's namespace
    # (usu. a Package)
    #
    my $ns = $end->{'namespace'};
    while ( $ns->isaClassifier ) {
      $ns = $ns->{'namespace'};
    }

    eval {
      $self->lookupType(\$end->{'participant'}, $ns);
    };
    if ( $@ ) {
      print STDERR "ns = $ns\n";
      die($@);
    }
  }

  # Resolve Association namespace:
  # Common Namespace of AssociationEnd participants.
  $attr->{'namespace'} ||= ModelElement_namespace_common(map($_->{'participant'}, @$connection));

  # Fill in the rest of each AssociationEnd.
  for my $end ( @$connection ) {
    # Extract options.
    my $meta = $end->{'.meta'};
    delete $end->{'.meta'};
    my $opts = $end->{'.options'};
    delete $end->{'.options'};

    $meta ||= 'AssociationEnd';

    #use Data::Dumper;
    #print STDERR Data::Dumper->new([$end])->Maxdepth(2)->Dump, "\n";

    # Turn parsed multiplicity string into a Multiplicity object.
    $self->create_Multiplicity(\$end->{'multiplicity'}, $self);
    confess("multiplicity is not ref") unless ref($end->{'multiplicity'});

    #$DB::single = 1;
    # Create actual AssociationEnd object.
    $end = $self->create($meta,
			 '_association' => $assoc, # UML HACK!
			 %$end,
			 );

    $self->add_options($end, $opts);

    # If the Association is a AssociationClass,
    # the Ends were added to the AssocationClass,
    # beacuse '_assocation' was specified.
  }

  # Otherwise, create a new Association object.
  if ( ! $assoc ) {
    # $DB::single = 1 if grep($_->{'name'} eq 'range', @{$attr->{'connection'}});
    $assoc = $self->create($meta,
			   # Defaults.
			   'visibility' => 'public',
			   'isSpecification' => 'false',
			   'isRoot' => 'false',
			   'isLeaf' => 'false',
			   'isAbstract' => 'false',
		
			   %$attr,
			  );

    $self->add_options($assoc, $opts);
  }

  # $DB::single = 1 if grep(! $_->{'connection_'}, $assoc->connection);

  $assoc;
}


sub finish_Reference
{
  my ($self, $attr) = @_;

  my $attr;

  eval {
    # Extract options.
    my $meta = $attr->{'.meta'};
    delete $attr->{'.meta'};
    my $opts = $attr->{'.options'};
    delete $attr->{'.options'};

    confess("Reference meta undefined") unless $meta;
    confess("$meta name undefined") unless $attr->{'name'};
    # confess("$meta type undefined") unless $attr->{'type'};
    
    # $DB::single = 1;
    
    $self->create_Multiplicity(\$attr->{'multiplicity'}, $self);
    
    # Lookup Attribute type in the Class namespace (i.e. Package).
    $self->lookupType(\$attr->{'type'}, $attr->{'owner'}->{'namespace'});
    
    $attr = $self->create($meta, 
			  # Defaults.
			  'visibility' => 'public',
			  'isSpecification' => 'false',
			  'ownerScope' => 'instance',
			  'targetScope' => 'instance', # ???
			  'ordering' => 'unordered',
			  'changeability' => 'changeable',

			  'namespace' => $attr->{'owner'},
			  %$attr,
			 );

    # Apply options.
    $self->add_options($attr, $opts);
  };
  if ( $@ ) {
    my $n = $attr->{'owner'}{'name'};
    die("  to Classifier $n:\n$@");
  }

  $attr;
}


#######################################################################
#
# Factory interface
#

=head2 create

  my $obj = $self->create($name, @args);

Requests a new object of the $name type from the factory.

Subclasses can intercept all object creation here.

=cut 
sub create
{
  my ($self, $name, @args) = @_;

  local $self->{'factory'}{'debugCreate'} = $self->{'debugCreate'};

  $self->{'factory'}->create($name, @args);
}


=head2 flush

  $self->flush($name);

Notifies the factory that all objects of the $name type have been created and can be vivified.

C<UMMF::Boot::Factory> uses this notification to do magic finalizations of the constructed Model.  This is only used for the initial bootstrapping of UMMF.

=cut
sub flush
{
  my ($self, @args) = @_;

  $self->{'factory'}->flush(@args);

  $self;
}


#######################################################################
#
# Finish model.
# 

=head2 finish_Model

  my $self->finish_Model($model);

Completes constrution of the Model by completing the Usages, Generalizations, Attributes and Associations created so far.

The 

=cut
sub finish_Model
{
  my ($self, $model) = @_;

  # Flush Classifiers.
  $self->flush('Classifier');

  # Add Usages to Namespaces.
  # Do this first so name => Classifier lookups will work.
  eval {
    for my $attr ( @{$self->{'.usage'}} ) {
      $self->finish_Usage($attr);
    }
    @{$self->{'.usage'}} = ();
  };
  if ( $@ ) {
    die("While adding Usages: \n$@");
  }
  $self->flush('Usage');


  # Add Generalizations to Classifiers.
  eval {
    for my $attr ( @{$self->{'.generalization'}} ) {
      $self->finish_Generalization($attr);
    }
    @{$self->{'.generalization'}} = ();
  };
  if ( $@ ) {
    die("While adding Generalizations: \n$@");
  }
  $self->flush('Generalization');

  
  # Add Attributes to Classifiers.
  eval {
    for my $attr ( @{$self->{'.attribute'}} ) {
      eval {
	$self->finish_Attribute($attr);
      };
      if ( $@ ) {
	die("In Attribute: \n  " . Attribute_asString($attr) . ": \n$@");
      }
    }
    @{$self->{'.attribute'}} = ();
  };
  if ( $@ ) {
    die("While adding Attributes: \n$@");
  }
  $self->flush('Attribute');
  

  # Add Associations to Classifiers.
  eval {      
    for my $attr ( @{$self->{'.association'}} ) {
      eval {
	# $DB::single = 1;
	$self->finish_Association($attr);
      };
      if ( $@ ) {
	die("In Association: \n  " . Association_asString($attr) . ": \n$@");
      }
    }
    @{$self->{'.association'}} = ();
  };
  if ( $@ ) {
    die("While adding Associations: \n$@");
  }
  $self->flush('Association');

  # Add References to Classifiers.
  eval {      
    for my $attr ( @{$self->{'.reference'}} ) {
      eval {
	# $DB::single = 1;
	$self->finish_Reference($attr);
      };
      if ( $@ ) {
	die("In Reference: \n  " . $attr->{name} . ": \n$@");
      }
    }
    @{$self->{'.reference'}} = ();
  };
  if ( $@ ) {
    die("While adding References: \n$@");
  }
  $self->flush('Reference');


  # Model is complete!
  $self->flush('Model');


  $model;
}


#######################################################################
# Support 
#
# Glued to UMMF::UML::MetaMetaModel::Util functions.
# 

sub add_options
{
  my ($self, $obj, $opts) = @_;

  my $taggedValue = $opts && $opts->{'taggedValue'};

  if ( $taggedValue ) {
    # print STDERR ref($obj) . " $obj->{'name'} taggedValues: " . join(', ', map("$_->[0] : $_->[1]", @$taggedValue)) . "\n";
    for my $tv ( @$taggedValue ) {
      my ($name, $value) = @$tv;
      ModelElement_set_taggedValue_name($obj, $name, $value, $self->{'factory'});
    }
  }

  $self;
}


sub name_qualified
{
  my ($self, $obj) = @_;

  ModelElement_name_qualified($obj);
}


sub namespace_root
{
  my ($self, $ns) = @_;

  ModelElement_namespace_root($ns);
}


sub ownedElement_name_safe
{
  my ($self, $name, $ns) = @_;

  Namespace_ownedElement_name($ns, $name);
}


sub ownedElement_name
{
  my ($self, $name, $ns) = @_;

  $ns ||= $self->model;

  Namespace_ownedElement_name($ns, $name);
}


sub ownedElement_name_
{
  my ($self, $name, $ns) = @_;

  $ns ||= $self->model;

  Namespace_ownedElement_name_($ns, $name);
}


sub create_Multiplicity
{
  shift; # eat $self
  Multiplicity_fromString(@_);
}

#
# This is a lexical convention, not a UML convention.
#
# If looking up a name in from the context of a Classifier
# fallback on the Classifier's namespace.
# 
# This may not be typical of most languages but we are
# parsing a specification, and we dont need a bunch of Usages
# when most Classifiers in a Package collaborate with each other.
#
sub lookupType
{
  my ($self, $name, $ns) = @_;

  $ns ||= $self->model;

  Namespace_lookup($ns, $name);
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


package UMMF::Core::Util;

use 5.6.0;
use strict;
#use warnings; # no warnings, too much hassle to make them go away.


our $AUTHOR = q{ kstephens@users.sourceforge.net 2003/04/15 };
our $VERSION = do { my @r = (q$Revision: 1.36 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::Core::Util - Utilities for querying meta-models and models.

=head1 SYNOPSIS

=head1 DESCRIPTION

Useful manipulations of model.
These can be used for any UML meta level.

This allows other modules, like UMMF::UML::Export::*, to assume that the UML meta-model is "stupid"
i.e. has no support methods other than accessors for Attributes and Associations.

Eventually these could be imported into generated models as supplimentary methods.

=head1 USAGE

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@users.sourceforge.net 2003/04/15

=head1 SEE ALSO

L<UMMF::Core::MetaMetaModel|UMMF::Core::MetaMetaModel>

=head1 VERSION

$Revision: 1.36 $

=head1 METHODS

=cut

####################################################################################

use base qw(Exporter);

our @EXPORT_OK = 
qw(
   ModelElement_initialize

   ModelElement_name_qualified
   ModelElement_namespace_root
   ModelElement_namespace_common

   Namespace_ownedElement_match
   Namespace_ownedElement_name_safe
   Namespace_ownedElement_name
   Namespace_ownedElement_name_
   Namespace_lookup

   Namespace_namespace
   Namespace_classifier
   Namespace_class
   Namespace_interface
   Namespace_enumeration
   Namespace_associationClass
   
   GeneralizableElement_generalization_parent
   GeneralizableElement_generalization_parent_all
   GeneralizableElement_generalization_child
   GeneralizableElement_generalization_child_all

   Multiplicity_fromString
   Multiplicity_asString
   Multiplicity_lower
   Multiplicity_upper
   MultiplicityRange_asString

   Association_asString
   AssociationEnd_asString

   Attribute_asString

   ModelElement_taggedValue_name
   ModelElement_taggedValue_name_true
   ModelElement_taggedValue_inheritsFrom
   ModelElement_taggedValue_inherited
   ModelElement_taggedValue_inherited_true
   ModelElement_taggedValue_trace
   ModelElement_set_taggedValue_name
   
   TagDefinition_for_name

   Classifier_attribute
   Classifier_operation
   Classifier_method
   
   Class_Association_Attribute
   AssociationClass_Attribute

   Attribute_initialValue_language

   Operation_return

   Expression_body_language

   __fix_association_end_names

   AssociationEnd_opposite
   AssociationEnd_association

   Model_clone
   Attribute_clone
   Operation_clone
   Association_clone

   Model_destroy

   trimws
   trim_ws_undef

   String_toBoolean
   ISA_super
   index_array
   unique_proc
   unique
   unique_ref
   );

our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

#######################################################################

use Carp qw(confess);

#######################################################################

sub trimws
{
  my ($x) = @_;
  
  no warnings;
  
  $x =~ s/^[\s\n]+//s;
  $x =~ s/[\s\n]+$//s;
  
  $x;
}


sub trim_ws_undef
{
  my ($x) = @_;

  if ( ref($x) ) {
    return $$x = trim_ws_undef($$x);
  }

  return undef unless defined $x;

  $x =~ s/^[\s\n]+//sg;
  $x =~ s/[\s\n]+$//sg;

  length $x ? $x : undef;
}



sub String_toBoolean
{
  my ($x) = @_;
  
  return undef unless defined $x;

  $x = trimws($x);
  
  no warnings;
  $x ne '' && $x ne 'false' && $x ne 'no' && $x ne '0';
}


sub ISA_super
{
  my ($x) = @_;

  # $DB::single = 1;
  $x = ref($x) || $x;

  no strict 'refs';

  my @x = ( $x );
  my @c;
  while ( @x ) {
    my $x = pop @x;
    next if grep($_ eq $x, @c);
    push(@c, $x);
    push(@x, @{"${x}::ISA"});
  }

  wantarray ? @c : \@c;
}


sub members
{
  my ($x) = @_;

  $x ? (UNIVERSAL::can($x, 'members') ? $x->members() : @$x) : ();
}


sub index_array
{
  my ($x, @x) = @_;

  for ( my $i = -1; ++ $i < @x;  ) {
    return $i if $x[$i] eq $x;
  }

  undef;
}


sub identity { shift }


sub unique_proc ($$)
{
  my ($proc, $x) = @_;
  my %x = map(($proc->($_), $_), @$x);
  wantarray ? values %x : [ values %x ];
}


sub unique
{
  unique_proc(\&identity, \@_);
}


sub unique_ref ($)
{
  unique_proc(\&identity, $_[0]);
}


#######################################################################


sub ModelElement_initialize
{
  my ($self) = @_;

  my $name = $self->{'name'};
  if ( length $name ) {
    die("Invalid ModelElement name '$name'") if $name =~ /::/;
  }

  $self->SUPER::initialize;
}


sub ModelElement_set_name
{
  my ($self, $name) = @_;

  use Carp qw(confess);

  # Cannot rename.
  # confess("$self already named") if ( $self->{'name'} );

  # Cannot be qualified name.
  confess("Name '$name' is qualified") if $name =~ /::/;

  # Must be reasonable.
  if ( length($name) ) {
    confess("Name '$name' is invalid") if $name =~ /::/;
  }

  if ( $self->{'name'} ne $name ) { # Recursion lock
    my $old = $self->{'name'};
    $self->{'name'} = $name; # Recursion lock

    # Force name collision check.
    my $ns = $self->{'namespace'};
    if ( $ns ) {
      my $x;
      if ( ($x = (grep($_->name eq $name, $ns->ownedElement))[0]) 
	   && $x ne $self ) {
	confess("Namespace '" . $ns->name . "' already has element '$x' named '$name' for $self");
      }
    }
  }

  $self;
}


#######################################################################


sub Attribute_initialize
{
  my ($self) = @_;

  # IMPLEMENT: Is this a UML 1.5 constraint??
  $self->{'namespace'} = $self->{'owner'};

  # $DB::single = 1 unless defined $self->{'multiplicity'};
  # $DB::single = 1 unless defined $self->{'multiplicity'};
  $self->{'multiplicity'} ||= 1;
  Multiplicity_fromString(\$self->{'multiplicity'}, UMMF::UML::MetaMetaModel->factory);

  die("Invalid type: $self->{type}") unless $self->{'type'};
  die("Invalid name: $self->{name}") unless $self->{'name'} =~ /^[A-Za-z0-9_]+$/;
  $self;
}


#######################################################################


sub Association_initialize
{
  my ($self) = @_;

  my $x = $self->{'connection'};
  if ( $x ) {
    $x->[0]->set_namespace($x->[1]->participant) unless $x->[0]->namespace;
    $x->[1]->set_namespace($x->[0]->participant) unless $x->[1]->namespace;

    # Set the Association's namespace
    # to be the common Namespace of all the Participants.
    # This seems to be what ArgoUML is doing.
    unless ( $self->{'namespace'} ) {
      # $DB::single = 1;
      $self->set_namespace(
			   ModelElement_namespace_common(map($_->namespace, @$x))
			   );
    }

  }

  $self;
}


#######################################################################


sub AssociationEnd_initialize
{
  my ($self) = @_;

  # IMPLEMENT: Is this a UML 1.5 constraint??
  #$self->{'namespace'} ||= $self->participant->namespace;

  # $DB::single = 1 unless defined $self->{'multiplicity'};
  $self->{'multiplicity'} ||= 1;
  Multiplicity_fromString(\$self->{'multiplicity'}, UMMF::UML::MetaMetaModel->factory);

  $self;
}



#######################################################################


sub ModelElement_name_anon
{
  my ($node) = @_;

  my $name = $node->name;
  
  # Handle anonymous model elements.
  unless ( length($name) ) {
    # Use the position of ModelElement in it's Namespace's ownedElement
    # Association, even though that AssociationEnd is not ordered.
    if ( $node->namespace ) {
      my $i = 0;
      for my $x ( $node->namespace->ownedElement ) {
	if ( $x eq $node ) {
	  $name = "__Anon__$i";
	  last;
	}
	$i ++;
      }
    }
    
    # Fall back on the memory address of the ModelElement.
    unless ( length($name) ) { 
      $node =~ /0x([0-9a-f]+)/i;
      $name = $1 ? "__Anon__$1" : "__Anon_IGiveUp";
    }
  }
  
  $name;
}


=head2 ModelElement_name_qualified

  my @names = ModelElement_name_qualified($obj);
  my $qname = ModelElement_name_qualified($obj, $sep);
  my $qname = ModelElement_name_qualified($obj, $sep, $filter);


Returns the fully-qualified name for a ModelElement.
Applies C<$name = $filter-E<GT>($obj, $name)> to each ModelElement, if C<$filter> is defined.

In list context, returns the names of all parent namespaces.
In scalar context, joins the names of all parent namespaces with C<$sep>
C<$sep> defaults to C<'::'>.

=cut 
sub ModelElement_name_qualified
{
  my ($node, $sep, $filter) = @_;

  my @x;

  confess("$node is not ref") unless ref($node);

  #
  # Cull the Model's name (Model's are root namespaces, ie. Model->namespace = nil) 
  # Model names are not usually intended for
  # scoping ModelElements when generating code.
  #
  if ( $node->namespace ) {
    @x = ModelElement_name_qualified($node->namespace, undef, $filter);

    {
      my $name = ModelElement_name_anon($node);
      $name = $filter->($node, $name) if $filter;
      push(@x, $name);
    }
  }

  # $DB::single = 1;

  wantarray ? @x : join($sep || '::', @x); 
}


=head2 ModelElement_namespace_root

Returns the root Namespace of a ModelElement.

=cut
sub ModelElement_namespace_root
{
  my ($ns) = @_;

  while ( my $x = $ns ? $ns->namespace : confess("ns") ) {
    $ns = $x;
  }

  $ns;
}


=head2 ModelElement_namespace_common

Returns the Namespace parent that is common to two ModelElements.

For example: if C<$x> is in a UML Namespace C<"A::B"> and C<$y> is in a Namespace C<"A::C::D">, C<ModelElement_namespace_common($x, $y)> will return the C<"A"> Namespace object.

=cut
sub ModelElement_namespace_common
{
  my ($me1, $me2, @other) = @_;

  my $x = $me1 || $me2;

  X: while ( $x ) {
    my $y = $me2 || confess("me2");
    while ( $y ) {
      last X if $y eq $x;
      $y = $y->namespace;
    }
    $x = $x->namespace;
  }

  if ( @other ) {
    $x = ModelElement_namespace_common($x, @other);
  }

  $x;
}


our $namespace_trace = 0;
sub Namespace_ownedElement_match
{
  my ($ns, $match, $recur, $limit, $ns_too) = @_;

  unless ( ref($match) ) {
    my $meth = $match;
    $match = sub { $_[0]->$meth };
  }

  if ( $namespace_trace ) {
    print STDERR "N_oE_m ", scalar ModelElement_name_qualified($ns), " : $namespace_trace :\n";
  }

  my @x;
  my $oE = $ns->ownedElement;
  push(@x, grep($match->($_), $ns));

  if ( $recur ) {
    for my $x ( @$oE ) {
      confess("BAAAAAH $x") if ref($x) eq 'main';
      if ( $x->isaNamespace ) {
	if ( $ns_too ) {
	  push(@x, grep($match->($x), $x));
	  last if $limit && @x >= $limit;
	}
	push(@x, Namespace_ownedElement_match($x, $match, $recur, $limit, $ns_too));
	last if $limit && @x >= $limit;
      } else {
	push(@x, grep($match->($x), $x));
      }
    }
  } else {
    push(@x, grep($match->($_), @$oE));
  }

  if ( $namespace_trace ) {
    local $" = ', ';
    print STDERR "N_oE_m ", scalar ModelElement_name_qualified($ns), " : = @x\n";
  }

  @x = @x[0 .. $limit - 1] if $limit;

  if ( $limit && $namespace_trace ) {
    local $" = ', ';
    print STDERR "N_oE_m ", scalar ModelElement_name_qualified($ns), " limited = @x\n";
  }


  wantarray ? @x : \@x;
}


sub Namespace_ownedElement_name_safe
{
  my ($ns, $name) = @_;

  #$DB::single = 1 if $ns->{'name'} eq 'Model_Management';

  # Nice hack for relative Namespaces.
  if ( $name eq '.' ) {
    return $ns;
  }
  elsif ( $name eq '..' ) {
    $ns = $ns->namespace || $ns;
    return $ns;
  }

  # Try ownedElements first.
  for my $elem ( $ns->ownedElement ) {
    # $DB::single = 1 unless ref($elem);
    confess("ownedElement $elem is not blessed ref") unless ref($elem) =~ /::/;
    return $elem if ( $elem->name eq $name );
  }
  
  # Try importedElement if $ns is a package!
  if ( $ns->isaPackage ) {
    for my $elem ( $ns->importedElement ) {
      # alias through ElementImport?
      #$DB::single = 1 unless ref($elem);
      confess("importedElement is not ref") unless ref($elem);
      return $elem if ( $elem->name eq $name );
    }
  }

  undef;
}


sub Namespace_ownedElement_name
{
  my ($ns, $name) = @_;

  my @name = ref($name) ? @$name : split('::', $name);
  if ( @name != 1 ) {
    if ( $name[0] eq '.' ) {
      $ns = $ns;
      shift @name;
    } else {
      $ns = ModelElement_namespace_root($ns);
    }
    my $last_name = pop(@name);

    for my $pn ( @name ) {
      my $x = Namespace_ownedElement_name_safe($ns, $pn);

      unless ( $x ) {
	$DB::single = 1;
	confess("Cannot find Namespace named '$pn' from Namespace '" . ModelElement_name_qualified($ns) . "' $ns");
      }

      $ns = $x;
    }

    $name = $last_name;
  }
  
  Namespace_ownedElement_name_safe($ns, $name);
}


sub Namespace_ownedElement_name_
{
  my ($ns, $name) = @_;

  # Incase its already resolved.
  return $name if ref($name);

  my $x = Namespace_ownedElement_name($ns, $name);
  confess("Cannot find ModelElement named '$name' from Namespace '" . ModelElement_name_qualified($ns) . "' $ns") unless $x;

  $x;
}


#
# This is a lexical convention, not a UML convention.
#
# If looking up by name from within the context of a Classifier fails,
# fallback on the Classifier's namespace.
# 
# This may not be typical of most languages but we are
# parsing a specification, and we dont need a bunch of Usages
# when most Classifiers in a Package colaborate with each other.
# 
# There was some mention of direct ownedElements are visible from all
# parent namespaces in the UML spec.
#
sub Namespace_lookup
{
  my ($ns, $name) = @_;

  # Shorthand for search/replace.
  if ( ref($name) eq 'SCALAR' ) {
    return $$name = Namespace_lookup($ns, $$name);
  }

  # Namespace searches in a Classifier should
  # always bounce out to its namespace.
  if ( $ns->isaClassifier ) {
    my $x = Namespace_ownedElement_name($ns, $name);
    return $x if $x;

    # Try Classifier's namespace.
    $ns = $ns->namespace;
  }

  Namespace_ownedElement_name_($ns, $name);
}


=head2 Namespace_namespace

Returns a list of all Namespace nodes owned by a Namespace.

=cut
sub Namespace_namespace
{
  Namespace_ownedElement_match($_[0], 'isaNamespace', 1);
}


=head2 Namespace_classifier

Returns a list of all Classifier nodes owned by a Namespace.

=cut
sub Namespace_classifier
{
  Namespace_ownedElement_match($_[0], 'isaClassifier', 1);
}


=head2 Namespace_class

Returns a list of all Class nodes owned by a Namespace.

=cut
sub Namespace_class
{
  Namespace_ownedElement_match($_[0], 'isaClass', 1);
}


=head2 Namespace_associationClass

Returns a list of all AssociationClass nodes owned by a Namespace.

=cut
sub Namespace_associationClass
{
  Namespace_ownedElement_match($_[0], 'isaAssociationClass', 1);
}


=head2 Namespace_interface

Returns a list of all Interface nodes owned by a Namespace.

=cut
sub Namespace_interface
{
  Namespace_ownedElement_match($_[0], 'isaInterface', 1);
}


=head2 Namespace_enumeration

Returns a list of all Enumeration nodes owned by a Namespace.

=cut
sub Namespace_enumeration
{
  Namespace_ownedElement_match($_[0], 'isaEnumeration', 1);
}



#######################################################################


=head2 GeneralizableElement_generalization_parent

Returns a list of the Generalization parents (superclasses) of a GeneralizableElement.

=cut
sub GeneralizableElement_generalization_parent ($)
{
  my ($self) = @_;

  # $DB::single = 1 unless $self =~ /::/;
  # confess("not a ref") unless ref($self);

  my @x = map($_->parent, $self->generalization);

  @x;
}


=head2 GeneralizableElement_generalization_parent_all

Returns a list of all the Generalization parents (superclasses) of a GeneralizableElement, toward the root Generalization (root baseclasses).

=cut
sub GeneralizableElement_generalization_parent_all ($)
{
  my ($self) = @_;

  # $DB::single = 1 unless $self =~ /::/;

  my @gen_all;

  my @q = GeneralizableElement_generalization_parent($self);
  while ( @q ) {
    my $q = pop @q;
    next if grep($_ eq $q, @gen_all);
    push(@gen_all, $q);
    push(@q, map($_->parent,
		 grep(defined, $q->generalization),
		 )
	 );
  }

  @gen_all;
}


sub GeneralizableElement_generalization_child ($)
{
  my ($self) = @_;

  # $DB::single = 1 unless $self =~ /::/;
  # confess("not a ref") unless ref($self);

  my @x = map($_->child, $self->generalization);

  @x;
}


sub GeneralizableElement_generalization_child_all ($)
{
  my ($self) = @_;

  # $DB::single = 1 unless $self =~ /::/;

  my @gen_all;

  my @q = GeneralizableElement_generalization_child($self);
  while ( @q ) {
    my $q = pop @q;
    next if grep($_ eq $q, @gen_all);
    push(@gen_all, $q);
    push(@q, map($_->child,
		 grep(defined, $q->generalization),
		 )
	 );
  }

  @gen_all;
}


#######################################################################


=head2 Classifier_attribute

Returns all Attribute features.

=cut
sub Classifier_attribute
{
  my ($node) = @_;

  grep($_->isaAttribute, $node->feature);
}


=head2 Classifier_operation

Returns all Operation features

=cut
sub Classifier_operation
{
  my ($node) = @_;

  grep($_->isaOperation, $node->feature);
}


=head2 Classifier_method

Returns all Method features.

=cut
sub Classifier_method
{
  my ($node) = @_;

  grep($_->isaMethod, $node->feature);
}


#######################################################################


=head2 Operation_return

Returns the return Parameter.

=cut
sub Operation_return
{
  my ($node) = @_;

  my @x = grep($_->kind eq 'return', $node->parameter);

  @x ? $x[0] : undef;
}



#######################################################################


=head2 Expression_body_language

Returns the body text of an Expression for a specific language.

=cut
sub Expression_body_language
{
  my ($obj, $lang) = @_;

  my $value;

  if ( $obj ) {
    # Specific language?
    if ( $lang && lc($obj->language) eq lc($lang) ) { 
      # confess("$obj -> body") unless UNIVERSAL::can($obj, 'body');
      $value = $obj->body;
    }
    # Universal language?
    elsif ( $lang && ! length($obj->language) ) {
      $value = $obj->body;
    }
    # No language specified.
    elsif ( ! $lang ) { 
      $value = $obj->body;
    }
  }

  if ( defined $value ) {
    $value = trimws($value);
  }

  $value = undef if defined $value && ! length $value;

  $value;
}


#######################################################################


=head2 Attribute_initialValue_language

Returns the body text of an Attribute's initialValue Expression.

=cut
sub Attribute_initialValue_language
{
  my ($node, $lang) = @_;

  no warnings;

  my $body;

  # Use initialValue.body if it matches the requested language.
  my $iV = $node->initialValue;
  if ( $iV && lc($iV->language) eq lc($lang) ) {
    $body = $iV->body;
  } else {
    # Try tagged values.
    $lang = ucfirst($lang);
    
    $body = (grep(defined,
		  map(join('', ModelElement_taggedValue_name($node, $_)),
		      "ummf.$lang.initialValue",
		      "ummf.initialValue")
		 ))[0];
  }

  # Default to initialValue.body if initialValue.language is not specified.
  if ( ! defined $body ) {
    if ( $iV && ! length($iV->language) ) {
      $body = $iV->body;
    }
  }

  $body;
}


#######################################################################


sub __make_association_end_name
{
  my ($x, $y) = @_;

  $x = $x->name if ( ref($x) );

  $x =~ s/^.*:://s;

  if ( @_ == 2 ) {
    $x = "${y}_$x" if $y;
    
    $x .= '_';
  } else {
    $x = lcfirst($x);
  }

  $x;
}


sub __fix_association_end_names
{
  if ( ! $_[1] && $_[3] ) {
    # T1 "" --- T2 n2 => n2_T1_
    # $DB::single = 1;

    #local $" = "\",\t\""; print STDERR "A\t@_\n";
    $_[1] = __make_association_end_name($_[0]);

    #print STDERR " =>\t@_\n";
  }
  elsif ( $_[1] && ! $_[3] ) {
    # T1 n1 --- T2 "" => n1_T2_

    # $DB::single = 1;
    #local $" = "\",\t\""; print STDERR "A\t@_\n";

    $_[3] = __make_association_end_name($_[2]);

    #print STDERR " =>\t@_\n";
  }
  elsif ( ! $_[1] && ! $_[3] ) {
    # $DB::single = 1;

    #local $" = "\",\t\""; print STDERR "A\t@_\n";

    $_[1] = __make_association_end_name($_[0]);
    $_[3] = __make_association_end_name($_[2]);

    #print STDERR " =>\t@_\n";
  }
  if ( $_[1] eq $_[3] ) {
    $_[1] .= '0';
    $_[3] .= '1';
  }
}




my ($a_type, $a_name, $e_type, $e_name) = 
(
 'Association',
 '',
 'AssociationEnd',
 'connection',
 );

__fix_association_end_names($a_type, $a_name, $e_type, $e_name);


sub AssociationEnd_association
{
  my ($end) = @_;

  confess("undef") unless $end;

  my $assoc;

  #
  # Hack to get around the unamed AssocationEnd between
  # AssocationEnd (connection) ------ () Association.
  #

  if ( 1 ) {
    # See modified MetaModel.spec.
    #
    #$DB::single = 1;
    $assoc = $end->{'_association'};
  }

  if ( 0 && ! $assoc ) {
    # See __fix_association_end_names()
    $assoc = $end->$a_name; 
  }

  unless ( $assoc ) {
    # Since the UML meta model does not have a role name for the Association
    # it is not navigable.
    # So to find the AssociationEnd opposite another end, we have to search the entire
    # model.
    
    # local $namespace_trace = "AssociationEnd_association $end";
    my ($assoc) = Namespace_ownedElement_match
    (ModelElement_namespace_root($end->participant),
     sub {
       $_[0]->isaAssociation && grep($_ eq $end, $_[0]->connection);
     },
     1,
     );    
  }

  $DB::single = 1 unless $assoc;
  confess("Cannot get Association from AssocationEnd " . AssociationEnd_asString($end)) unless $assoc;

  $assoc;
}


=head2 AssociationEnd_opposite

  @other_ends = AssociationEnd_opposite($end);

Returns a list of all the AssociationEnds opposite to the AssociationEnd.
Typically this list has only one AssociationEnd.

=cut
sub AssociationEnd_opposite
{
  my ($end) = @_;

  my @x;

  my $assoc = AssociationEnd_association($end);

  @x = grep($_ ne $end, $assoc->connection);

  @x;
}


#######################################################################
# These assume a Factory.
#

=head2 Multiplicity_fromString

  my $multiplicity = Multiplicity_fromString($str, $factory);

Creates a Multiplicity object, using factory C<$factory> by parsing string C<$str>.

=cut
sub Multiplicity_fromString
{
  my ($str, $factory) = @_;

  # Shorthand.
  if ( ref($str) eq 'SCALAR' ) {
    return $$str = Multiplicity_fromString($$str, $factory);
  }

  # Dont bother if its already an object.
  return $str if ref($str);

  my @range = split(/\s*,\s*/, $str);

  push(@range, 1) unless @range;

  for my $r ( @range ) {
    my @x = split(/\s*\.\.\s*/, $r, 2);
    
    $r = $factory->create('MultiplicityRange',
			  'lower' => $x[0] ne '*' ? $x[0] : 0,
			  'upper' => $x[1] || $x[0],
			  );
  }

  my $x = $factory->create('Multiplicity',
			   'range' => \@range,
			   );

  $x;
}


sub Multiplicity_asString
{
  my ($node) = @_;

  return $node unless ref $node;

  join(',',
       map(MultiplicityRange_asString($_),
	   $node->range)
       );
}


sub Multiplicity_lower
{
  my ($multi) = @_;

  my $lower;

  # Note: 
  # This code does not use accessor methods,
  # so UMMF::Boot::Factory::Object::AUTOLOAD()
  # will not go into recursion.
  #
  if ( $multi ) {
    for my $r ( members($multi->{'range'}) ) {
      my $x = $r->{'lower'};

      # ArgoUML and Poseidon use '-1' for UnlimitedInteger.
      $x = '*' if $x < 0; 
      
      if ( $x eq '*'  ) {
	confess("Unexpected UnlimitedInteger for MultiplicityRange lower");
      }
      elsif ( ! defined $lower ) {
	$lower = $x;
      }
      elsif ( $lower > $x ) {
	$lower = $x;
      }
    }
  }

  $lower = 1 unless defined $lower; # If none specified.

  $lower;
}


sub Multiplicity_upper
{
  my ($multi) = @_;

  my $upper = 1; # If none specified.

  # Note: 
  # This code does not use accessor methods,
  # so UMMF::Boot::Factory::Object::AUTOLOAD()
  # will not go into recursion.
  #
  if ( $multi ) {
    for my $r ( members($multi->{'range'}) ) {
      my $x = $r->{'upper'};

      # ArgoUML and Poseidon use '-1' for UnlimitedInteger.
      $x = '*' if $x < 0; 

      if ( $x eq '*'  ) {
	$upper = $x;
	last;
      }
      elsif ( $upper < $x ) {
	$upper = $x;
      }
    }
  }

  $upper;
}


sub MultiplicityRange_asString
{
  my ($node) = @_;

  return 1 unless $node;

  my $u = $node->upper;
  my $l = $node->lower;

  $l = '*' if $l < 0;

  $u eq $l ? $u : "$l..$u";
}


sub ModelElement_name_with_id
{
  my ($p) = @_;

  no warnings;

  my $id = ref($p) ? $p->{'_id'} : '';
  $p = ref($p) ? $p->{'name'} : $p;
  $p = '""' unless length $p;
  $p = "$p /*$id*/" if ( $id );

  $p;
}


sub Association_asString
{
  my ($assoc, %end_annot) = @_;

  no warnings;

  my $name = ModelElement_name_with_id($assoc);

  sprintf("  @ @ %-50s\n",
	  $name
	  ) .
  join(",\n", 
       map("  " . AssociationEnd_asString($_, $end_annot{$_}),
	   members($assoc->{'connection'})
	   )
       ) . ';'
}



sub AssociationEnd_asString
{
  my ($x, $end_annot) = @_;

  no warnings;

  my $p = ModelElement_name_with_id($x->{'participant'});

  sprintf("%-2s %-3s %25s : %-20s %-5s %s %s%s%s",
	  (
	   (String_toBoolean($x->{'isNavigable'}) && '->'),
	   ($x->{'aggregation'} eq 'aggregate' && "<>") ||
	   ($x->{'aggregation'} eq 'composite' && "<#>")
	   ),
	  (
	   ($x->{'visibility'} eq 'public'    && '+') ||
	   ($x->{'visibility'} eq 'private'   && '-') ||
	   ($x->{'visibility'} eq 'protected' && '#') ||
	   ($x->{'visibility'} eq 'package'   && '~') ||
	                                         ' '
	   ) .
	  ($x->{'name'} || '""'),
	  $p,
	  Multiplicity_asString($x->{'multiplicity'}),
	  ($x->{'ordering'} eq 'ordered' && " {ordered}"),
	  ($x->{'_phantom'} && " {phantom}"),
	  ($x->{'_trace'} && " <<trace>> --> " . $x->{'_trace'}{'name'}),
	  " /*$x->{_id}*/ $end_annot",
	  );
}


sub Attribute_asString
{
  my ($x) = @_;

  no warnings;
  my $p = ModelElement_name_with_id($x->{'type'});

  my $m = Multiplicity_asString($x->{'multiplicity'});

  my $iV = $x->{'initialValue'};
  if ( ref($iV) ) {
    $iV = $iV->{'body'} . "/* $iV->{language} */";
  }

  sprintf("      %25s %-30s\n",
	  '',
	  "/* Attribute $x->{_id} */",
	  ) .
  sprintf("  %25s : %-20s %-7s%s;%s",
	  (
	   ($x->{'visibility'} eq 'public'    && '+') ||
	   ($x->{'visibility'} eq 'private'   && '-') ||
	   ($x->{'visibility'} eq 'protected' && '#') ||
	   ($x->{'visibility'} eq 'package'   && '%') ||
	   ' '
	   ) .
	  ($x->{'name'} || '""'),
	  $p,
	  $m ne '1' ? "[$m]" : '',
	  (defined $iV ? ' = ' . $iV : ''),
	  ($x->{'_trace'} && ("/* <<trace>> --> " . $x->{'_trace'}{'name'} . " */")),
	  );
}



#######################################################################


sub ModelElement_taggedValue_name_array
{
  my ($node, $name, $default) = @_;

  $DB::single = 1 unless ref($node);

  #$DB::single = 1 if ( ModelElement_name_qualified($node) =~ /sonema/ );

  return +() unless $node->can('taggedValue');

  my @x = grep($_->type->name eq $name, $node->taggedValue);

  #local $" = ', '; print STDERR "ME_tV_n ", scalar ModelElement_name_qualified($node), " $name => @x \n";

  @x ? @x : ( defined $default ? +( $default ) : () );
}


sub ModelElement_taggedValue_name
{
  my ($node, $name, $default) = @_;

  my @x = ModelElement_taggedValue_name_array($node, $name);

  # This assumes that everybody wants dataValue as a string,
  # instead of the String[*] its specified as in the UML 1.5 Spec.
  @x ? join('', $x[0]->dataValue) : $default;
}


sub ModelElement_taggedValue_name_true
{
  String_toBoolean(ModelElement_taggedValue_name(@_));
}



sub ModelElement_taggedValue_inheritsFrom
{
  my ($node) = @_;

  # Traverse up containment.
  #
  # Many XMI models do not specify namespaces for
  # Features (Attributes), so use the Feature's owner
  # for taggedValue inheritance.
  #
  if ( $node->isaFeature ) {
    $node = $node->owner;
  } else {
    $node = $node->namespace;
  }
  
  $node;
}


my $hiddenDefault = [ ];
sub ModelElement_taggedValue_inherited
{
  my ($node, $name, $default) = @_;

  # print STDERR "ME_tV_i ", scalar ModelElement_name_qualified($node), " $name =>\n";

  while ( $node ) {
    my $x = ModelElement_taggedValue_name($node, $name, $hiddenDefault);
    if ( $x ne $hiddenDefault ) {
      $default = $x;
      last;
    }

    $node = ModelElement_taggedValue_inheritsFrom($node);
  }

  # print STDERR "  '$default'\n";

  $default;
}


sub ModelElement_taggedValue_inherited_true
{
  String_toBoolean(ModelElement_taggedValue_inherited(@_));
}


sub ModelElement_taggedValue_trace
{
  ModelElement_taggedValue_inherited(@_);
}


sub ModelElement_set_taggedValue_name
{
  my ($node, $name, $value, $factory) = @_;

  my @x = grep($_->type->name eq $name, $node->taggedValue);

  if ( @x ) {
    grep($_->set_dataValue($value), @x);
  } else {
    my $td = TagDefinition_for_name($node, $name, $factory);

    my $tv = $factory->create('TaggedValue',
			      'type' => $td,
			      'dataValue' => [ $value ],
			      );

    $node->add_taggedValue($tv);
  }

  $node
}


sub TagDefinition_for_name
{
  my ($node, $name, $factory, $multiplicity) = @_;

  my $model = $node && ModelElement_namespace_root($node);
  my $td;

  ($td) = grep($_->isaTagDefinition && $_->name eq $name, $model->ownedElement)
  if $model;
  
  unless ( $td ) {
    $multiplicity ||= '1';

    $td = $factory->create('TagDefinition', 
			   'name' => $name,
			   'multiplicity' => Multiplicity_fromString($multiplicity, $factory),
			   'tagType' => '',
			   );

    $model->add_ownedElement($td) if $model;
  }

  $td;
}



#######################################################################

=head2 Class_Association_Attribute

Returns a list of new Attribute objects that are a typical representation
of opposite AssociationEnds in a Class.

=cut
sub Class_Association_Attribute
{
  my ($cls, $factory) = @_;

  $factory ||= $cls->__factory;

  my @attr;

  for my $cls_end ( $cls->association ) {
    for my $end ( AssociationEnd_opposite($cls_end) ) {
      my $name  = $end->name; # IMPLEMENT: naming.
      next unless $name;
      next unless $end->isNavigable eq 'true';
      my $multi = $end->multiplicity;
      my $type  = $end->participant;
      my $targetScope = $cls_end->targetScope;
      my $ordering = $end->ordering;
      my $visibility = $end->visibility;
      
      my $attr = $factory->create('Attribute',
				  # 'owner' => $cls,
				  'name' => $name,
				  'type' => $type,
				  'multiplicity' => $multi,
				  'targetScope' => $targetScope,
				  'ordering' => $ordering,
				  'visibility' => $visibility,
				  );

      # IMPLEMENT: Add trace

      push(@attr, $attr);
				  
    }
  }

  wantarray ? @attr : \@attr;
}

#######################################################################

=head2 AssociationClass_Attribute

Returns a list of new Attribute objects that are a typical representation
of the AssociationEnds in a AssociationClass.

=cut
sub AssociationClass_Attribute
{
  my ($cls, $factory) = @_;

  $factory ||= $cls->__factory;

  my @attr;

  for my $end ( $cls->connection ) {
    my $name  = $end->name; # IMPLEMENT: naming.
    next unless $name;
    next unless $end->isNavigable eq 'true';
    my $multi = $end->multiplicity;
    my $type  = $end->participant;
    my $targetScope = 'instance';
    my $ordering = $end->ordering;
    my $visibility = $end->visibility;
    
    my $attr = $factory->create('Attribute',
				# 'owner' => $cls,
				'name' => $name,
				'type' => $type,
				'multiplicity' => $multi,
				'targetScope' => $targetScope,
				'ordering' => $ordering,
				'visibility' => $visibility,
				);
    
    # IMPLEMENT: Add trace
    
    push(@attr, $attr);
  }

  wantarray ? @attr : \@attr;
}


#######################################################################

sub Model_clone
{
  my ($node, $map, $map_) = @_;

  $map ||= { };

  my $ref = ref($node);

  return $node unless $ref;
  return [ map(Model_clone($_, $map, $map_), @$node) ] if $ref eq 'ARRAY';
  return { map(Model_clone($_, $map, $map_), %$node) } if $ref eq 'HASH'; 

  my $node_x = $map->{$node};
  return $node_x if $node_x;
  
  $map->{$node} = $node_x = bless({ %$node }, $ref);
  $map_->{$node_x} = $node if $map_;

  for my $key ( keys %$node_x ) {
    my $v = \{$node_x->{$key}};
    $$v = Model_clone($$v, $map, $map_);
  }
  
  $node_x;
}


sub Attribute_clone
{
  my ($node) = @_;

  $node = $node->__clone;

  $node->{'owner'} = undef;

  $node;
}


sub Operation_clone
{
  my ($node) = @_;

  $node = $node->__clone;

  $node->{'owner'} = undef;

  my @x = map($_->__clone, $node->parameter);
  grep($_->{'parameter_'} = undef, @x);
  $node->{'parameter'} = [ ];
  $node->set_parameter(@x);

  $node;
}



sub Association_clone
{
  my ($node) = @_;

  confess("undef") unless $node;

  $node = $node->__clone;

  # Make new AssociationEnds.
  # $DB::single = 1;
  my @x = map($_->__clone, $node->connection);
  grep($_->{'connection_'} = undef, @x);
  $node->{'connection'} = [ ];
  $node->set_connection(@x);

  $node;
}


#######################################################################


sub Model_destroy
{
  my ($x) = @_;

  my $ref = ref($x);

  return unless $ref;

  my @x;

  if ( $ref =~ /ARRAY/ ) {
    @x = @$x;
    @$ref = ();
  }
  elsif ( $ref =~ /HASH/ ) {
    @x = @$x;
    %$ref = ();
  }
  elsif ( $ref =~ /SCALAR/ ) {
    $$ref = undef;
  }

  grep(Model_destroy($_), @x);
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


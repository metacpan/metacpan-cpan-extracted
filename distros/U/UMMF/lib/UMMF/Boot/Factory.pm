package UMMF::Boot::Factory;

use 5.6.0;
use strict;
#use warnings;

our $AUTHOR = q{ kstephens@users.sourceforge.net 2003/05/06 };
our $VERSION = do { my @r = (q$Revision: 1.18 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::Boot::Factory - Bootstrapping factory

=head1 SYNOPSIS

=head1 DESCRIPTION

This module is used to create a bootstrapping UML meta-meta-model from
the meta-model description.

=head1 USAGE

=head1 EXPORT

None exported.

=head1 AUTHOR

Kurt Stephens, kstephens@users.sourceforge.net 2003/05/06

=head1 SEE ALSO

L<UMMF::Core::Builder|UMMF::Core::Builder>

=head1 VERSION

$Revision: 1.18 $

=head1 METHODS

=cut


#######################################################################

use base qw(UMMF::Core::Factory);

#######################################################################

use UMMF::Core::Util qw(:all);

use Carp qw(confess);

#######################################################################

sub initialize
{
  my ($self) = @_;
  
  $self->{'classMap'} ||= 1;

  $self->SUPER::initialize;

  $self->{'packagePrefix'} ||= 'UMMF::Boot';

  $UMMF::Boot::Factory::Object::_id = 0;

  $self;
}


#######################################################################


my @cls;
my %cls;
my %attr;
my @assoc;
my $__cls_supers;
my $__cls_method = { };
my $__cls_method_patch;

my $base_package = __PACKAGE__ . '::Object';

my @obj;
our @factory_map;
our $model;


sub model
{
  confess("no model") unless $model;
  $model;
}

sub factory_map
{
  confess("no model") unless @factory_map;
  \@factory_map;
}


sub factory
{
  UMMF::UML::MetaMetaModel::FactoryBoot::Object->__factory;
}


sub __true { 1 }


sub create
{
  my ($self, $meta, @args) = @_;

  # $DB::single = 1;

  # Translate meta name to fully-qualified name, if possible.
  my $meta_q = $meta;
  my $meta_cls = $cls{$meta};
  if ( $meta_cls ) {
    # $DB::single = 1;
    $meta_q = $meta_cls->{'.name_q'};
  }

  # Construct an object.
  my $obj = $base_package->new
  (
   '.className' => $meta_q,
   '.class' => $meta_cls,
   ".isa$meta" => 1,
   @args,
   );
  
  # Bless it into some package.
  {
    # If we have a meta Classifier object,
    # use it, otherwise punt until later.
    my $cls = $cls{$meta_q} || $cls{$meta};
    $cls = $cls && $cls->{'.package'};
    $cls ||= $base_package;
    
    bless($obj, $cls);
  }


  # Get a fully qualified name for the object.
  my ($name, $name_q);
  if ( $obj->{'name'} ) {
    my @pkg;
    my $ns = $obj;
    while ( $ns->{'namespace'} ) {
      push(@pkg, $ns->{'name'});
      $ns = $ns->{'namespace'};
    }
    @pkg = reverse @pkg;
    $name = $obj->{'name'};
    $name_q = join('::', @pkg);
    $obj->{'.name_q'} = $name_q;
  }


  #####################################################################
  ## Initialization
  ##
  ## All of these initializers are hand-coded.
  ## This should cover all the
  ## the objects generated by UMMF::UML::Import::MetaMetaModel.
  ##
  ## They are arranged in Generalization parent pre-order so
  ## things like namespace can get set up by subclasses
  ## before the Namespace initializer.
  ##
  ## If anything major changes in MetaModel.spec,
  ## esp. in the Foundation package,
  ## This code might be broken.
  ##
  my $x;

  # die("Attribute 2561!!!\n") if $obj->{'_id'} eq 2561;

  # Multiplicity
  if ( grep($meta eq $_, 'Multiplicity') ) {
    $obj->{'range'} ||= [ ];
  }

  # EnumerationLiteral
  if ( grep($meta eq $_, 'EnumerationLiteral') ) {
    __many_one($obj, 'literal', 'enumeration');
    $obj->{'namespace'} ||= $obj->{'enumeration'};
    # $DB::single = 1;
  }

  # Enumeration
  if ( grep($meta eq $_, 'Enumeration') ) {
    __one_many($obj, 'enumeration', 'literal');
    grep($_->{'namespace'} = $obj, @{$obj->{'literal'}});
  }

  # AssociationEnd
  if ( $meta eq 'AssociationEnd' ) {
    __many_one($obj, 'association', 'participant');
    __many_one($obj, 'connection', '_association'); # HACK!!!!
  }

  # Association
  if ( grep($meta eq $_, 'Association', 'AssociationClass') ) {
    $obj->{'.isaAssociation'} = 1;
    __one_many($obj, '_association', 'connection'); # HACK!!!!

    my $x = $obj->{'connection'};
    if ( 0 &&
	 grep($_->{'name'} eq 'connection', @$x) &&
	 grep($_->{'name'} eq '_association', @$x) && 1 ) {
      $DB::single = 1;
    }

    push(@assoc, $obj);
  }
  
  # StructuralFeature
  if ( grep($meta eq $_, 'Attribute') ) {
    $obj->{'.isaStructuralFeature'} = 1;
    __many_one($obj, 'typedFeature', 'type');

    $attr{$obj->{'owner'}}{$obj->{'name'}} = $obj;
    $obj->{'namespace'} ||= $obj->{'owner'};
  }

  # Feature
  if ( grep($meta eq $_, 'Attribute') ) {
    $obj->{'.isaFeature'} = 1;
    __many_one($obj, 'feature', 'owner');
  }

  # Class
  if ( grep($meta eq $_, 'Class', 'AssociationClass') ) {
    $obj->{'.isaClass'} = 1;
  }

  # Model
  if ( grep($meta eq $_, 'Model') ) {
    $obj->{'.isaModel'} = 1;
    $model ||= $obj;
  }  

  # Package
  if ( grep($meta eq $_, 'Model', 'Package') ) {
    $obj->{'.isaPackage'} = 1;
    $obj->{'importedElement'} ||= [ ];
  }

  # Namespace
  if ( grep($meta eq $_, 'Model', 'Package', 'Class', 'AssociationClass', 'Enumeration', 'Primitive') ) {
    $obj->{'.isaNamespace'} = 1;
    __one_many($obj, 'namespace', 'ownedElement');

    my $package = join("::", 
			      grep(length($_),
				   $self->{'packagePrefix'},
				   $name_q,
				   )
			      );
    # Remember the Classifier's Perl package.
    # $DB::single = 1;
    $obj->{'.package'} = $package;

    # Make a package to bless into.
    # Make the package bounce up to the $base_package.
    eval qq{
      package $package;
      our \@ISA = qw($base_package);
      our \$VERSION = '3.1415926';

      sub __model_name { '$name_q' }

    }; die $@ if $@;

    # Patch in the classifier, so UMMF::UML::Export::XMI will work.
    {
      no strict 'refs';

      *{"${package}::__classifier"} = sub { $obj; }; 

      *{"${package}::isa$name"} = \&__true;

      my $name_ = $name_q;
      $name_ =~ s/::/__/sg;
      *{"${package}::isa$name_"} = \&__true;
    }

    # Add to factory map.
    push(@factory_map,
	 $name, $package,
	 $name_q, $package,
	 );
	 
  }

  # Classifier
  if ( grep($meta eq $_, 'Class', 'AssociationClass', 'Enumeration', 'Primitive') ) {
    $obj->{'.isaClassifier'} = 1;
    __one_many($obj, 'owner', 'feature');
    __one_many($obj, 'particpant', 'association');

    confess("Class name collision '$name_q'") if $cls{$name_q};

    if ( my $other = $cls{$name} ) {
      my $other_name_q = $other->{'.name_q'};
      warn("short Class name collision '$name' between '$other_name_q' and '$name_q'");
    }

    push(@cls, $obj);
    $cls{$name_q} = $obj;
    $cls{$name} ||= $obj;
  }

  # Generalization
  if ( grep($meta eq $_, 'Generalization') ) {
    $obj->{'.isaGeneralization'} = 1;
    __many_one($obj, 'generalization', 'child');
    __many_one($obj, 'specialization', 'parent');
  }

  # Dependency
  if ( grep($meta eq $_, 'Usage') ) {
    $obj->{'.isaDependency'} = 1;
    __one_many($obj, 'supplier', 'supplierDependency');
    __one_many($obj, 'client', 'clientDependency');
  }

  # Relationship
  if ( grep($meta eq $_, 'Generalization', 'Usage') ) {
    $obj->{'.isaRelationship'} = 1;
  }

  # GeneralizableElement
  if ( grep($meta eq $_, 'Model', 'Package', 'Class', 'AssociationClass', 'Enumeration', 'Primitive') ) {
    $obj->{'.isaGeneralizableElement'} = 1;
    __one_many($obj, 'child', 'generalization');
    __one_many($obj, 'parent', 'specialization');
  }

  # ModelElement
  if ( 1 ) {
    $obj->{'.isaModelElement'} = 1;
    __many_one($obj, 'ownedElement', 'namespace');
  }
  
  # Element
  if ( 1 ) {
    $obj->{'.isaElement'} = 1;
  }

  if ( 0 && $obj->{'.isaAssociationClass'} ) {
    print STDERR "$meta_q $obj->{name} {\n\t";
    print STDERR join("\n\t", map("$_ = " . $obj->{$_}, sort keys %$obj));
    print STDERR "\n} = $obj\n";
    
    # $DB::single = 1;
    #$DB::single = 1 if $meta eq 'Generalization';
    #$DB::single = 1 if $meta eq 'Attribute';
    $DB::single = 1 if $meta eq 'AssocationEnd';
  }

  # confess("FOAOSDFOSDFO") unless $obj->{'.name_q'};

  push(@obj, $obj);

  $obj;
}


sub flush
{
  my ($self, $kind) = @_;

  # $DB::single = 1;

  if ( 0 ) {
    print STDERR "========================================\n";
    print STDERR "== flush $kind\n";
  }

  if ( $kind eq 'Generalization' ) { 
    # Generalizations have all been added.
    # Now start caching in __cls_supers().
    $__cls_supers = { };

    # Backpatch @ISA.
    for my $cls ( @cls ) {
      my $pkg = $cls->{'.package'};

      my @isa = map($_->{'.package'},
		    map($_->{'parent'},
			@{$cls->{'generalization'}},
			)
		    );

      push(@isa, $base_package) unless @isa;
      # $DB::single = 1 if @isa;

      {
	no strict 'refs';
	@{"${pkg}::ISA"} = @isa;
      }
    }
  }
  elsif ( $kind eq 'Attribute' ) {
    # Attributes have all been added.
    # Now start caching accessors.
    $__cls_method = { };
  }
  elsif ( $kind eq 'Association' ) {
    # Attributes and Associations have all been added.

    for my $obj ( @assoc ) {
      # Add AssociationEnds as pseudo-Attributes.
      for my $end ( @{$obj->{'connection'}} ) {
	my $cls = $end->{'participant'};
	for my $end_x ( grep($_ ne $end, @{$obj->{'connection'}}) ) {
	  if ( $end_x->{'name'} ) {
	    # confess("FKSDFKSDLFKSD") if $end_x->{'name'} eq 'ownedElement';
	    $end_x->{'.owner'} = $cls; # So $pkg_impl will work.
	    $attr{$cls}{$end_x->{'name'}} = $end_x;
	  }
	}
      }
    }

    # Recache accessors and patch them in.
    $__cls_method = { };
    $__cls_method_patch = 1;
  }
  elsif ( $kind eq 'Model' ) {
    # Rebless into Class package.
    for my $obj ( @obj ) {
      my $cls = $cls{$obj->{'.className'}};
      $obj->{'.className'} = $cls->{'.name_q'}; # Backpatch.
      bless($obj, $cls->{'.package'});
    }
  }

  $self;
}



sub __add_if_absent
{
  my $a = $_[0] ||= [ ];
  shift;
  for my $x ( @_ ) {
    push(@$a, $x) unless grep($_ eq $x, @$a);
  }
}


sub __one_many
# $one_obj, $one_role, $many_role
{
  my ($one_obj, $one_role, $many_role) = @_;

  #local $" = ', '; print STDERR "$one_obj->{__className} $one_role 1 === $many_role *\n";
  grep($_->{$one_role} = $one_obj, @{$one_obj->{$many_role} ||= [ ]});
}


sub __many_one
# $many_obj, $many_role, $one_role
{
  my ($many_obj, $many_role, $one_role) = @_;

  my $x  = $many_obj->{$one_role};
  #local $" = ', '; print STDERR "$many_obj->{__className} $many_role * === $one_role $x";

  confess() if $x && ! ref($x);

  __add_if_absent($x->{$many_role}, $many_obj) if $x;
}



sub __cls_supers
{
  my ($cls) = @_;
  my $x = $__cls_supers && $__cls_supers->{$cls};
  unless ( $x ) {
    my @supers;
    my @x = ( $cls );
    while ( @x ) {
      my $cls = pop @x;
      next if grep($_ eq $cls, @supers);
      push(@supers, $cls);
      push(@x, map($_->{'parent'}, @{$cls->{'generalization'}}));
    }

    $x = \@supers;
    $__cls_supers->{$cls} = $x if $__cls_supers;

    if ( 0 ) {
      print STDERR "\n\n__cls_supers $cls->{name} = ", join(', ',  map($_->{'name'}, @supers)), "\n\n\n"
      if $__cls_supers;
    }
  }

  @$x;
}


sub __cls_attr
{
  my ($cls, $name) = @_;

  for my $super ( __cls_supers($cls) ) {
    my $attr = $attr{$super}{$name};
    return $attr if $attr;
  }

  confess("Unknown Attribute '$name' in Class '$cls->{name}'") if $__cls_method_patch;

  undef;
}



#######################################################################


sub __cls_method
{
  my ($self, $operation, $args) = @_;

  # Lookup Class object.
  my $cls = $self->{'.class'} ||= $cls{$self->{'.className'}};

  # Rebless into Class package?
  if ( $cls && ref($self) eq $base_package ) {
    $self->{'.className'} = $cls->{'.name_q'}; # Backpatch.
    bless($self, $cls->{'.package'});
  }

  my $pkg_impl;
  my $method = $__cls_method && $__cls_method->{$cls}{$operation};

  if ( ! $method ) {
    if ( $operation =~ /^isa([A-Z][A-Za-z_0-9]*)$/ ) {
      my $target_cls = $1;
      
      my $value = $self->{".$operation"};
      return $value if defined $value;
      
      $value = grep($_ eq $target_cls, map($_->{'name'}, __cls_supers($cls)));
      $value ||= 0;
      
      # $self->{".$operation"} = $value;
      return $value;
    }
    elsif ( $operation =~ /^add_(.*)$/ ) {
      my $a = $1;
      my $attr = $cls && __cls_attr($cls, $a);
      # $DB::single = 1;
      if ( $attr ) {
	# $DB::single = 1;

	$pkg_impl = $attr;

	unless ( $method = $attr->{'.adder'} ) {
	  if ( Multiplicity_upper($attr->{'multiplicity'}) ne '1' ) {
	    $method = sub {
	      my $self = shift;
	      my $x = $self->{$a} ||= [ ];
	      @$x = @_;
	      $self;
	    };
	  }
	  
	  $attr->{'.adder'} = $method;
	}
      } else {
	# Fall-back method.
	$method = sub {
	  my $self = shift;
	  my $x = $self->{$a};
	  
	  confess("Not a ref") if grep(! ref($_), @_);
	  
	  push(@$x, @_);
	  
	  $self;
	};
      }
    }
    elsif ( $operation =~ /^set_(.*)$/ ) {
      my $a = $1;
      my $attr = $cls && __cls_attr($cls, $a);
      if ( $attr ) {
	$pkg_impl = $attr;

	# $DB::single = 1;

	unless ( $method = $attr->{'.setter'} ) {
	  if ( Multiplicity_upper($attr->{'multiplicity'}) eq '1' ) {
	    $method = sub {
	      $_[0]->{$a} = $_[1];
	      $_[0];
	    };
	  } else {
	    $method = sub {
	      my $self = shift;
	      my $x = $self->{$a} ||= [ ];
	      @$x = @_;
	      $self;
	    };
	  }
	  
	  $attr->{'.setter'} = $method;
	}
      } else {
	# Fall-back method.
	$method = sub {
	  my $self = shift;
	  my $x = $self->{$a};
	  
	  if ( ref($x) eq 'ARRAY' ) {
	    confess("Not ref") if grep(! ref($_), @_);
	    @$x = @_;
	  } else {
	    if ( @_ > 1 ) {
	      $self->{$a} = \@_;
	    } else {
	      $self->{$a} = $_[0];
	    }
	  }
	  
	  $self;
	};
      }
    } else {
      # Getter
      my $a = $operation;
      my $attr = $cls && __cls_attr($cls, $a);
      if ( $attr ) {
	$pkg_impl = $attr;
	
	# $DB::single = 1;
	unless ( $method = $attr->{'.getter'} ) {
	  # $DB::single = 1 if $a eq 'upper';
	  if ( Multiplicity_upper($attr->{'multiplicity'}) ne '1' ) {
	    $method = sub {
	      my $x = $_[0]->{$a} ||= [ ];
	      wantarray ? @$x : $x;
	    };
	  } else {
	    $method = sub {
	      $_[0]->{$a};
	    };
	  }
	  $attr->{'.getter'} = $method;
	}
      } else {
	# Fall-back method.
	$method = sub {
	  my $x = $_[0]->{$a};
	  
	  # $DB::single = 1 if $a eq 'ownedElement' && $_[0]->{'name'} eq 'Model_Management';
	  
	  if ( wantarray ) {
	    if ( ref($x) eq 'ARRAY' ) {
	      return @$x;
	    } else {
	      if ( exists $_[0]->{$a} ) {
		return +( $x );
	      } else {
		return ();
	      }
	    }
	  } else {
	    return $x;
	  }
	};
	
      }
    }

    $__cls_method->{$cls}{$operation} = $method if $__cls_method;
  }

  if ( $method ) {
    if ( $pkg_impl && $__cls_method_patch ) {
      no strict 'refs';

      $pkg_impl = $pkg_impl->{'owner'} || $pkg_impl->{'.owner'} if ref($pkg_impl);
      $pkg_impl = $pkg_impl->{'.package'} if ref($pkg_impl);
      
      # $DB::single = 1;
      # print STDERR "Patching ${pkg_impl}->${operation}()\n";

      *{"${pkg_impl}::${operation}"} = $method;
    }

    $method->($self, @$args);
  } else {
    confess("Unknown Method '$operation' on Class '$self->{__className}'");
  }
}


#######################################################################

package UMMF::Boot::Factory::Object;


our $_id = 0;

sub new
{
  my ($self, %opts) = @_;

  $opts{'_id'} ||= ++ $_id;

  bless(\%opts, ref($self) || $self)->_initialize;
}


sub _initialize
{
  $_[0];
}


sub __clone
{
  my ($self) = @_;

  $DB::single = 1;

  $self = bless({ %$self }, ref($self));

  $self->{'_id'} .= '.' . ++ $_id;

  for my $key ( keys %$self ) {
    my $v = $self->{$key};
    if ( ref($v) eq 'ARRAY' ) {
      $self->{$key} = [ @$v ];
    } elsif ( ref($v) eq 'HASH' ) {
      $self->{$key} = { %$v };
    }
  }

  $self;
}


sub __metamodel
{
  # This is its own metamodel!
  UMMF::Boot::Factory->model;
}


sub __model
{
  $UMMF::Boot::Factory::model;
}


my $__factory;
sub __factory
{
  unless ( $__factory ) { 
    # $DB::single = 1;

    $__factory = UMMF::Core::Factory
    ->new(
	  'classMap' => UMMF::Boot::Factory->factory_map
	  );						  
  }
  $__factory;
}



our $AUTOLOAD;

sub AUTOLOAD
{
  no strict 'refs';
  
  my ($self, @args) = @_;
  local ($1, $2);
  
  my ($package, $operation) = $AUTOLOAD =~ m/^(?:(.+)::)([^:]+)$/;
  return if $operation eq 'DESTROY';
  
  UMMF::Boot::Factory::__cls_method($self, $operation, \@args);
}


#######################################################################




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


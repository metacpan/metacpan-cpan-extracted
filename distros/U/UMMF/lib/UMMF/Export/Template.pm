package UMMF::Export::Template;

use 5.6.1;
use strict;

our $AUTHOR = q{ kstephens@users.sourceforge.net 2003/04/06 };
our $VERSION = do { my @r = (q$Revision: 1.66 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::Export::Template - A code generator base class using Template Toolkit.

=head1 SYNOPSIS

  use base qw(UMMF::Export::Template);

=head1 DESCRIPTION

This package allow UML models to be processed into other forms using a template.

=head1 USAGE

Need description of template input data structure.

=head1 EXPORT

None exported.

=head1 TO DO

This entire class needs to be refactored; it has grown too large and most of the template variables are set up in a redundant manner that is dependent on the underlying meta-model.

I propose that the meta-model be used directly in all templates from now on. 

=head1 AUTHOR

Kurt Stephens, kstephens@users.sourceforge.net 2003/05/02

=head1 SEE ALSO

L<UMMF::UML::MetaModel|UMMF::UML::MetaModel>

=head1 VERSION

$Revision: 1.66 $

=head1 METHODS

=cut

#######################################################################

use base qw(UMMF::Export);

#######################################################################

use UMMF;
use UMMF::Core::Util qw( :all );
use Carp qw(confess);

use Template;
use Template::Stash;

use File::Basename;

#######################################################################


sub initialize
{
  my ($self) = @_;

  $self->SUPER::initialize;

  $self->{'defaultSuperclass'} ||= [ ];

  $self;
}


#######################################################################


sub export_Model
{
  my ($self, $model) = @_;

  $model = $self->model_filter($model);

  my $out = $self->{'output'};

  $out = '-' if $out eq *STDOUT;
  $out = '-' if $out eq \*STDOUT;

  # $Template::Parser::DEBUG = 1;

  my $vars = $self->template_vars($model);
  my $file = $self->template_file;
  my $template = $self->template;

  $file = basename($file);

  # $DB::single = 1;
  my $result = $template->process($file, $vars, $out);
  die $@ if $@;

  #$DB::single = 1;
  #$out->print($result);

  $self;
}


#######################################################################


=head2 template_file

  $self->template_file;

Returns the name of the Template to be used.

If C<$self->{'template_file'}> is not defined, defaults
to the file name C<ref($self) . '.txt'>.

=cut
sub template_file
{
  my ($self) = @_;

  my $x = \$self->{'template_file'};
  unless ( $$x ) {
    my @try;
    my $file;

    # Try file in other resource path.
    $file = ref($self) || $self;
    $file =~ s@.*::@@s;
    $file .= '.txt';
    push(@try, map("$_/$file", UMMF->resource_path('template')));

    # Try file in same directory as this module (Foo)
    # named FooTemplate.txt
    #$file = ref($self) || $self;
    #$file =~ s@::@/@sg;
    #$file .= '.pm';
    #$file = $INC{$file};
    #$file =~ s/\.pm$/Template.txt/;
    #push(@try, $file);

    # Find readable file.
    $file = undef;
    if ( $self->{'debug'} ) {
      for my $x ( @try ) { print STDERR "  try $x\n"; }
    }
    for my $x ( @try ) {
       if ( -r $x ) {
	$file = $x;
	last;
      }
    }
    unless ( $file ) {
      die("Cannot find template for " . ref($self));
    }

    # Make it absolute.
    use File::Spec;
    $file = File::Spec->rel2abs($file);
    
    print STDERR "Export: using template $file\n";

    # $DB::single = 1;
    $$x = $file;
  }

  $$x;
}


=head2 template_config

Returns the Template configuration hash.

=cut
sub template_config
{
  my ($self) = @_;

  # use Template::Constants qw( :debug );

  my $x = $self->{'template_config'} ||=
  {
      'INCLUDE_PATH'  => [ 
			  dirname($self->template_file), 
			  UMMF->resource_path('template'),
			 ],
      'INTERPOLATE'   => 0, # Do not interpolate $var
      # 'RELATIVE'      => 1,
      'POST_CHOMP'    => 1,
      # 'PRE_PROCESS' => 'header',
      'EVAL_PERL'     => 1,

      'COMPILE_EXT'   => '.ttc',
      'COMPILE_DIR'   => join('/', UMMF->tmp_dir, "$ENV{USER}.ttc"),

      # 'DEBUG'         => DEBUG_ALL, # DEBUG_PARSER | DEBUG_SERVICE | DEBUG_CONTEXT | DEBUG_PROVIDER,
  };

  {
    use File::Path;
    mkpath([ $x->{'COMPILE_DIR'} ], 1); 
  }

  $x;
}


$Template::Stash::SCALAR_OPS->{unquoted} ||= sub {
  no warnings;

  my ($x) = @_;

  $x =~ s/["']//sg;

  $x;
};
$Template::Stash::SCALAR_OPS->{asInteger} ||= sub {
  no warnings;

  my ($x) = @_;

  $x =~ s/["']//sg;
  $x =~ /^[+-]?[0-9]+$/ ? $x : '-1';
};
$Template::Stash::SCALAR_OPS->{uc} ||= sub {
  no warnings;
  uc(shift);
};
$Template::Stash::SCALAR_OPS->{lc} ||= sub {
  no warnings;
  lc(shift);
};


=head2 template

Returns a cached Template object.

=cut
sub template
{
  my ($self) = @_;
  
  my $t = $self->{'template'} ||= 
  Template->new($self->template_config) || die Template->error(), "\n";
  

  $t;
}


#######################################################################


sub object_value
{
  my ($self, $obj, $key) = @_;

  my $x = $obj->key();

  $x;
}


sub __id
{
  my ($self, $obj) = @_;

  # print STDERR "__id($obj)\n";

  # Get objects unique id.
  my $id = $obj->{'_id'};
  # Default to Perl object reference.
  unless ( $id ) {
    local $1;
    $obj =~ /[(]([^\)]+)[)]/;
    $id = $1 || $obj;
  }

  # Get name.
  my $name = $obj->{'name'};
  # Get qualified name.
  my $name_q = ModelElement_name_qualified($obj);

  # Translate non-alphanumeric characters to '_' for
  # implementation language compatibility.
  my $name_ = $name;
  $name_ =~ s/[^a-z_0-9]/_/sgi;
  my $name_q_ = $name_q;  
  $name_q_ =~ s/[^a-z_0-9]/_/sgi;
  
  # Get the object's Namespace representation.
  my $namespace = $self->__id_namespace($obj->namespace);

  # Get the names of any Stereotypes applied.
  my @stereotype = $obj->stereotype;
  for my $s ( @stereotype ) {
    $s = $s->name if ref($s);
  }
  if ( 0 && @stereotype ) {
    local $" = ', ';
    print STDERR "$obj $obj->{name} stereotype = @stereotype\n";
  }


  # Get documentation
  my $documentation = $self->config_value($obj, 'documentation');
  $documentation = '' unless defined $documentation;

  $DB::single = 1 if $documentation;

  # Documentation with each line prefixed with the implementation language's
  # comment character(s).
  my $documentation_commented = $documentation;
  my $comment_char = $self->comment_char;
  $documentation_commented =~ s/\n/\n$comment_char/sg;

  # Separate first paragraph of documentation from rest.
  my ($documentation_1, $documentation_rest) = split("\n\n", $documentation, 2);
  trim_ws_undef(\$documentation);
  trim_ws_undef(\$documentation_commented);
  trim_ws_undef(\$documentation_1);
  trim_ws_undef(\$documentation_rest);

  # $DB::single = 1 unless $name;

  my %vals = 
  (
   'obj' => $obj,

   # Unique identifiers:

   # Generated by this class.
   'id' => $id,
   # Generated by Poseidon.
   'element_uuid' => ModelElement_taggedValue_name($obj, 'element.uuid'),

   # The underlying UML metaobject class name,
   'metatype' => ref($obj),

   # Different types of names for the same metaobject.
   # Note: identifier_name_filter will translate away keywords
   # reserved by the implementation language, e.g. 'final', 'while', etc.

   # Unqualified:

   # As is.
   'name'    => $self->identifier_name_filter($obj, $name),
   # Non alphanumeric chars translated to '_'.
   'name_'   => $self->identifier_name_filter($obj, $name_),
   # First char uppercase.
   'Name'    => $self->identifier_name_filter($obj, ucfirst($name)),
   'Name_'    => $self->identifier_name_filter($obj, ucfirst($name_)),
   # All uppercase.
   'NAME'    => $self->identifier_name_filter($obj, uc($name)),
   'NAME_'    => $self->identifier_name_filter($obj, uc($name_)),
   # First char lowercase.
   'nAME'    => $self->identifier_name_filter($obj, lcfirst($name_)),
   'nAME_'   => $self->identifier_name_filter($obj, lcfirst($name_)),
   
   # Fully qualified in Namespace:

   # As is.
   'name_q_raw' => $name_q,
   'name_q'  => $self->identifier_name_filter($obj, $name_q),

   # Non alphanumeric characters translated to '_'.
   'name_q_' => $self->identifier_name_filter($obj, $name_q_),

   ($obj->isaNamespace 
    ?
    (
     'package' => $self->package_name($obj),
     'package_file' => $self->package_file_name($obj),
     
     'implementation_file' => $self->package_file_name($obj), # IMPLEMENT
     'interface_file' => $self->package_file_name($obj), # IMPLEMENT
     
     ) 
    : 
    ()
    ),

   # Give namespace data.
   'namespace' => $namespace,

   # List of Stereotypes and and hash for testing
   # if a metaobject has a Stereotype applied.
   'stereotype' => \@stereotype,
   'has_stereotype' => { map(($_ => 1), @stereotype) },

   # Template variables beginning with '_' do not work.

   # Phantom means that this metaobject, is used only
   # as a placeholder (possible in an Interface) but
   # not in implementation.
   #
   # I.e. a phantom AssociationEnd may be added to a
   # generated Interface.
   'phantom_obj' => $obj->{'_phantom'},
   'phantom' => $obj->{'_phantom'} && ($self->package_name($obj->{'_phantom'}) || $obj->{'_phantom'}),
   
   # Trace to the metaobject responsible for the creation of
   # this object during UML transformations.
   'trace_obj' => $obj->{'_trace'},
   'trace' => $obj->{'_trace'} && ($self->package_name($obj->{'_trace'}) || $obj->{'_trace'}),

   'documentation' => $documentation,
   'documentation_commented' => $documentation_commented,
   'documentation_1' => $documentation_1,
   'documentation_rest' => $documentation_rest,
     
   # If true, the template should generate implementation code
   # for this metaobject.
   'generate' => $self->config_value_inherited_true($obj, 'generate', 1),

   # If true, the template should generate implementation code
   # to store this metaobject off-line.
   'storage'              => $self->config_value_inherited_true($obj, 'storage'),
   'storage_type_impl'    => $self->config_value($obj, 'storage.type.impl'),
   'storage_type'         => $self->config_value($obj, 'storage.type'),
   'storage_type_sql'     => $self->config_value($obj, 'storage.type.sql'),
   'storage_subtype'      => $self->config_value($obj, 'storage.subtype'),
   'storage_key_type'     => $self->config_value($obj, 'storage.key.type'),
   'storage_key_sql'      => $self->config_value($obj, 'storage.key.sql'),
   'storage_value_type'   => $self->config_value($obj, 'storage.value.type'),
   'storage_value_sql'    => $self->config_value($obj, 'storage.value.sql'),
   'storage_index'        => $self->config_value($obj, 'storage.index'),
   'storage_deploy'       => $self->config_value($obj, 'storage.deploy'),
   'storage_retreat'      => $self->config_value($obj, 'storage.retreat'),
   'storage_table'        => $self->config_value($obj, 'storage.table'),
   'storage_table_filter' => $self->filter_func($self->config_value_inherited($obj, 'storage.table.filter', '')),
   'storage_name'         => $self->config_value($obj, 'storage.name'),
   'storage_aggregation'  => $self->config_value($obj, 'storage.aggregation'),
   'storage_field_id'     => $self->config_value($obj, 'storage.field.id'),
   'storage_field_class'  => $self->config_value($obj, 'storage.field.class'),
   'storage_deploy_table' => $self->config_value_inherited_true($obj, 'storage.deploy.table', 1),

   # Class/model version.
   'version' => $self->config_value_inherited($obj, 'version', '1.0'),

   # Enumerate common isa tests.
   map(($_ => $obj->$_),
       'isaClass',
       'isaAssociation',
       'isaAssociationEnd',
       'isaAssociationClass',
       'isaInterface',
       'isaEnumeration',
       'isaPrimitive',
       'isaDataType',
       'isaAttribute',
       'isaOperation',
       'isaMethod',
       'isaParameter',
       'isaPackage',
      ),
   );

  #print STDERR "$obj $obj->{name} generate=$vals{generate}\n";
  #print STDERR "__id($obj)->namepace = $namespace\n";

  %vals;
}


sub __id_namespace
{
  my ($self, $obj) = @_;

  return undef unless defined $obj;

  my $cache = $self->{'.namespace'} ||= { };

  my $x;
  unless ( $x = $cache->{$obj} ) {
    $x = $cache->{$obj} = 
      { 
       $self->__id($obj),
      };
  }

  $x;
}


sub filter_non_alphanum
{
  my ($self, $x) = @_;

  $self;
}


=head2 template_vars

Returns the template variables generated by scanning the Model.

=cut
sub template_vars
{
  my ($self, $model) = @_;

  my $v = { };

  $v->{'model'} = $model;
  $v->{'template'} = $self;
  $v->{'template_file'} = $self->template_file;


  print STDERR "\n\nPreparing template vars:\n" if $self->{'verbose'} > 0;
  # $DB::single = 1;

  $self->{'model_packagePrefix'} ||= $self->{'packagePrefix'};
  # Note: 
  # UMMF::Export::Perl::Tangram::Storage
  # relys on UML::__ObjectBase being the base class of all generated classes!
  # Need some method for importing all those methods into the $packagePrefix::__ObjectBase.pm
  #    -- ks 2005/10/16
  $self->{'model_packagePrefix'} = [ 'UML' ] 
  unless $self->{'model_packagePrefix'} && @{$self->{'model_packagePrefix'}};

  $v->{'model_package'} = $self->package_name($self->{'model_packagePrefix'});
  $v->{'model_package_'} = $self->package_name([ @{$self->{'model_packagePrefix'}}, '' ]);
  $v->{'model_package_file'} = $self->package_file_name($self->{'model_packagePrefix'});
  $v->{'model_package_dir'} = $self->package_dir_name($self->{'model_packagePrefix'});
  {
    my $ob = [ @{$self->{'model_packagePrefix'}}, '__ObjectBase' ];
    $v->{'base_package'} = $self->package_name($ob);
    $v->{'base_package_file'} = $self->package_file_name($ob);
    $v->{'base_package_dir'} = $self->package_dir_name($ob);
  }

  if ( 0 ) {
    # local $UMMF::UML::MetaMetaModel::Util::namespace_trace = 1;
    my (@ac) = Namespace_ownedElement_match($model, 'isaAssociationClass', 1);
    $DB::single = 1;
    
    print STDERR "AC: ", join(', ', map($_->name, @ac)), "\n";
  }

  my (@cls_v, %obj_v, %v_obj);
  my (@assocEnd, @assocEnd_v);
  
  $v->{'classifier'} = \@cls_v;
  $v->{'associationEnd'} = \@assocEnd_v;

  my @cls_all = Namespace_classifier($model);
  for my $cls ( @cls_all ) {
    print STDERR "Classifier $cls->{name} \t:\n" if $self->{'verbose'} > 1;
    unless ( $self->template_enabled($cls) ) {
      # print STDERR "IGNORED!\n";
      next;
    }
    #print STDERR "OK!\n";
    
    my $primitive_type = $self->config_value($cls, 'primitive.type');
    my $primitive = $self->config_value_true($cls, 'primitive', ! ! $primitive_type);

    my $x = {
      $self->__id($cls),
      
      'primitive' => $primitive,
      'primitive_type' => $primitive_type,
      
      'construct_type' => $self->config_value($cls, 'construct.type'),
      
      'validate_type' => $self->config_value($cls, 'validate.type'),
      'validate_type_type' => $self->config_value($cls, 'validate.type.type'),
      
      'construct' => $self->config_value($cls, 'construct'),
      'construct_type' => $self->config_value($cls, 'construct.type'),

      map(($_ => String_toBoolean(scalar $cls->$_())),
	  'isRoot',
	  'isLeaf',
	  'isAbstract',
	  'isSpecification',
	  ),
      
      map(($_ => $cls->$_()),
	  'visibility',
	  ),
    };

    # Trap java::lang::boolean crap.
    if ( 0 ) {
    if ( $x->{name_q} =~ /java/ && $x->{name_q} =~ /lang/ && $x->{name_q} =~ /boolean/ ) {
      print STDERR 
	"ARGGH: java.lang crap:\n", 
	Data::Dumper->new([$x], [qw($x)])
	    ->Indent(2)
	    ->Sortkeys(1)
	    ->Dump;
      # exit 1;
    }
    }
    
    #$x->{'primitive_type'} ||= $x->{'package'};
    #$x->{'construct_type'} ||= $x->{'primitive_type'};
    #$x->{'validate_type_type'} ||= $x->{'construct_type'};
    #$x->{'storage_type'} || $x->{'primitive_type'};

    push(@cls_v, $x);
    
    $obj_v{$cls} = $x;
    $v_obj{$x} = $cls;      
  }
 
  @cls_v = sort { $a->{'name_q'} cmp $b->{'name_q'} } @cls_v;

  # Initialize the factory map.
  {
    my @factory_map;
    $v->{'factory_map'} = \@factory_map;

    for my $x ( @cls_v ) {
      if ( $x->{'generate'} ) {
	my $cls_name   = $x->{'name'};
	my $cls_name_q = $x->{'name_q_raw'};
	my $pkg_name   = $x->{'package'};

	push(@factory_map,
	     $cls_name   => $pkg_name,
	     $cls_name_q => $pkg_name,
	    );
      }
    }
  }

  # Find all AssociationEnds
  for my $cls ( @cls_all ) {

    # Generate accessors for each association end point
    # where this classifier participates.
    my @x = $cls->association;
    push(@x, map(AssociationEnd_opposite($_), @x));

    for my $end ( @x ) {
      next if $obj_v{$end};
      
      print STDERR "AssociationEnd $cls->{name} :: $end->{name}\n" if $self->{'verbose'} > 1;

      my $name = $end->name;
      
      # $DB::single = 1 unless $name;

      my $type = $end->participant;
      my $multi = $end->multiplicity;
      
      my $instance = $end->targetScope ne 'classifier'; 
      
      my $x = {
	$self->__id($end),
	
	'isNavigable' => $end->isNavigable ne 'false',
	'instance' => $instance,
	
	# 'type' => $self->package_name($type, undef, $cls),
	'type' => $self->package_name($type, undef, undef),
	'type_obj' => $type,
	'type_info' => $obj_v{$type},
	'type_impl' => $self->config_value($end, 'type.impl'),

	'weak_ref_enabled' => $self->config_value_inherited_true($end, 'weak_ref_enabled'),

	'container_type' => $self->config_value($end, 'container.type'),
	'container_type_ordered' => $self->config_value_inherited($end, 'container.type.ordered'),
	'container_type_unordered' => $self->config_value_inherited($end, 'container.type.unordered'),

	'multi' => Multiplicity_asString($multi),
	'multi_lower' => Multiplicity_lower($multi),
	'multi_upper' => Multiplicity_upper($multi),
	'multi_single' => Multiplicity_upper($multi) eq '1',
	
	map(($_ => $end->$_()),
	    'visibility',
	    'ordering',
	    'aggregation',
	    'targetScope',
	    'changeability',
	    )
      };
      $x->{'weak_ref'} = $x->{'weak_ref_enabled'} && $self->config_value($end, 'weak_ref');
      
      # Cant nav if it doesn't have a name.
      $x->{'isNavigable'} = 0 unless $x->{'name'};
      

      if ( 0 && $x->{'phantom'} ) {
	my $assoc = AssociationEnd_association($end);
	print STDERR "\nPHANTOM: $cls->{name}\t : $end \n", Association_asString($assoc), "\n";
      }

      # Remember it.
      push(@assocEnd, $end);
      push(@assocEnd_v, $x);

      $obj_v{$end} = $x;
      $v_obj{$x} = $end;

      print STDERR "AssociationEnd $cls->{name} :: $end->{name}\t: DONE\n" if $self->{'verbose'} > 1;
    }
  }

  @assocEnd = sort { $a->{'name'} cmp $b->{'name'} } @assocEnd;
  @assocEnd_v = sort { $a->{'name'} cmp $b->{'name'} } @assocEnd_v;

  # print STDERR "assocs: ", join(",\n ", sort keys %assoc_v), "\n";

  # Add opposites to each End.
  for my $end ( @assocEnd ) {
    my $xx = \%obj_v; # Bug in perl parser?!?!

    # The association relationship with the AssociationEnds
    # on the other side must be maintained.
    my @x = AssociationEnd_opposite($end);
    @x =
    map(
	$xx->{$_} || confess("No assoc_v for '$_->{name}' ($_)"), 
	@x,
	);

    # @x = sort { $a->{'name'} cmp $b->{'name'} } @x;

    my $v = $obj_v{$end};
    $v->{'opposite'} = \@x;
    $v->{'opposites'} = scalar @x;
  }

  # Create Association.
  {
    my @assoc_v;

    for my $end ( @assocEnd ) {
      my $assoc = AssociationEnd_association($end) || confess("No Association for $end");
      my $x = $obj_v{$assoc};
      
      unless ( $x ) {
	$x = {
	      $self->__id($assoc),
	      
	      'connection' => [ map($obj_v{$_} || die(), $assoc->connection) ],
	     };
	# Give each AssociationEnd a relative position in the Association connection.
	my $i = -1;
	for my $c ( @{$x->{'connection'}} ) {
	  $c->{'i'} = ++ $i;
	}

	push(@assoc_v, $x);
	$obj_v{$assoc} = $x;
      }

      # Add links from end to the assoc.
      my $end_v = $obj_v{$end} || die();
      $end_v->{'assoc'} = $x;
    }

    @assoc_v = sort { $a->{'name'} cmp $b->{'name'} } @assoc_v;

    $v->{'association'} = \@assoc_v;
    $v->{'associations'} = scalar @assoc_v;
  }

  # Find all Operations
  for my $cls ( @cls_all ) {
    my $cls_v = $obj_v{$cls};

    # Operation
    my @op;
    $cls_v->{'operation'} = \@op;
    
    for my $op ( $self->operation($cls) ) {
      next if $obj_v{$op};

      print STDERR "Operation $cls->{name} :: $op->{name}\t:\n" if $self->{'verbose'} > 1;
      unless ( $self->template_enabled($op) ) {
	# print STDERR "IGNORED!\n";
	next;
      }
	       
      my $return_param = Operation_return($op);
      # Make the Operation's type the "return" params type.
      my $type = $return_param->type || confess("Class " . $cls->name . ", Method " . $op->name . ", return Parameter " . $return_param->name . " has no type");
      my $type_v = $obj_v{$type} || confess("Class " . $cls->name . ", Method " . $op->name . ", return Parameter " . $return_param->name . " cannot be mapped");
      my $type_name = $type ? $self->package_name($type, undef, $cls) : 'void';
      
      my @param;

      # $DB::single = 1;	
      my $op_v = {
	$self->__id($op),
	
	'type' => $type_name,
	'type_info' => $type_v,
	'type_impl' => $self->config_value($return_param, 'type.impl'),
	
	'instance' => $op->ownerScope ne 'classifier',
	
	'parameter' => \@param,
	
	map(($_ => $op->$_()),
	    'visibility',
	    'ownerScope',
	    'isQuery',
	    ),
      };

      # IS THIS CORRECT? -- 2004/09/29
      $op_v->{'type_impl'} ||= 
	$obj_v{$type}{'primitive_type'} || 
	$op_v->{'type'};
      
      # Trap java::lang::boolean crap.
      if ( 1 ) {
	if ( $op_v->{type_impl} =~ /java.*lang.*boolean/i ) {
	  print STDERR 
	    "ARGGH: java.lang crap:\n", 
	      Data::Dumper->new([$op_v], [qw($op_v)])
		  ->Indent(1)
		  ->Sortkeys(1)
		  ->Dump;
	  exit 1;
	}
      }

      # print STDERR "  visibility = '$op_v->{visibility}'\n";
      # print STDERR "  ownerScope = '$op_v->{ownerScope}'\n";

      push(@op, $op_v);
      
      # Do Parameters that are not the return Parameter.
      for my $param ( $op->parameter ) {
	next if $param->name eq 'return';
	
	my $type = $param->type || confess("Class " . $cls->name . ", Method " . $op->name . ", Parameter " . $param->name . " has no type");
	my $type_name = $self->package_name($type, undef, $cls);

	my $defaultValue = $self->get_Expression_body($param, $param, 'defaultValue');

	my $param_v = { 
	  $self->__id($param),

	  'type' => $type_name,
	  'type_info' => $obj_v{$type},
	  'type_impl' => $self->config_value($param, 'type.impl'),
	  
	  'defaultValue_defined' => defined $defaultValue,
	  'defaultValue' => $defaultValue,
	  'kind' => $param->kind,
	};

	# IS THIS CORRECT? -- 2004/09/29
	$param_v->{'type_impl'} ||= 
	$obj_v{$type}{'primitive_type'} || 
	$param_v->{'type'};

	# OLD CODE.
	$param_v->{'type_impl'} ||= $param_v->{'type'};
	$param_v->{'type_primitive'} ||= 
	  $obj_v{$type}{'primitive_type'} || $param_v->{'type_impl'};
	
	push(@param, $param_v);
      }
      
      $op_v->{'parameters'} = scalar @param;
      
      $obj_v{$op} = $op_v;
      $v_obj{$op_v} = $op;
    }
    
    $cls_v->{'operations'} = scalar @op;
  }


  # Internals in each class.
  for my $cls_v ( @cls_v ) {
    my $cls = $v_obj{$cls_v};

    # Dependencies
    {
      my @dep;
      $cls_v->{'dependency'} = \@dep;
      
      for my $sup ( map($_->supplier,
			$cls->clientDependency,
			)
		    ) {
  	my $sup_v = $obj_v{$sup};
	push(@dep, $sup_v) if $sup_v;

	# print STDERR "Classifier $cls->{name} Dependency -=-=-> $sup->{name}\n";
	
      }

      $cls_v->{'dependencys'} = scalar @dep;
    }

    # Usages
    {
      my @usage;
      $cls_v->{'usage'} = \@usage;

      for my $cls ( map($_->supplier,
			grep($_->isaUsage,
			     $cls->clientDependency,
			     )
                        )
                    ) {
        my $usage_v = $obj_v{$cls};
        push(@usage, $usage_v->{'package'});

      }

      # $DB::single = 1 if $cls->name eq 'Time';
      my $usage = $self->config_value($cls, 'usage', '');
      push(@usage, split(/\s*[,;]\s*|\s+/, $usage));
      @usage = sort unique(@usage);

      $cls_v->{'usages'} = scalar @usage;
    }
    
    # Imports
    # Poseidon uses TaggedValues for JavaImportStatement.
    {
      my @import;
      $cls_v->{'import'} = \@import;

      # Poseidon-specific.
      my $JavaImportStatement = ModelElement_taggedValue_name($cls, 'JavaImportStatement', '');
      @import = split(/\s*:\s*/, $JavaImportStatement);

      # Editor-inspecific.
      # Handle translation of import UML names to impl package names.
      my $import = $self->config_value($cls, 'import', '');
      my @x = split(/\s*[;,]\s*/, $import);
      @x = map(eval { Namespace_ownedElement_name($cls, $_) } || $_, @x);
      @x = map(($obj_v{$_} && $obj_v{$_}{'package'}) || $_, @x);
      push(@import, @x);

      $cls_v->{'imports'} = scalar @import;
    }
    
    # Header/Footer
    {
      # Editor-inspecific.
      my $header = $self->config_value($cls, 'header', '');
      $cls_v->{'header'} = $header;

      my $footer = $self->config_value($cls, 'footer', '');
      $cls_v->{'footer'} = $footer;
    }
    
     # Generalizations
    {
      my @exports;
      $cls_v->{'exports'} = \@exports;
      
      my @x = map($_->parent,
		  grep(defined, $cls->generalization),
		  );
      $cls_v->{'generalization'} = \@x;
      $cls_v->{'generalizations'} = scalar @x;
      

      ###############################################
      # Get all generalizations
      #

      my @gen_all = map($obj_v{$_}, GeneralizableElement_generalization_parent_all($cls));
      @gen_all = reverse @gen_all;
      $cls_v->{'generalization_all'} = \@gen_all;
      $cls_v->{'generalization_alls'} = scalar @gen_all;
      
      
      my @supers = (
		    map($self->package_name($_),
			@x,
			)
		    );
      $cls_v->{'supers'} = \@supers;
      
      # If no supers are specified be sure to use the base package.
      $cls_v->{'supers_default'} =
      [
       @supers ? () :
       (
	$v->{'base_package'},
	@{$self->{'defaultSuperclass'}},
	)
       ];
      
      for my $x ( @x ) {
	$x = $obj_v{$x};
      }
      #local $" = ', '; print STDERR "*** $cls->{name} supers [@supers]\n";
    }
    
    # Abstractions
    {
      my @abstraction;
      $cls_v->{'abstraction'} = \@abstraction;
      
      @abstraction = map($_->supplier, 
			grep($_->isaAbstraction,
			     grep(defined $_,
				  $cls->clientDependency
				  )
			     )
			);
      for my $x ( @abstraction ) {
	$x = $obj_v{$x};
      }

      $cls_v->{'abstractions'} = scalar @abstraction;
    }
 

    # EnumerationLiteral
    {
      my @literal;
      $cls_v->{'literal'} = \@literal;
      
      # Generate accessors for each association end point
      # where this classifier participates.
      if ( $cls->isaEnumeration ) {
	# $DB::single = 1;

	for my $literal ( $cls->literal ) {
	  my $name = $literal->name;
	  
	  my $literal_v = {
	    $self->__id($literal),
	  };

	  push(@literal, $literal_v);
	}
      }
    }

    # Attributes
    {
      my @attr;
      $cls_v->{'attribute'} = \@attr;
      
      # $DB::single = 1;
      
      for my $attr ( $self->attribute($cls) ) {
	
	print STDERR "Attribute $cls->{name} :: $attr->{name}\t:\n" if $self->{'verbose'} > 1;
	unless ( $self->template_enabled($attr) ) {
	  # print STDERR "IGNORED!\n";
	  next;
	}
	#print STDERR "OK\n";
	
	my $name = $attr->name;
	
	my $type = $attr->type;
	my $multi = $attr->multiplicity;
	
	# $DB::single = 1 if $name eq 'SUNDAY';

	my $initialValue = $self->get_Expression_body($attr, $attr, 'initialValue');

	my $accessor = sub { $self->config_value_inherited_true($attr, 'accessor', 'true'); };
	my $getter = $self->config_value_inherited_true($attr, 'accessor.getter', $accessor);
	my $setter = $self->config_value_inherited_true($attr, 'accessor.setter', $accessor);

	# $DB::single = 1;	
	my $attr_v = {
	  $self->__id($attr),

	  'type' => $self->package_name($type, undef, $cls),
	  'type_info' => $obj_v{$type},
	  'type_impl' => $self->config_value($attr, 'type.impl'),

	  'weak_ref_enabled' => $self->config_value_inherited_true($attr, 'weak_ref.enabled'),
		      
	  'container_type' => $self->config_value($attr, 'container.type'),
	  'container_type_ordered' => $self->config_value_inherited($attr, 'container.type.ordered'),
	  'container_type_unordered' => $self->config_value_inherited($attr, 'container.type.unordered'),

	  'multi'        => Multiplicity_asString($multi),
	  'multi_lower'  => Multiplicity_lower($multi),
	  'multi_upper'  => Multiplicity_upper($multi),
	  'multi_single' => Multiplicity_upper($multi) eq '1',
	  
	  'initialValue' => $initialValue,
	  'initialValue_defined' => defined $initialValue,
	  
	  'instance' => $attr->ownerScope ne 'classifier',

	  'getter' => $getter,
	  'getter_before' => $self->config_value($attr, 'accessor.getter.before'),
	  'getter_after'  => $self->config_value($attr, 'accessor.getter.after' ),

	  'setter' => $setter,
	  'setter_before' => $self->config_value($attr, 'accessor.setter.before'),
	  'setter_after'  => $self->config_value($attr, 'accessor.setter.after' ),
	       
	  map(($_ => $attr->$_()),
	      'visibility',
	      'ownerScope',
	      'changeability',
	      'targetScope',
	      'ordering',
	      ),
	};
	$attr_v->{'weak_ref'} = $attr_v->{'weak_ref_enabled'} && $self->config_value($attr, 'weak_ref');
	
	$attr_v->{'type_impl'} ||= 
	$obj_v{$type}{'primitive_type'} || 
	$attr_v->{'type'};

	$attr_v->{'storage_type'} ||= 
	$obj_v{$type}{'storage_type'}
	  ;

	# print STDERR "$cls_v->{package}::$attr_v->{name} storage_type = $attr_v->{storage_type}\n";

	if ( 0 && $attr_v->{'name'} eq 'time' ) {
	  print STDERR "****************************************\n";
	  print STDERR join(",\n", 
			    map("$_ = " . $attr_v->{$_},
				sort keys %$attr_v,
				)
			    ), "\n";
	}

	push(@attr, $attr_v);
      }

      $cls_v->{'attributes'} = scalar @attr;
    }

    # Classifer participant <--> association AssociationEnd
    {
      my @assocEnd = map($obj_v{$_}, $cls->association);

      # Remap end.type in relation to the cls.
      my %end_map;
      for my $cls_end ( @assocEnd ) {
        $cls_end = $end_map{$cls_end} ||= { %$cls_end };
        for my $x ( @{$cls_end->{'opposite'}} ) {
	  $x = $end_map{$x} ||= { %$x };

	  my $type = $x->{'type_obj'};

	  # Get the type name in the context of the class.
	  my $new_type = $self->package_name($type, undef, $cls);
	  if ( 0 && $new_type ne $x->{'type'} ) {
	    print STDERR "Export: Class $cls_v->{name_q}: AssociationEnd $x->{name}: type: $x->{type} => $new_type\n";
	  }
	  $x->{'type'} = $new_type;

	  # IS THIS CORRECT? -- 2004/09/29
	  if ( 1 ) {
	    $x->{'type_impl'} ||= 
	      $obj_v{$type}{'primitive_type'} || 
	      $x->{'type'};
	  } else {
	    $x->{'type_impl'} ||= $x->{'type'};
	  }
	  $x->{'type_primitive'} ||= 
	    $obj_v{$type}{'primitive_type'} || $x->{'type_impl'};
	  
	  $x->{'storage_type'} ||= 
	    $obj_v{$type}{'storage_type'};

	  # Trap java::lang::boolean crap.
	  if ( 0 ) {
	    if ( $x->{type_impl} !~ /[^a-z0-9_]/i ) {
	      print STDERR 
		"ARGGH: java.lang crap:\n", 
		  Data::Dumper->new([$x], [qw($x)])
		      ->Indent(1)
			->Sortkeys(1)
			  ->Dump;
	      exit 1;
	    }
	  }
	  
        }
      }

      @assocEnd = sort { ($a->{'opposite'}[0]{'name'} || $a->{'name'}) 
			 cmp 
			 ($b->{'opposite'}[0]{'name'} || $b->{'name'})
		       } @assocEnd;
      $cls_v->{'association'} = \@assocEnd;
      $cls_v->{'associations'} = scalar @assocEnd;
    }

    if ( 0 && grep($cls_v->{'name'} eq $_, 'Namespace', 'ModelElement') ) {
      use Data::Dumper;
      print STDERR Data::Dumper->new([ $cls_v ], [ $cls_v->{name} ])
	->Maxdepth(5)
	  ->Dump();
      $DB::single = 1;
    }


    # Method
    {
      my @meth;
      $cls_v->{'method'} = \@meth;
      
      $cls_v->{'default_constructor'} = undef;
      
      for my $meth ( $self->method($cls) ) {
	
	# Get the Method's specification (Operation).
	my $op = $meth->specification;
	my $op_v = $obj_v{$op};

	print STDERR "Method $cls->{name} :: $op->{name}\t:\n" if $self->{'verbose'} > 1;
	unless ( $self->template_enabled($meth) ) {
	  # print STDERR "IGNORED!\n";
	  next;
	}
	
	my $name = $op->name;
	
	# Get the method body for this export language type.
	my $body = $self->get_Expression_body($op, $meth, 'body');

	# $DB::single = 1;	
	my $meth_v = {
	  $self->__id($meth),

	  map(($_ => $meth->$_()),
	      # Note: ArgoUML/Poseidon does not define these;
	      # see method->specification Operation object.

	      'visibility',       
	      'ownerScope',
	      'isQuery',
	      ),
	  'instance' => $meth->ownerScope ne 'classifier',

	  'op' => $op_v,
	  'specification' => $obj_v{$op},

	  'body' => $body,
	  'body_defined' => defined $body,
	};
	
	# If the Operation is <<create>> and it has no parameters,
	# The method is the default constructor.
	if ( $op_v->{'has_stereotype'}{'create'} && @{$op_v->{'parameter'}} == 0 ) {
	  $cls_v->{'default_constructor'} = $meth_v;
	}


	# print STDERR "  visibility = '$meth_v->{visibility}'\n";
	# print STDERR "  ownerScope = '$meth_v->{ownerScope}'\n";

	push(@meth, $meth_v);
      }

      $cls_v->{'methods'} = scalar @meth;
    }
  }

  print STDERR "\n\nPreparing template vars: DONE\n" if $self->{'verbose'} > 0;

  $v;
}



#######################################################################

my %filter_func;
sub filter_func
{
  my ($self, $expr) = @_;

  my $sub_expr;
  $filter_func{$expr} ||= eval($sub_expr = 'sub { no warnings; local($_) = @_; return $_ unless defined $_; ' . $expr . ' ; $_; }') || die("$@: in expr\n: $sub_expr");
}


#######################################################################


sub get_Expression_body
{
  my ($self, $cobj, $obj, $key, $lang) = @_;

  $lang ||= $self->config_kind;

  # print STDERR "$cobj->{name} $key\n";
  #$DB::single = 1;

  # Get language-specific Expression body.
  my $lang_value = $self->get_Expression_body_1($cobj, $obj, $key, $lang);

  my $value = $lang_value;

  # Get language-inspecific Expression body if there is no language-specific
  # Expression body.
  unless ( defined $value ) {
    $value = $self->get_Expression_body_1($cobj, $obj, $key); # Any language.
  }

  # Is the Expression body
  # explicitly ok for this language?
  my $lang_ok =  $self->config_value_inherited_true($cobj, "$key.ok");
  if ( $lang_ok ) {
    return $value;
  }

  # Does the Expression body contain language-specific tagged code, like:
  #  // UMMF_LANG:java
  #    java.lang.Object foo = x.somemethod(y);
  #  # UMMF_LANG:perl
  #    my $foo = $x->somemethod($y)
  #
  # If so, pull out the code for the specified $lang.
  #
  if ( defined $value && $value =~ m@(//+|#+)\s*UMMF[_-]LANG\s*:@is ) {
    my $out = '';

    # $DB::single = 1;
    $value = "\n$value\n#UMMF_LANG\n"; # Anchor
    while ( $value =~ s@\n\s*(//+|#+)\s*UMMF[_-]LANG\s*:\s*$lang\s*\n(.*?)(\n\s*(//+|#+)\s*UMMF[_-]LANG)@$3@is ) {
      $out .= $2;
    }

    # Trim leading/trailing whitespace, make undef if it has no length.
    $value = trim_ws_undef($out);
  } else {
    # Go back to language-specific Expression body.
    $value = $lang_value;
  }

  $value;
}


sub get_Expression_body_1
{
  my ($self, $cobj, $obj, $key, $lang) = @_;

  # Try explicit config value.
  # Trim leading/trailing whitespace, make undef if it has no length.
  my $value = trim_ws_undef($self->config_value($cobj, $key));

  # Try actual Expression body for specified language.
  unless ( defined $value ) {
    $value = trim_ws_undef(Expression_body_language($obj->$key, $lang));
  }

  $value;
}


#######################################################################


sub template_enabled
{
  my ($self, $node, @args) = @_;

  1; # $self->config_enabled($node, @args);
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


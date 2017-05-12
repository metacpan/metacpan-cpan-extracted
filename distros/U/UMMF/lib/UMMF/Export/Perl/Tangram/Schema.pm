package UMMF::Export::Perl::Tangram::Schema;

use 5.6.0;
use strict;
use warnings;

our $AUTHOR = q{ kstephens@users.sourceforge.net 2004/03/29 };
our $VERSION = do { my @r = (q$Revision: 1.17 $ =~ /\d+/g); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

UMMF::Export::Perl::Tangram::Schema - Tangram Schema tools.

=head1 SYNOPSIS

=head1 DESCRIPTION

This package provides tools for managing Tangram Schemas.

=head1 USAGE

perl -MUMMF::Export::Perl::Tangram -e 'UMMF::Export::Perl::Tangram::main(@ARGV)' deploy|retreat <dirs-to-scan>

=head1 EXPORT

None exported.

=head1 TO DO

=over 4

=back

=head1 AUTHOR

Kurt Stephens, kstephens@users.sourceforge.net 2004/03/29

=head1 SEE ALSO

L<UMMF::Export::Perl|UMMF::Export::Perl>,
L<UMMF::Export::Perl::Tangram::Storage|UMMF::Export::Perl::Tangram::Storage>,
L<UMMF::Export::Perl::Tangram::Schema|UMMF::Export::Perl::Schema>

=head1 VERSION

$Revision: 1.17 $

=head1 METHODS

=cut

#######################################################################

use base qw(UMMF::Core::Object);

#######################################################################

use Carp qw(confess);
use File::Find;
use IO::File;
use Data::Dumper;
use Cwd qw(fast_abs_path);
use File::Path; # mkpath
use File::Basename;
use DBI;
use UMMF::Export::Perl::DBI;

#######################################################################

my %empty;
my @empty;

#######################################################################


sub initialize
{
  my ($self) = @_;

  $self->SUPER::initialize;

  $self->{'debug'} ||= 0;

  # List of Tangram types to automatically generate indices
  # for 'coll' columns.
  $self->{'index_coll_types'} ||= 
    [
     'Tangram::Ref',
     'Tangram::Set',
     'Tangram::Array',
     'Tangram::Hash',
     'Tangram::FlatHash',
     'Tangram::FlatArray',
    ];

  # List of Tangram types to automatically generate indices
  # for intrusive columns.
  $self->{'index_intr_coll_types'} ||= 
    [
     'Tangram::IntrSet',
     'Tangram::IntrArray',
     'Tangram::IntrRef',
    ];

  my $pkg_filter = $self->{'pkg_filter'} ||= $ENV{'UMMF_STORAGE_SCHEMA_PKG_FILTER'} || '';
  $pkg_filter = qq{sub { local \$_ = \$_[0]; $pkg_filter; 1; } };
  $pkg_filter = eval($pkg_filter) || die("In:\n$pkg_filter\n$@");
  $self->{'pkg_filter'} = $pkg_filter;

  $self;
}


#######################################################################


sub locate_schema_packages
{
  my ($self, $inc_path) = @_;

  $inc_path ||= \@INC;

  my @pkg;

  my %file_visited;

  my $fh = IO::File->new;
  find(
       {
	'wanted' =>
	sub {
	  return unless -f && /\.(p[m])$/i;

	  return if $file_visited{$_} ++;

	  $fh->open("< $_") || (warn("cannot read '$_': $!"), return);

	  print STDERR "SEARCHING $_\n" if $self->{'debug'} > 1;

	  my ($pkg, $pkg_last);
	  my $line;
	  while ( defined(my $line = <$fh>) ) {
	    chomp;
	    if ( $line =~ /^\s*package\s+(.*)\s*;/ ) {
	      $pkg = $1;
	    } elsif ( $line =~ /^sub\s+__tangram_schema\b/ ) {
	      no warnings;

	      print STDERR "found $pkg\n" if $self->{'debug'};

	      $DB::single = 1 if ! $pkg;

	      # Add package only if it doesn't match last one.
	      if ( $self->{'pkg_filter'}->($pkg) ) {
		push(@pkg, [ $pkg, $_ ])
		  if $pkg ne $pkg_last;
	      }

	      $pkg_last = $pkg;
	      # last; # There may be more than one package per file.
	    }
	  }
	  $fh->close;
	},

	'no_chdir' => 1,
       },
       unique_ordered(map(fast_abs_path($_), 
			  grep(-d $_,
			       @$inc_path,
			      ),
			 ),
		     ),
      );

  # Look for duplicate packages.
  my %pkg_seen;
  for my $pkg ( @pkg ) {
    my ($pkg_name, $pkg_path) = @$pkg;
    if ( my $x = $pkg_seen{$pkg_name} ) {
      print STDERR "Package '$pkg_name' ($x->[1]) also found at '$pkg_path', ignoring.\n";
    } else {
      $pkg_seen{$pkg_name} = $pkg;
    }
  }

  # Throw away pkg path.
  @pkg = map($_->[0], values %pkg_seen);

  wantarray ? @pkg : \@pkg;
}


sub get_package_schema
{
  my ($self, $pkg) = @_;

  #$DB::single = 1;
  my $expr = qq{use ${pkg};};
  eval $expr;
  if ( $@ ) {
    $DB::single = 1;
    confess("In:\n$expr\n$@");
  }

  my $schema = ${pkg}->__tangram_schema();
  confess("Schema hash not returned by ${pkg}::__tangram_schema") unless ref($schema) eq 'HASH';

  # Get the file name.
  my $file = $pkg;
  $file =~ s@::@/@sg;
  $file .= ".pm";
  $file = $INC{$file};

  # For each class.
  my $cls_name;
  for my $cls ( @{$schema->{'classes'}} ) {
    unless ( ref($cls) ) {
      $cls_name = $cls;
      next;
    }
    $cls->{'.ummf'}{'from_pm'} = $file;

    # Get the class version.
    my $cls_version;
    {
      no strict 'refs';
      $cls_version = ${"${cls_name}::VERSION"};
    }
    $cls->{'.ummf'}{'class_version'} = $cls_version;
  }

  $schema;
}


sub merge_schema
{
  my ($self, $schema, @schemas) = @_;

  while ( @schemas ) {
    my $x = shift @schemas;

    #print STDERR Data::Dumper->new([ $x ], [qw($x)])->Dump, "\n";

    for my $slot ( 'classes', 'deploy', 'retreat' ) {
      my $a = $schema->{$slot};
      my $b = $x->{$slot};

      if ( (! $a) && $b ) {
	$schema->{$slot} = $b;
      }
      elsif ( ref($a) eq 'HASH' ) {
	%$a = ( %$a, __elements($b) );
      } else {
	#print STDERR "$slot : " . ref($a) . ' ' . ref($b) . "\n";
	# die(ref($a) . ' ' . ref($b)) unless ref($a) eq ref($b);
	push(@$a, __elements($b));
      }
    }
  }

  die("No classes") unless $schema->{'classes'};

  $schema->{'classes'} ||= [ ];

  $schema;
}


sub __elements
{
  my ($x) = @_;
  return () unless $x;
  ref($x) eq 'HASH' ? %$x : @$x;
}


our %type_2_tangram_type =
(
 'double' => 'real',
 'float' => 'real',
 'boolean' => 'int',
 'char' => 'int',
 'byte' => 'int',
);

our %tangram_type_2_class =
(
 'array'       => 'Tangram::Array',
 'backref'     => [ 'Tangram::BackRef', 'Tangram::Coll' ],
 'dmdatetime'  => 'Tangram::DMDateTime',
 'flat_array'  => 'Tangram::FlatArray',
 'flat_hash'   => 'Tangram::FlatHash',
 'hash'        => 'Tangram::Hash',
 'iarray'      => 'Tangram::IntrArray',
 'ihash'       => 'Tangram::IntrHash',
 'iref'        => 'Tangram::IntrRef', # Not installed?
 'iset'        => 'Tangram::IntrSet',
 'perl_dump'   => 'Tangram::PerlDump',
 'rawdate'     => 'Tangram::RawDate',
 'rawdatetime' => 'Tangram::RawDateTime',
 'rawtime'     => 'Tangram::RawTime',
 'ref'         => 'Tangram::Ref',
 'int'         => [ 'Tangram::Integer', 'Tangram::Scalar' ],
 'real'        => [ 'Tangram::Real',    'Tangram::Scalar' ],
 'string'      => [ 'Tangram::String',  'Tangram::Scalar' ],
 'set'         => 'Tangram::Set'
);



my %used;

sub map_type_to_package
{
  my ($self, $type, $schema, $cls, $slot) = @_;

  my $types = $schema->{'.ummf'}{'TYPES'} ||= { %tangram_type_2_class };

  # Map orphan types like 'double' => 'real';
  $type = $type_2_tangram_type{$type}
    if $type_2_tangram_type{$type};

  # For a given type, load the package that implements.
  # print STDERR "type = $type\n";

  confess("$cls->$slot: no type") unless $type;

  my $pkg = $types->{$type};
  if ( $pkg ) {
    $pkg = $pkg->[1] if ref $pkg;
  } else {
    $pkg = $type;
    $type = undef;
  }

  # Autoload the implementing package.
  unless ( $used{$pkg} ++ ) {
    my $expr = qq{use $pkg;};
    # print STDERR "$expr\n";
    eval $expr;
    confess("In:\n$expr\n$@") if $@;
  }

  # Find out what the Tangram typename is.
  unless ( defined $type ) {
    $type = $pkg->tangram_type;

    # Remember the type by name.
    $types->{$type} = $pkg;
  }

  ($type, $pkg);
}


sub prepare_schema
{
  my ($self, $schema) = @_;

  $schema->{'.ummf'}{'date'} ||= scalar gmtime(time);

  $schema->{'.ummf'}{'deploy'} ||= $schema->{'deploy'} || { };
  delete $schema->{'deploy'};
  $schema->{'.ummf'}{'retreat'} ||= $schema->{'retreat'} || { };
  delete $schema->{'retreat'};

  # Convert schema classes ARRAY to hash.
  my $s_clss = \$schema->{'classes'};
  if ( ref($$s_clss) eq 'ARRAY' ) {
    $$s_clss = { @$$s_clss };
  }
  $s_clss = $$s_clss;

  # Convert schema fields ARRAY to hash.
  for my $cls ( values %$s_clss ) {
    my $x = \$cls->{'fields'};
    if ( ref($$x) eq 'ARRAY' ) {
      $$x = { @$$x };
    }
  }

  # The name of the class/id table.
  $schema->{'.ummf'}{'class_id_table'} ||= 'TangramClass';

  # Save class name in its Class def hash.
  for my $cls_name ( keys %$s_clss ) {
    ($s_clss->{$cls_name}{'.ummf'} ||= { })->{'class_name'} = $cls_name;
  }

  # Transform: 
  # 'slots' => {
  #   'field' => { 'type_impl' => 'ref', 'class' => 'Some::Class::With::type_impl::defined', ... },
  # To:
  #   'field' => { 'type_impl' => $class->{'Some::Class::With::type_impl::defined'}{'type_impl', ... },
  # }
  for my $cls ( values %$s_clss ) {
    for my $field_name ( keys %{$cls->{'slots'} || \%empty} ) {
      # Make slots entries hashes.
      my $xr = \$cls->{'slots'}{$field_name};
      $$xr = { 'type_impl' => $$xr } unless ref($$xr) eq 'HASH';
      my $x = $$xr;

      my $class_type_impl;
      if ( $x->{'type_impl'} eq 'ref' && 
	   ($class_type_impl = $s_clss->{$x->{'class'}}{'type_impl'}) ) {
	my $cls_name = $cls->{'.ummf'}{'class_name'};
	# print STDERR "Mapped $cls_name.$field_name ref $x->{class} => type_impl $class_type_impl\n";
	$x->{'type_impl'} = $class_type_impl;
	delete $x->{'class'};
      }
    }
  }

  # Transform: 
  # 'slots' => {
  #   'field_name' => {'type_impl' => 'typename', ... },
  #   ... }
  # Into:
  # 'fields' => {
  #   'typename' => [
  #     'field_name' => { ... }
  #   ],
  # ...
  # }

  for my $cls ( values %$s_clss ) {
    $cls->{'fields'} ||= { };
    $cls->{'bases'} ||= [ ];

    # For each slot in $cls,
    for my $field_name ( keys %{$cls->{'slots'} || \%empty} ) {
      my $xr = \$cls->{'slots'}{$field_name};
      $$xr = { 'type_impl' => $$xr } unless ref($$xr) eq 'HASH';
      my $x = $$xr;
      
      # Resolve the type and package.
      ($x->{'type_impl'}) = $self->map_type_to_package($x->{'type_impl'}, $schema, $cls->{'.ummf'}{'class_name'}, $field_name);
	
      # Add a Tangram::Schema fields entry by type
      my $type_impl = $x->{'type_impl'};
      delete $x->{'type_impl'};
      
      ($cls->{'fields'}{$type_impl} ||= { })->{$field_name} = $x;
    }
    
    # Delete non-Tangram 'slots' hash.
    delete $cls->{'slots'};
  }

  # Remove Classes that have a 'type_impl';
  for my $cls ( values %$s_clss ) {
    if ( $cls->{'type_impl'} || ! $cls->{'.ummf'}{'class_name'} ) {
      delete $s_clss->{$cls->{'.ummf'}{'class_name'}};
    }
  }

  # Check for bogus types
  for my $cls ( values %$s_clss ) {
    my $cls_name = $cls->{'.ummf'}{'class_name'};
    if ( $cls_name =~ /^Java::/ ) {
      confess("Runaway Java type '$cls_name', use ummf.storage.type...");
    }
    if ( $cls->{'table'} =~ /::/ ) {
      confess("Runaway table name '$cls->{table}', use ummf.storage.table...");
    }
  }

  # Remove unused field types generated by PerlTemplate.txt.
  for my $cls ( values %$s_clss ) {
    # my $x = $cls; print STDERR Data::Dumper->new([ $x ], [qw($x)])->Dump, "\n";

    for my $type ( keys %{$cls->{'fields'}} ) {
      # For others.
      $self->map_type_to_package($type, $schema);

      my $x = $cls->{'fields'}{$type};
      unless ( $x && (ref($x) eq 'ARRAY' ? @$x : keys %$x) ) {
	delete $cls->{'fields'}{$type};
      }
    }

    # Filter out base classes that do not have a schema.
    @{$cls->{'bases'}} = grep($s_clss->{$_}, @{$cls->{'bases'}});
  }

  # Fix SQL keywords.
  for my $cls ( values %$s_clss ) {
    # Fix table name.
    fix_sql_keyword(\$cls->{'table'}) 
    if $cls->{'table'};

    for my $type ( keys %{$cls->{'fields'}} ) {
      my $fields = $cls->{'fields'}{$type};
      if ( $fields && (ref($fields) eq 'HASH') ) {
	for my $field_def ( values %$fields ) {
	  next unless ref($field_def) eq 'HASH';

	  # Fix column names.
	  for my $x ( 'coll', 'col', 'slot', 'item', 'table' ) {
	    fix_sql_keyword(\$field_def->{$x}) 
	      if $field_def->{$x};
	  }
	}
      }
    }
  }
  

  $schema;
}


sub deploy_schema
{
  my ($self, $schema, $to_db) = @_;

  $self->_do_schema($schema, $to_db, 'deploy');
}


sub retreat_schema
{
  my ($self, $schema, $to_db) = @_;

  $self->_do_schema($schema, $to_db, 'retreat');
}


sub _do_schema
{
  my ($self, $schema, $to_db, $method) = @_;

  # Get a new storage object.
  my $storage = UML::__ObjectBase->__storage;
  my $do;
  my $dbh;
  my @opts;
  if ( $to_db ) {
    $dbh = $storage->dbh;
    $do = sub { 
      my $stmt = join('', @_);
      $dbh->do($stmt) || 
	print STDERR "SQL ERROR: " . $dbh->errstr . ": in $stmt"; 
    };
    @opts = ($dbh);
  } else {
    # To STDOUT.
    $do = sub { print @_, "\n"; };
  }

  # Generated a tangram schema.
  my ($ts, $schema_dump, $schema_var) = $self->tangram_schema($schema, $do, $dbh, $storage);

  # $DB::single = 1;

  # Do TangramClass table.
  if ( $to_db ) {
    my $class_table = $schema->{'.ummf'}{'class_id_table'};
    if ( $method eq 'retreat' ) {
      # Drop table.
      # $do->("DROP TABLE $class_table");
      # Never drop this table, too useful.
    }
  }

  # Deploy the basic schema.
  Tangram::Relational->$method($ts, @opts);

  # Locate all indices by table.
  my @index;
  my %table_index;

  my $indexs = $ts->{'.ummf'}{'index'} ||= [ ];
  for my $index ( @$indexs ) {
    my ($table_name, $columns, $UNIQUE, $index_name) = @$index;
    my @columns = ref($columns) ? @$columns : ($columns);
    $columns = join(', ', @columns);

    next if $table_index{"$table_name,$columns"} ++;

    # Create an index name,
    $index_name ||= join('_',
			 '_ind',
			 $table_name,
			 @columns,
		       );

    push(@index, [ $table_name, $columns, $index_name, $UNIQUE ]);
  }

  # Sort by table name, then by columns.
  @index = sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] } @index;

  # Deploy or retreat the indices
  for my $index ( @index ) {
    my ($table_name, $columns, $index_name, $UNIQUE) = @$index;

    if ( $method eq 'retreat' ) {
      # Create an index.
      $do->("DROP INDEX $index_name;");
    } else {
      # Create an index.
      $UNIQUE = $UNIQUE ? 'UNIQUE ' : '';
      $do->("CREATE ${UNIQUE}INDEX $index_name ON $table_name ($columns);");
    }
  }


  if ( $method eq 'deploy' ) {
    # Append the $schema dump.
    my $schema_file = $storage->schema_hash_file;
    my $schema_pkg = $storage->schema_hash_pkg;

    if ( $schema_file ) {
      my $fh = IO::File->new;
      {
	my $dir = dirname($schema_file);
	unless ( -d $dir ) {
	  mkpath($dir, 1) || confess("Cannot create directory '$dir': $!")
	}
      }
      $fh->open("> $schema_file") || confess("Cannot write schema file '$schema_file': $!");

      $schema_dump = "$schema_dump;\n$schema_var;\n";

      if ( $schema_pkg ) {
	$schema_dump = 
	  "package $schema_pkg;\n" .
	  "our \$VERSION = qw($VERSION);\n" .
	  "sub tangram_schema_hash {\n" .
	  "my $schema_var;\n" .
	  $schema_dump .
	  "}"
      }
      print $fh 
	# "my ",
	"$schema_dump\n", 
	"1;\n";

      $fh->close;
    } else {
      unless ( $to_db ) {
	$schema_dump =~ s/^/--- /mg;
	$do->($schema_dump);
      }
    }
  }

  # Call deployment methods on each cls.
  if ( $method eq 'deploy' && $to_db ) {
    # Get hash of 'class_name' => 'deploy method',
    my $c_clss = $ts->{'.ummf'}{$method} || { };

    # Prepare the UMMF::...::Tangram::Storage object.
    $storage->{'schema'} = $ts || die("No Tangram::Schema");
    local $UML::__ObjectBase::storage = $storage;

    my ($cls_name, $meth);
    while ( ($cls_name, $meth) = each %$c_clss ) {
      # If the tangram_schema() for the class has
      # a storage.deploy method,
      #   Call it with the $storage object.
      if ( $meth ) {
	print STDERR "Deploy $cls_name -> $meth\n";
       
	$DB::single = 1;
	#die;

	$cls_name->$meth($storage);
      }
    }
  }

  $self;
}


sub manage_class_ids
{
  my ($self, $schema, $do, $dbh, $action) = @_;

  if ( ! $do ) {
    if ( $dbh ) {
      $do = sub { $dbh->do(@_) || print STDERR "SQL: Error: " . $dbh->errstr . ": in @_"; };
    } else {
      $do = sub { print join('', @_), "\n"; };
    }
  }

  no warnings;
  if ( $action eq 'store' ) {
    $self->store_class_ids($schema, $do, $dbh);
  } else {
    $self->load_class_ids($schema, $do, $dbh);
  }
}


sub load_class_ids
{
  my ($self, $schema, $do, $dbh) = @_;

  my $table = $schema->{'.ummf'}{'class_id_table'} || confess;

  # $DB::single = 1;

  my $class_by_name = 
    ($dbh && $dbh->selectall_hashref("SELECT * FROM $table", 'name')) || { };
  # print STDERR Data::Dumper->new([ $class_by_name ], [qw($class_by_name)])->Dump(), "\n";

  # Need table definition in store_class_ids()?
  $schema->{'.ummf'}{'class_table_create'} = ! keys %$class_by_name;

  # $schema->{'.ummf'}{'class_id'} = $class_by_name;
  my $last_id = 0;

  my @cls_needs_id;
  my $s_clss = $schema->{'classes'};
  for my $cls ( sort { $a->{'.ummf'}{'class_name'} cmp $b->{'.ummf'}{'class_name'} } values %$s_clss ) {
    #my $name = grep($s_clss->{$_} eq $cls, keys %$s_clss);
    #print STDERR "cls '$name' = ", Data::Dumper->new([$cls])->Dump(), "\n";

    my $cls_name = $cls->{'.ummf'}{'class_name'} || confess("No class name");
    if ( my $cls_x = $class_by_name->{$cls_name} ) {
      $cls->{'id'} = $cls_x->{'id'};
      # print STDERR "Class '$cls_name': id $cls->{id}\n";
      {
	no warnings;
	
	$last_id = $cls->{'id'}
          if $last_id < $cls->{'id'};
      }
    } else {
      print STDERR "Warning: no id for class '$cls_name' defined in $table\n";
      push(@cls_needs_id, $cls);
    }

  }

  # Assign new IDs to classes, before Tangram::Schema->new().
  $schema->{'.ummf'}{'cls_needs_id'} = @cls_needs_id;
  for my $cls ( @cls_needs_id ) {
    $cls->{'id'} = ++ $last_id;
    $cls->{'.ummf'}{'needs_store'} = 1;
  }

  # Remember last class id.
  $schema->{'.ummf'}{'last_id'} = $last_id;

  # $DB::single = 1;

  $self;
}


sub store_class_ids
{
  my ($self, $schema, $do, $dbh) = @_;

  my $table = $schema->{'.ummf'}{'class_id_table'} || confess;

  # $DB::single = 1;

  if ( $schema->{'.ummf'}{'class_table_create'} ) {
    # Create table first.
    $do->(
qq{CREATE TABLE $table (
  id INT,
  name VARCHAR(255),
  class_version VARCHAR(32),
  primary_table VARCHAR(64),
  added DATETIME
);}
	 );
    $do->(qq{CREATE UNIQUE INDEX ${table}_id ON ${table} (id);});
    $do->(qq{CREATE UNIQUE INDEX ${table}_name ON ${table} (name);});
    $do->(qq{ALTER TABLE ${table} ADD COLUMN primary_key VARCHAR(32) AFTER primary_table;});
    $do->(qq{ALTER TABLE ${table} ADD COLUMN type_column VARCHAR(32) AFTER primary_key;});
  }

  # Force commit.
  # $dbh->commit;

  my $x = sub {
    my $s_clss = $schema->{'classes'};
    for my $cls ( sort { $a->{'.ummf'}{'class_name'} cmp $b->{'.ummf'}{'class_name'} } values %$s_clss ) {
      my $cls_name      = $cls->{'.ummf'}{'class_name'} || die("No class name");
      my $cls_id        = $cls->{'id'} || die("$cls_name has no class id");
      my $cls_version   = $cls->{'.ummf'}{'class_version'} || '-1';
      my $cls_table     = $cls->{'table'};
      my $cls_id_col    = $cls->{'sql'}{'id_col'};
      my $cls_class_col = $cls->{'sql'}{'class_col'} || '';
      
      if ( $cls->{'.ummf'}{'needs_store'} ) {
      # print STDERR "Class '$cls_name' gets id '$cls_id'\n";
      if ( $_[0] eq 'insert' ) {
	$do->(qq{INSERT INTO $table (id, name, added) VALUES ($cls_id, '$cls_name', NOW());});
      } else {
	$do->(qq{UPDATE $table SET 
    class_version = '$cls_version', 
    primary_table = '$cls_table', 
    primary_key = '$cls_id_col', 
    type_column = '$cls_class_col' 
  WHERE 
    name = '$cls_name';});
      }
    }
    }
  };

  # Do inserts, then updates for cut-and-paste niceness.
  $x->('insert');
  $x->('update');

  # Force commit.
  # $dbh->commit;
  
  $self;
}


sub tangram_schema ($$$$$)
{
  my ($self, $schema, $do, $dbh, $storage) = @_;
 
  use Tangram;

  use Tangram::Schema;
  use Tangram::Relational;

  use Tangram::Core;

  # Prepare a dump of the schema hash.
  my $schema_var = $storage->schema_var;
  my $schema_dump = Data::Dumper->new([ $schema ], [$schema_var])->Purity(1)->Dump;


  # Load class meta-data.
  if ( $do ) {
    $self->manage_class_ids($schema, $do, $dbh, 'load');
  }

  # Create a Tangram::Schema object.
  # $DB::single = 1;
  my $ts = Tangram::Schema->new($schema);

  # Store class meta-data.
  if ( $do ) {
    $self->manage_class_ids($ts, $do, $dbh, 'store');
  }

  #print STDERR Data::Dumper->new([ $ts ], [qw($ts)])->Dump, "\n";
  # $DB::single = 1;

  # Create necessary indexs:
  #   [ table_name, [ column_names, ... ], UNIQUE? ]
  my $indexs = $ts->{'.ummf'}{'index'} ||= [ ];

  # Scan for 'coll' indices.
  my $s_clss = $ts->{'classes'};
  for my $cls ( ref($s_clss) eq 'ARRAY' ? @$s_clss : values %$s_clss ) {
    next unless ref($cls);

    # Create index for type.
    if ( $cls->{'table'} ) { 
      push(@$indexs, [ $cls->{'table'}, 'type' ]);
    }

    for my $col ( keys %{$cls->{'MEMDEFS'}} ) {
      my $x = $cls->{'MEMDEFS'}{$col};
      # print STDERR "$x '$x->{table}' '$x->{col}' '$x->{coll}'\n";
      # $DB::single = 1 if $x =~ /Ref/;

      my $table = $x->{'table'} || $cls->{'table'};

      # If ummf.storage.index is explicitly set;
      # Create index on 'col'.
      if ( $x->{'index'} ) {
	my $UNIQUE = $x->{'index'} =~ /uni/i ? 1 : 0;
	push(@$indexs, [ $table, $x->{'col'}, $UNIQUE ]);
      }
      elsif ( grep(UNIVERSAL::isa($x, $_), @{$self->{'index_coll_types'}}) ) {
	# Tangram::Ref has no 'table'.
	if ( ! $x->{'table'} && $x->{'col'} ) { 
	  push(@$indexs, [ $table, $x->{'col'}, 0 ]);
	}
	if ( $x->{'table'} && $x->{'coll'} ) {
	  push(@$indexs, [ $table, $x->{'coll'}, 0 ]);
	}
	if ( $x->{'table'} && $x->{'item'} ) {
	  push(@$indexs, [ $table, $x->{'item'}, 0 ]);
	}
	if ( $x->{'table'} && $x->{'slot'} ) {
	  push(@$indexs, [ $table, $x->{'slot'}, 0 ]);
	}
      }
      # Intrusive collections add columns into the table of the
      # class of the elements in the collection.
      elsif ( grep(UNIVERSAL::isa($x, $_), @{$self->{'index_intr_coll_types'}}) ) {
	$table = $ts->{'classes'}{$x->{'class'}}{'table'};
	# $DB::single = 1;

	# Tangram::Ref has no 'table'.
	if ( $table && $x->{'coll'} ) {
	  push(@$indexs, [ $table, $x->{'coll'}, 0 ]);
	}
	if ( $table && $x->{'item'} ) {
	  push(@$indexs, [ $table, $x->{'item'}, 0 ]);
	}
      }
    }
  }

  ($ts, $schema_dump, $schema_var);
}


#######################################################################
# Handle reserved words (why does SQL have *so* many?)
#


sub unique_ordered
{
  my (%x, @x);

  for my $x ( @_ ) {
    push(@x, $x) unless $x{$x} ++;
  }

  wantarray ? @x : \@x;
}


my %sql_keyword =
  (
   # Tangram reserved columns:
   'id' => 1,
   'type' => 1,
  );


sub fix_sql_keyword
{
  my ($r) = @_;

  my $v;
  while ( ($v = $$r) && $sql_keyword{lc($v)} ) {
    $$r = '_' . $$r;
  }

  $$r;
}


{
  local $_;
  # $DB::single = 1;
  while ( <DATA> ) {
    chomp;
    s/^\s+//;
    s/\s+$//;
    next if /^#/;
    last if /^--END--/;
    $sql_keyword{lc($_)} = 1;
  }
}


1;


__DATA__
# From phpMyAdmin-2.5.1/badwords.txt
action
add
after
aggregate
all
alter
analyze
and
as
asc
avg
avg_row_length
auto_increment
bdb
berkeleydb
between
bigint
bit
binary
blob
bool
both
by
cascade
case
change
char
character
check
checksum
column
columns
comment
constraint
create
cross
current_date
current_time
current_timestamp
data
database
databases
datetime
day
day_hour
day_minute
day_second
dayofmonth
dayofweek
dayofyear
dec
decimal
default
delayed
delay_key_write
delete
desc
describe
distinct
distinctrow
double
drop
else
enclosed
end
enum
escape
escaped
exists
explain
fields
file
first
float
float4
float8
flush
for
foreign
from
full
fulltext
function
global
grant
grants
group
having
heap
high_priority
hour
hour_minute
hour_second
hosts
identified
if
ignore
in
index
infile
inner
innodb
insert
insert_id
int
integer
interval
int1
int2
int3
int4
int8
into
is
isam
join
key
keys
kill
last_insert_id
leading
left
length
like
limit
lines
load
local
lock
logs
long
longblob
longtext
low_priority
master_log_seq
master_server_id
match
max
max_rows
mediumblob
mediumint
mediumtext
middleint
min_rows
minute
minute_second
modify
month
monthname
mrg_myisam
myisam
natural
no
not
null
numeric
on
optimize
option
optionally
or
order
outer
outfile
pack_keys
partial
password
precision
primary
procedure
process
processlist
privileges
purge
read
real
references
regexp
reload
rename
replace
require
restrict
returns
revoke
right
rlike
row
rows
second
select
set
show
shutdown
smallint
soname
sql_auto_is_null
sql_big_result
sql_big_selects
sql_big_tables
sql_buffer_result
sql_calc_found_rows
sql_log_bin
sql_log_off
sql_log_update
sql_low_priority_updates
sql_max_join_size
sql_quote_show_create
sql_safe_updates
sql_select_limit
sql_slave_skip_counter
sql_small_result
sql_warnings
ssl
starting
straight_join
string
striped
table
tables
temporary
terminated
text
then
time
timestamp
tinyblob
tinyint
tinytext
to
trailing
type
union
unique
unlock
unsigned
update
usage
use
using
values
varbinary
varchar
variables
varying
when
where
with
write
year
year_month
zerofill
--END--

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


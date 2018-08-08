package UR::DataSource::RDBMS;

# NOTE:: UR::DataSource::QueryPlan has conditional logic 
# for this class/subclasses currently

use strict;
use warnings;
use Scalar::Util;
use List::MoreUtils;
use File::Basename;

require UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::DataSource::RDBMS',
    is => ['UR::DataSource','UR::Singleton'],
    is_abstract => 1,
    has => [
        server       => { is => 'Text', doc => 'the "server" part of the DBI connect string' },
        login        => { is => 'Text', doc => 'user name to connect as', is_optional => 1 },
        auth         => { is => 'Text', doc => 'authentication for the given user', is_optional => 1 },
        owner        => { is => 'Text', doc => 'Schema/owner name to connect to', is_optional => 1  },
    ],

    has_optional => [
        alternate_db_dsn => {
            is => 'Text',
            default_value => 0,
            doc => 'Set to a DBI dsn to copy all data queried from this datasource to an alternate database',
        },
        camel_case_table_names => {
            is => 'Boolean',
            default_value => 0,
            doc => 'When true, dynamically calculating class names from table names will expect camel case in table names.',
        },
        camel_case_column_names => {
            is => 'Boolean',
            default_value => 0,
            doc => 'When true, dynamically calculating property names from column names will expect camel case in column names.',
        },
        _all_dbh_hashref                 => { is => 'HASH', len => undef, is_transient => 1 },
        _last_savepoint                  => { is => 'Text', len => undef, is_transient => 1 },
    ],
    valid_signals => ['query', 'query_failed', 'commit_failed', 'do_failed', 'connect_failed', 'sequence_nextval', 'sequence_nextval_failed'],
    doc => 'A logical DBI-based database, independent of prod/dev/testing considerations or login details.',
);

# A record of objects saved to the database.  It's filled in by _sync_database()
# and used by the alternate DB saving code.  Objects noted in this hash don't get
# saved to the alternate DB
my %objects_in_database_saved_by_this_process;

sub database_exists {
    my $self = shift;
    warn $self->class . " failed to implement the database_exists() method.  Testing connection as a surrogate.  FIXME here!\n";
    eval {
        my $c = $self->create_default_handle();
    };
    if ($@) {
        return;
    }
    return 1;
}

sub create_database {
    my $self = shift;
    die $self->class . " failed to implement the create_database() method!"
        . "  Unable to initialize a new database for this data source "
        . $self->__display_name__ . " FIXME here.\n";
}

sub _resolve_ddl_for_table {
    my ($self,$table, %opts) = @_;

    my $all = delete $opts{all};
    if (%opts) {
        Carp::confess("odd arguments to _resolve_ddl_for_table: " . UR::Util::d(\%opts));
    }

    my $table_name = $table->table_name;
    my @ddl;
    if ($table->{db_committed} and not $all) {
        my @columns = $table->columns;
        for my $column (@columns) {
            next unless $all or $column->last_object_revision eq '-';
            my $column_name = $column->column_name;
            my $ddl = "alter table $table_name add column ";

            $ddl .= "\t$column_name " . $column->data_type;
            if ($column->data_length) {
                $ddl .= '(' . $column->data_length . ')';
            }
            push(@ddl, $ddl) if $ddl;
        }
    }
    else {
        my $ddl;
        my @columns = $table->columns;
        for my $column (@columns) {
            next unless $all or $column->last_object_revision eq '-';
            my $column_name = $column->column_name;
            $ddl = 'create table ' . $table_name . "(\n" unless defined $ddl;

            $ddl .= "\t$column_name " . $column->data_type;
            if ($column->data_length) {
                $ddl .= '(' . $column->data_length . ')';
            }

            $ddl .= ",\n" unless $column eq $columns[-1];
        }
        $ddl .= "\n)" if defined $ddl;
        push(@ddl, $ddl) if $ddl;
    }
    return @ddl;
}

sub generate_schema_for_class_meta {
    my ($self, $class_meta, $temp) = @_;

    # We now support on-the-fly database introspection
    # this gets called with the temp flag when _sync_database realizes 
    # it knows nothing about the table in question.
    
    # We basically presume the schema is the one we would have generated 
    # given the current class definitions

    # TODO: We still need to presume foreign keys are constrained.

    my $method = ($temp ? '__define__' : 'create'); 
    my @defined;    
    my $table_name = $class_meta->table_name;
    my @fks_to_generate;
    for my $p ($class_meta->parent_class_metas) {
        next if ($p->class_name eq 'UR::Object' or $p->class_name eq 'UR::Entity');
        next unless $p->class_name->isa("UR::Object");
        my @new = $self->generate_schema_for_class_meta($p,$temp);
        push @defined, @new;

        my $parent_table;
        if (($parent_table) = grep { $_->isa("UR::DataSource::RDBMS::Table") } @new) {
            my @id_by = $class_meta->id_property_names;            
            my @column_names = map { $class_meta->property($_)->column_name } @id_by;
            my $r_table_name = $parent_table->table_name;
            ##$DB::single = 1; # get pk columns
            my @r_id_by = $p->id_property_names;
            my @r_column_names = map { $class_meta->property($_)->column_name } @r_id_by;
            push @fks_to_generate, [$class_meta->class_name, $table_name, $r_table_name, \@column_names, \@r_column_names];
        }
    }

    my %properties_with_expected_columns = 
        map { $_->column_name => $_ } 
        grep { $_->column_name }
        $class_meta->direct_property_metas;    

    #my %expected_constraints =
    #    map { $_->column_name => $_ }
    #    grep { $_->class_meta eq $class_meta }
    #    map { $class_meta->property_meta_for_name($_) }
    #    map { @{ $_->id_by } }
    #    grep { $_->id_by }
    #    $class_meta->all_property_metas;
    #print Data::Dumper::Dumper(\%expected_constraints);
    
    unless ($table_name) {
        if (my @column_names = keys %properties_with_expected_columns) {
            Carp::confess("class " . $class_meta->__display_name__ . " has no table_name specified for columns @column_names!");
        }
        else {
            # no table, but no storable columns.  all ok.
            return;
        }
    }

    ## print "handling table $table_name\n";

    if ($table_name =~ /[^\w\.]/) {
        # pass back anything from parent classes, but do nothing for special "view" tables
        #$DB::single = 1;
        return @defined;   
    }
 
    my $t = '-'; 

    my $table = $self->refresh_database_metadata_for_table_name($table_name, $method);
 
    my %existing_columns;
    if ($table) {
        ## print "found table $table_name\n";
        %existing_columns = 
            map { $_->column_name => $_ } 
            grep { $_->column_name }
            $table->columns;
        push @defined, ($table,$table->columns);
    }
    else {
        ## print "adding table $table_name\n";
        $table = UR::DataSource::RDBMS::Table->$method(
            table_name  => $table_name,
            data_source => $self->_my_data_source_id,
            remarks => $class_meta->doc,
            er_type => 'entity',
            last_object_revision => $t,
            table_type => ($table_name =~ /\s/ ? 'view' : 'table'),
        );
        Carp::confess("Failed to create metadata or table $table_name") unless $table;
        push @defined, $table;
    }

    my ($update,$add,$extra) = UR::Util::intersect_lists([keys %properties_with_expected_columns],[keys %existing_columns]);

    for my $column_name (@$extra) {
        my $column = $existing_columns{$column_name};
        $column->last_object_revision('?');
    }   
   
    for my $column_name (@$add) {
        my $property = $properties_with_expected_columns{$column_name}; 
        #print "adding column $column_name\n";
        my $column = UR::DataSource::RDBMS::TableColumn->$method(
            column_name => $column_name,
            table_name => $table->table_name,
            data_source => $table->data_source,
            namespace => $table->namespace,
            data_type => $self->object_to_db_type($property->data_type) || 'Text',
            data_length => $property->data_length,
            nullable => $property->is_optional,
            remarks => $property->doc,
            last_object_revision => $t, 
        );
        push @defined, $column;
    }

    for my $column_name (@$update) {
        my $property = $properties_with_expected_columns{$column_name}; 
        my $column = $existing_columns{$column_name};
        ##print "updating column $column_name with data from property " . $property->property_name . "\n";
        if ($column->data_type) {
            $column->data_type($self->object_to_db_type($property->data_type)) if $property->data_type;
        }
        else {
            $column->data_type($self->object_to_db_type($property->data_type) || 'Text');
        }
        $column->data_length($property->data_length);
        $column->nullable($property->is_optional);
        $column->remarks($property->doc);
    }

    for my $property ( $class_meta->direct_id_property_metas ) {

        unless (UR::DataSource::RDBMS::PkConstraintColumn->get(table_name => $table->table_name, column_name => $property->column_name, data_source => $table->data_source)) {
            UR::DataSource::RDBMS::PkConstraintColumn->$method(
                column_name => $property->column_name,
                data_source => $table->data_source,
                rank        => $property->is_id,
                table_name  => $table->table_name );
        }
    }

    # this "property_metas" method filers out things which have an id_by.
    # it used to call ->properties, which used that method internally ...but seems like it never could have done anything?
    for my $property ($class_meta->property_metas) {
        my $id_by = $property->id_by;
        next unless $id_by;
        my $r_class_name = $property->data_type;
        my $r_class_meta = $r_class_name->__meta__;
        my $r_table_name = $r_class_meta->table_name;
        next unless $r_table_name;
        my @column_names = map { $class_meta->property($_)->column_name } @$id_by;
        my @r_column_names = map { $r_class_meta->property($_)->column_name } @{ $r_class_meta->id_property_names };

        push @fks_to_generate, [$property->id, $table_name, $r_table_name, \@column_names, \@r_column_names ];
    }

    for my $fk_to_generate (@fks_to_generate) {
        my ($fk_id, $table_name, $r_table_name, $column_names, $r_column_names) = @$fk_to_generate;
        
        my $fk = UR::DataSource::RDBMS::FkConstraint->$method(
            fk_constraint_name => $fk_id,
            table_name      => $table_name,
            r_table_name    => $r_table_name,
            data_source     => $self->_my_data_source_id,
            last_object_revision => '-',
        );
        unless ($fk) {
            die "failed to generate an implied foreign key constraint for $table_name => $r_table_name!"
                . UR::DataSource::RDBMS::FkConstraint->error_message;
        }
        push @defined, $fk;

        for (my $n = 0; $n < @$column_names; $n++) {
            my $column_name = $column_names->[$n];
            my $r_column_name = $r_column_names->[$n];
            my %fkcol_params = ( fk_constraint_name => $fk_id,
                                 table_name      => $table_name,
                                 column_name     => $column_name,
                                 r_table_name    => $r_table_name,
                                 r_column_name   => $r_column_name,
                                 data_source     => $self->_my_data_source_id,
                               );

            my $fkcol = UR::DataSource::RDBMS::FkConstraintColumn->get(%fkcol_params);
            unless ($fkcol) {
                $fkcol = UR::DataSource::RDBMS::FkConstraintColumn->$method(%fkcol_params);
            }
            unless ($fkcol) {
                die "failed to generate an implied foreign key constraint for $table_name => $r_table_name!"
                    . UR::DataSource::RDBMS::FkConstraint->error_message;
            }
            push @defined, $fkcol;
        }
    }
    
    # handle missing meta datasource on the fly...
    if (@defined) {
        my $ns = $class_meta->namespace;
        my $exists = UR::Object::Type->get($ns . "::DataSource::Meta");
        unless ($exists) {
            UR::DataSource::Meta->generate_for_namespace($ns);
        }
    }

    unless ($temp) {
        my @ddl = $self->_resolve_ddl_for_table($table);
        $t = $UR::Context::current->now;
        if (@ddl) {
            my $dbh = $table->data_source->get_default_handle;
            for my $ddl (@ddl) {
                $dbh->do($ddl) or Carp::confess("Failed to modify the database schema!: $ddl\n" . $dbh->errstr);
                for my $o ($table, $table->columns) {
                    $o->last_object_revision($t);
                }
            }
        }
    }

    return @defined;
}

# override in architecture-oriented subclasses
sub object_to_db_type {
    my ($self, $object_type) = @_;
    my $db_type = $object_type;
    # ...
    return $db_type;
}

# override in architecture-oriented subclasses
sub db_to_object_type {
    my ($self, $db_type) = @_;
    my $object_type = $db_type;
    # ...
    return $object_type;
}


# FIXME - shouldn't this be a property of the class instead of a method?
sub does_support_joins { 1 } 

# Most RDBMSs support limit/offset selects
sub does_support_limit_offset { 1 }

sub get_class_meta_for_table {
    my $self = shift;
    my $table = shift;
    my $table_name = $table->table_name;

    return $self->get_class_meta_for_table_name($table_name);
}

sub get_class_meta_for_table_name {
    my($self,$table_name) = @_;
    
    # There is an unique constraint on classes, but only those which use
    # tables in an RDBMS, which dicates that there can be only two for
    # a given table in a given data source: one for the ghost and one
    # for the regular entity.  We can't just fix this with a unique constraint
    # since classes with a null data source would be lost in some queries.
    my @class_meta =
        grep { not $_->class_name->isa("UR::Object::Ghost") }
        UR::Object::Type->get(
            table_name => $table_name,
            data_source => $self->class,
        );
    
    unless (@class_meta) {
        # This will load every class in the namespace on the first execution :(
        ##$DB::single = 1;
        @class_meta =
            grep { not $_->class_name->isa("UR::Object::Ghost") }
            UR::Object::Type->get(
                table_name => $table_name,
                data_source => $self->class,
            );
    }

    $self->context_return(@class_meta);
}

sub dbi_data_source_name {    
    my $self = shift->_singleton_object;
    my $driver  = $self->driver;    
    my $server  = $self->server;
    unless ($driver) {
        Carp::confess("Cannot resolve a dbi_data_source_name with an undefined driver()");
    }    
    unless ($server) {
        Carp::confess("Cannot resolve a dbi_data_source_name with an undefined server()");
    }
    return 'dbi:' . $driver . ':' . $server;
}

*get_default_dbh = \&get_default_handle;
sub get_default_handle {    
    my $self = shift->_singleton_object;    
    my $dbh = $self->SUPER::get_default_handle;
    unless ($dbh && $dbh->{Active}) {
        $self->__invalidate_get_default_handle__;
        $dbh = $self->create_default_handle();
    }    
    return $dbh;
}




sub get_for_dbh {
    my $class = shift;
    my $dbh = shift;
    my $ds_name = $dbh->{"private_UR::DataSource::RDBMS_name"};
    return unless($ds_name);
    my $ds = UR::DataSource->get($ds_name);
    return $ds;
}

sub has_changes_in_base_context {
    shift->has_default_handle;
    # TODO: actually check, as this is fairly conservative
    # If used for switching contexts, we'd need to safely rollback any transactions first.
}


sub _dbi_connect_args {
    my $self = shift;

    my @connection;
    $connection[0] = $self->dbi_data_source_name;
    $connection[1] = $self->login;
    $connection[2] = $self->auth;
    $connection[3] = { AutoCommit => 0, RaiseError => 0 };

    return @connection;
}

sub get_connection_debug_info {
    my $self = shift;
    my $handle_class = $self->default_handle_class;
    my @debug_info = (
        "DBI Data Source Name: ", $self->dbi_data_source_name, "\n",
        "DBI Login: ", $self->login || '' , "\n",
        "DBI Version: ", $DBI::VERSION, "\n",
        "DBI Error: ", $handle_class->errstr || '(no error)', "\n",
    );
    return @debug_info;
}

sub default_handle_class { 'UR::DBI' };

sub create_dbh { shift->create_default_handle_wrapper }
sub create_default_handle {
    my $self = shift;
    if (! ref($self) and $self->isa('UR::Singleton')) {
        $self = $self->_singleton_object;
    }
    
    # get connection information
    my @connection = $self->_dbi_connect_args();
    
    # connect
    my $handle_class = $self->default_handle_class;
    my $dbh = $handle_class->connect(@connection);
    unless ($dbh) {
        my $errstr;
        {   no strict 'refs';
            $errstr = ${"${handle_class}::errstr"};
        };
        my @confession = (
            "Failed to connect to the database: $errstr\n",
            $self->get_connection_debug_info(),
        );
        $self->__signal_observers__('connect_failed', 'connect', \@connection, $errstr);
        Carp::confess(@confession);
    }

    # used for reverse lookups
    $dbh->{'private_UR::DataSource::RDBMS_name'} = $self->class;

    # store the handle in a hash, since it's not a UR::Object
    my $all_dbh_hashref = $self->_all_dbh_hashref;
    unless ($all_dbh_hashref) {
        $all_dbh_hashref = {};
        $self->_all_dbh_hashref($all_dbh_hashref);
    }
    $all_dbh_hashref->{$dbh} = $dbh;
    Scalar::Util::weaken($all_dbh_hashref->{$dbh});

    $self->is_connected(1);
    
    return $dbh;
}

# The default is to ignore no tables, but derived classes
# will probably override this
sub _ignore_table {
    0;
}


sub _table_name_to_use_for_metadata_objects {
    my($self, $schema, $table_name) = @_;
    return $self->owner
                ? $table_name
                : join('.', $schema, $table_name);
}

sub _get_table_names_from_data_dictionary {
    my $self = shift->_singleton_object;        
    if (@_) {
        Carp::confess("get_tables does not currently take filters!  FIXME.");
    }    
    my $dbh = $self->get_default_handle;
    my $owner = $self->owner || '%';

    # FIXME  This will fix the immediate problem of getting classes to be created out of 
    # views.  We still need to somehow mark the resulting class as read-only

    my $sth = $self->get_table_details_from_data_dictionary('%', $owner, '%', 'TABLE,VIEW');
    my @names;
    while (my $row = $sth->fetchrow_hashref) {
        my $table_name = $self->_table_name_to_use_for_metadata_objects(@$row{'TABLE_SCHEM','TABLE_NAME'});
        $table_name =~ s/"|'//g;  # Postgres puts quotes around entities that look like keywords
        next if $self->_ignore_table($table_name);
        push @names, $table_name;
    }
    return @names;
}


# A wrapper for DBI's table_info() since the DBD implementations of them
# aren't always exactly what we need in other places in the system.  Other
# subclasses can override it to get custom behavior
sub get_table_details_from_data_dictionary {
    return shift->_get_whatever_details_from_data_dictionary('table_info',@_);
}

sub _get_whatever_details_from_data_dictionary {
    my $self = shift;
    my $method = shift;

    my $dbh = $self->get_default_handle();
    return unless $dbh;

    return $dbh->$method(@_);
}

sub get_column_details_from_data_dictionary {
    return shift->_get_whatever_details_from_data_dictionary('column_info',@_);
}

sub get_foreign_key_details_from_data_dictionary {
    return shift->_get_whatever_details_from_data_dictionary('foreign_key_info',@_);
}

sub get_primary_key_details_from_data_dictionary {
    return shift->_get_whatever_details_from_data_dictionary('primary_key_info',@_);
}


sub get_table_names {
    map { $_->table_name } shift->get_tables(@_);
}

sub get_tables {
    my $self = shift;

    #my $class = shift->_singleton_class_name;
    #return UR::DataSource::RDBMS::Table->get(data_source_id => $class);
    my $ds_id;
    if (ref $self) {
        if ($self->can('id')) {
            $ds_id = $self->id;
        } else {
            $ds_id = ref $self;
        }
    } else {
        $ds_id = $self;
    }
    return UR::DataSource::RDBMS::Table->get(data_source => $ds_id);
}

sub get_nullable_foreign_key_columns_for_table {
    my $self = shift;
    my $table = shift;

    my @nullable_fk_columns;
    my @fk = $table->fk_constraints;
    for my $fk (@fk){
        my @fk_columns = UR::DataSource::RDBMS::FkConstraintColumn->get(
                             fk_constraint_name => $fk->fk_constraint_name,
                             data_source => $self->_my_data_source_id);
        for my $fk_col (@fk_columns){
            my $column_obj = UR::DataSource::RDBMS::TableColumn->get(data_source => $self->_my_data_source_id,
                                 table_name => $fk_col->table_name,
                                 column_name=> $fk_col->column_name);
            unless ($column_obj) {
                Carp::croak("Can't find TableColumn metadata object for table name ".$fk_col->table_name." column ".$fk_col->column_name." while processing foreign key constraint named ".$fk->fk_constraint_name);
            }
            if ($column_obj->nullable and $column_obj->nullable ne 'N'){
                my $col = $column_obj->column_name;
                push @nullable_fk_columns, $col;
            }
        }
    }
    return @nullable_fk_columns;
}

sub get_non_primary_key_nullable_foreign_key_columns_for_table {
    my $self = shift;
    my $table = shift;

    my @nullable_fk_columns = $self->get_nullable_foreign_key_columns_for_table($table);
    my %pk_columns = map { $_->column_name => 1} $table->primary_key_constraint_columns;
    my @non_pk_nullable_fk_columns;
    for my $fk_column (@nullable_fk_columns){
        push @non_pk_nullable_fk_columns, $fk_column unless grep { $fk_column eq $_} keys %pk_columns;
    }
    return @non_pk_nullable_fk_columns;
}

# TODO: make "env" an optional characteristic of a class attribute
# for all of the places we do this crap...

sub access_level {
    my $self = shift;
    my $env = $self->_method2env("access_level");    
    if (@_) {
        if ($self->has_default_handle) {
            Carp::confess("Cannot change the db access level for $self while connected!");
        }
        $ENV{$env} = lc(shift);
    }
    else {
        $ENV{$env} ||= "ro";
    }
    return $ENV{$env};
}

sub _method2env {
    my $class = shift;
    my $method = shift;
    unless ($method =~ /^(.*)::([^\:]+)$/) {
        $class = ref($class) if ref($class);
        $method = $class . "::" . $method;
    }
    $method =~ s/::/__/g;
    return $method;
}

sub resolve_class_name_for_table_name {
    my $self = shift->_singleton_object;
    my $qualified_table_name = shift;
    my $relation_type = shift;   # Should be 'TABLE' or 'VIEW'

    my(undef, $table_name) = $self->_resolve_owner_and_table_from_table_name($qualified_table_name);
    # When a table_name conflicts with a reserved word, it ends in an underscore.
    $table_name =~ s/_$//;

    if ($self->camel_case_table_names) {
        $table_name = UR::Value::Text->get($table_name)->to_lemac("_");
    }

    my $namespace = $self->get_namespace;
    my $vocabulary = $namespace->get_vocabulary;

    my @words;
    $vocabulary = 'UR::Vocabulary' unless eval { $vocabulary->__meta__ };
    if ($vocabulary) {
        @words = 
            map { $vocabulary->convert_to_title_case($_) } 
            map { $vocabulary->plural_to_singular($_) }
            map { lc($_) }
            split("_",$table_name);
    } else {
        @words = 
            map { ucfirst(lc($_)) }
            split("_",$table_name);
    }

    if ($self->can('_resolve_class_name_for_table_name_fixups')) {
        @words = $self->_resolve_class_name_for_table_name_fixups(@words);
    }

    my $class_name;
    my $addl;
    if ($relation_type && $relation_type =~ m/view/i) {
        $addl = 'View::';
    } else {
        # Should just be for tables, temp tables, etc
        $addl = '';
    }
    $class_name = $namespace . "::" . $addl . join("",@words);

    if (substr($class_name, -6) eq '::Type') {
        # Don't overwrite class metadata objects for a table called 'type'
        $class_name .= 'Table';
        $self->warning_message("Class for table $table_name will be $class_name");
    }

    return $class_name;
}

sub resolve_type_name_for_table_name {
    my $self = shift->_singleton_object;
    my $table_name = shift;

    if ($self->camel_case_table_names) {
        $table_name = UR::Value::Text->get($table_name)->to_lemac("_");
    }
    
    my $namespace = $self->get_namespace;
    my $vocabulary = $namespace->get_vocabulary;
    $vocabulary = 'UR::Vocabulary' unless eval { $vocabulary->__meta__ };

    my $vocab_obj = eval { $vocabulary->__meta__ };
    my @words =         
    (
        (
            map { $vocabulary->plural_to_singular($_) }
            map { lc($_) }
            split("_",$table_name)
        )
    );

    my $type_name =  join(" ",@words);
    return $type_name;
}

sub resolve_property_name_for_column_name {
    my $self = shift->_singleton_object;
    my $column_name = shift;

    if ($self->camel_case_column_names) {
        $column_name = UR::Value::Text->get($column_name)->to_lemac("_");
    }
    my @words =
        map { lc($_) }
        split("_",$column_name);

    my $type_name =  join("_",@words);
    return $type_name;
}

sub _get_or_create_table_meta {
	my $self = shift;

	my ($data_source, 
		$qualified_table_name,
		$db_table_name,
		$creation_method,
		$table_data,
		$revision_time) = @_;
	
        my $data_source_id = $self->_my_data_source_id;	
	my $table_object = UR::DataSource::RDBMS::Table->get(data_source => $data_source_id,
	                                                     table_name  => $qualified_table_name);
	if ($table_object) {
	    # Already exists, update the existing entry
	    # Instead of deleting and recreating the table object (the old way),
	    # modify its attributes in-place.  The name can't change but all the other
	    # stuff might.
	    $table_object->table_type($table_data->{TABLE_TYPE});
	    $table_object->data_source($data_source->class);
	    $table_object->remarks($table_data->{REMARKS});
	    $table_object->last_object_revision($revision_time) if ($table_object->__changes__());

	} else {
	    # Create a brand new one from scratch

	    $table_object = UR::DataSource::RDBMS::Table->$creation_method(
	        table_name => $qualified_table_name,
	        table_type => $table_data->{TABLE_TYPE},
	        data_source => $data_source_id,
	        remarks => $table_data->{REMARKS},
	        last_object_revision => $revision_time,
	    );
	    unless ($table_object) {
	        Carp::confess("Failed to $creation_method table object for $db_table_name");
	    }
	}
	
	return $table_object;
}

sub refresh_database_metadata_for_table_name {
    my ($self,$qualified_table_name, $creation_method) = @_;

    $creation_method ||= 'create';

    # this must be on or before the actual data dictionary queries
    my $revision_time = $UR::Context::current->now();

    # The class definition can specify a table name as <schema>.<table_name> to override the
    # data source's default schema/owner.
    my($ds_owner,$db_table_name) = $self->_resolve_owner_and_table_from_table_name($qualified_table_name);

    my $data_source_id = $self->_my_data_source_id;

    my $table_object = $self->_get_or_create_table_metadata_for_refresh($ds_owner, $db_table_name, $qualified_table_name, $creation_method, $revision_time);
    return unless $table_object;

    # We'll count a table object as changed even if any of the columns,
    # FKs, etc # were changed
    my $data_was_changed_for_this_table = $self->_update_column_metadata_for_refresh($ds_owner, $db_table_name, $qualified_table_name, $creation_method, $revision_time, $table_object);

    if ($self->_update_foreign_key_metadata_for_refresh($ds_owner, $db_table_name, $qualified_table_name, $creation_method, $revision_time, $table_object)) {
        $data_was_changed_for_this_table = 1;
    }

    if ($self->_update_primary_key_metadata_for_refresh($ds_owner, $db_table_name, $qualified_table_name, $creation_method, $revision_time, $table_object)) {
        $data_was_changed_for_this_table = 1;
    }

    if ($self->_update_unique_constraint_metadata_for_refresh($ds_owner, $db_table_name, $qualified_table_name, $creation_method, $revision_time, $table_object)) {
        $data_was_changed_for_this_table = 1;
    }

    $table_object->last_object_revision($revision_time) if ($data_was_changed_for_this_table);

    # Determine the ER type.
    # We have 'validation item', 'entity', and 'bridge'

    my $column_count = scalar($table_object->column_names) || 0;
    my $pk_column_count = scalar($table_object->primary_key_constraint_column_names) || 0;
    my $constraint_count = scalar($table_object->fk_constraint_names) || 0;

    if ($column_count == 1 and $pk_column_count == 1) {
        $table_object->er_type('validation item');
    }
    else {
        if ($constraint_count == $column_count) {
            $table_object->er_type('bridge');
        }
        else {
            $table_object->er_type('entity');
        }
    }

    return $table_object;
}

sub _get_or_create_table_metadata_for_refresh {
    my($self, $ds_owner, $db_table_name, $qualified_table_name, $creation_method, $revision_time) = @_;

    my $table_sth = $self->get_table_details_from_data_dictionary('%', $ds_owner, $db_table_name, "TABLE,VIEW");
    my $table_data = $table_sth->fetchrow_hashref();
    unless ($table_data && %$table_data) {
        #$self->error_message("No data for table $table_name in data source $self.");
        return;
    }

    my $table_object = $self->_get_or_create_table_meta(
                                    $self,
                                    $qualified_table_name,
                                    $db_table_name,
                                    $creation_method,
                                    $table_data,
                                    $revision_time);
    return $table_object;
}

sub _update_column_metadata_for_refresh {
    my($self, $ds_owner, $db_table_name, $qualified_table_name, $creation_method, $revision_time, $table_object) = @_;

    my $data_was_changed_for_this_table = 0;
    my $data_source_id = $self->_my_data_source_id;

    # mysql databases seem to require you to actually put in the database name in the first arg
    my $db_name = ($self->can('db_name')) ? $self->db_name : '%';
    my $column_sth = $self->get_column_details_from_data_dictionary($db_name, $ds_owner, $db_table_name, '%');
    unless ($column_sth) {
        $self->error_message("Error getting column data for table $db_table_name in data source $self.");
        return;
    }
    my $all_column_data = $column_sth->fetchall_arrayref({});
    unless (@$all_column_data) {
        $self->error_message("No column data for table $db_table_name in data source $data_source_id");
        return;
    }

    my %columns_to_delete = map {$_->column_name, $_}
                                UR::DataSource::RDBMS::TableColumn->get(
                                    table_name  => $qualified_table_name,
                                    data_source => $data_source_id);


    for my $column_data (@$all_column_data) {

        #my $id = $table_name . '.' . $column_data->{COLUMN_NAME}
        $column_data->{'COLUMN_NAME'} =~ s/"|'//g;  # Postgres puts quotes around things that look like keywords

        delete $columns_to_delete{$column_data->{'COLUMN_NAME'}};

        my $column_obj = UR::DataSource::RDBMS::TableColumn->get(table_name  => $qualified_table_name,
                                                                 data_source => $data_source_id,
                                                                 column_name => $column_data->{'COLUMN_NAME'});
        if ($column_obj) {
            # Already exists, change the attributes
            $column_obj->data_source($table_object->{data_source});
            $column_obj->data_type($column_data->{TYPE_NAME});
            $column_obj->nullable(substr($column_data->{IS_NULLABLE}, 0, 1));
            $column_obj->data_length($column_data->{COLUMN_SIZE});
            $column_obj->remarks($column_data->{REMARKS});
            if ($column_obj->__changes__()) {
                $column_obj->last_object_revision($revision_time);
                $data_was_changed_for_this_table = 1;
            }

        } else {
            # It's new, create it from scratch

            $column_obj = UR::DataSource::RDBMS::TableColumn->$creation_method(
                column_name => $column_data->{COLUMN_NAME},
                table_name  => $qualified_table_name,
                data_source => $table_object->{data_source},

                data_type   => $column_data->{TYPE_NAME},
                nullable    => substr($column_data->{IS_NULLABLE}, 0, 1),
                data_length => $column_data->{COLUMN_SIZE},
                remarks     => $column_data->{REMARKS},
                last_object_revision => $revision_time,
            );

            $data_was_changed_for_this_table = 1;
        }

        unless ($column_obj) {
            Carp::confess("Failed to create a column ".$column_data->{'COLUMN_NAME'}." for table $db_table_name");
        }
    }

    for my $to_delete (values %columns_to_delete) {
        #$self->status_message("Detected column " . $to_delete->column_name . " has gone away.");
        $to_delete->delete;
        $data_was_changed_for_this_table = 1;
    }

    return $data_was_changed_for_this_table;
}

sub _update_foreign_key_metadata_for_refresh {
    my($self, $ds_owner, $db_table_name, $qualified_table_name, $creation_method, $revision_time, $table_object) = @_;

    my $data_was_changed_for_this_table = 0;
    my $data_source_id = $self->_my_data_source_id;

    # Make a note of what FKs exist in the Meta DB involving this table
    my @fks_in_meta_db = UR::DataSource::RDBMS::FkConstraint->get(data_source => $data_source_id,
                                                                  table_name  => $qualified_table_name);
    push @fks_in_meta_db, UR::DataSource::RDBMS::FkConstraint->get(data_source  => $data_source_id,
                                                                   r_table_name => $qualified_table_name);
    my %fks_in_meta_db_by_fingerprint;
    foreach my $fk ( @fks_in_meta_db ) {
        my $fingerprint = $self->_make_foreign_key_fingerprint($fk);
        $fks_in_meta_db_by_fingerprint{$fingerprint} = $fk;
    }

    # constraints on this table against columns in other tables

    my $fk_sth = $self->get_foreign_key_details_from_data_dictionary('', $ds_owner, $db_table_name, '', '', '');

    my %fk;     # hold the fk constraints that this invocation of foreign_key_info created

    my @constraints;
    my %fks_in_real_db;
    if ($fk_sth) {
        while (my $data = $fk_sth->fetchrow_hashref()) {

            foreach ( qw( FK_NAME FK_TABLE_NAME FKTABLE_NAME UK_TABLE_NAME PKTABLE_NAME FK_COLUMN_NAME FKCOLUMN_NAME UK_COLUMN_NAME PKCOLUMN_NAME ) ) {
                next unless defined($data->{$_});
                # Postgres puts quotes around things that look like keywords
                $data->{$_} =~ s/"|'//g;
            }

            my $constraint_name = $data->{'FK_NAME'};
            my $fk_table_name = $self->_table_name_to_use_for_metadata_objects(
                                        $data->{FK_TABLE_SCHEM} || $data->{FKTABLE_SCHEM},
                                        $data->{'FK_TABLE_NAME'} || $data->{'FKTABLE_NAME'});
            my $r_table_name = $self->_table_name_to_use_for_metadata_objects(
                                        $data->{UK_TABLE_SCHEM} || $data->{PKTABLE_SCHEM},
                                        $data->{'UK_TABLE_NAME'} || $data->{'PKTABLE_NAME'});
            my $fk_column_name = $data->{'FK_COLUMN_NAME'}
                                 || $data->{'FKCOLUMN_NAME'};
            my $r_column_name = $data->{'UK_COLUMN_NAME'}
                                || $data->{'PKCOLUMN_NAME'};

            # MySQL returns primary key info with foreign_key_info()!?
            # They show up here with no $r_table_name or $r_column_name
            next unless ($r_table_name and $r_column_name);

            my $fk = UR::DataSource::RDBMS::FkConstraint->get(fk_constraint_name => $constraint_name,
                                                              table_name         => $fk_table_name,
                                                              data_source        => $data_source_id,
                                                              r_table_name       => $r_table_name
                                                          );

            unless ($fk) {
                $fk = UR::DataSource::RDBMS::FkConstraint->$creation_method(
                    fk_constraint_name => $constraint_name,
                    table_name      => $fk_table_name,
                    r_table_name    => $r_table_name,
                    data_source     => $table_object->{data_source},
                    last_object_revision => $revision_time,
                );

                $fk{$fk->id} = $fk;
                $data_was_changed_for_this_table = 1;
            }

            if ($fk{$fk->id}) {
                my %fkcol_params = ( fk_constraint_name => $constraint_name,
                                     table_name      => $fk_table_name,
                                     column_name     => $fk_column_name,
                                     r_table_name    => $r_table_name,
                                     r_column_name   => $r_column_name,
                                     data_source     => $table_object->{data_source},
                                   );
                my $fkcol = UR::DataSource::RDBMS::FkConstraintColumn->get(%fkcol_params);
                unless ($fkcol) {
                    $fkcol = UR::DataSource::RDBMS::FkConstraintColumn->$creation_method(%fkcol_params);
                }
            }

            my $fingerprint = $self->_make_foreign_key_fingerprint($fk);
            $fks_in_real_db{$fingerprint} = $fk;

            push @constraints, $fk;
        }
    }

    # get foreign_key_info the other way
    # constraints on other tables against columns in this table

    my $fk_reverse_sth = $self->get_foreign_key_details_from_data_dictionary('', '', '', '', $ds_owner, $db_table_name);

    %fk = ();   # resetting this prevents data_source referencing
    # tables from fouling up their fk objects


    if ($fk_reverse_sth) {
        while (my $data = $fk_reverse_sth->fetchrow_hashref()) {

            foreach ( qw( FK_NAME FK_TABLE_NAME FKTABLE_NAME UK_TABLE_NAME PKTABLE_NAME FK_COLUMN_NAME FKCOLUMN_NAME UK_COLUMN_NAME PKCOLUMN_NAME PKTABLE_SCHEM FKTABLE_SCHEM UK_TABLE_SCHEM FK_TABLE_SCHEM) ) {
                next unless defined($data->{$_});
                # Postgres puts quotes around things that look like keywords
                $data->{$_} =~ s/"|'//g;
            }

            my $constraint_name = $data->{'FK_NAME'} || '';
            my $fk_table_name = $self->_table_name_to_use_for_metadata_objects(
                                        $data->{FK_TABLE_SCHEM} || $data->{FKTABLE_SCHEM},
                                        $data->{'FK_TABLE_NAME'} || $data->{'FKTABLE_NAME'});
            my $r_table_name = $self->_table_name_to_use_for_metadata_objects(
                                        $data->{UK_TABLE_SCHEM} || $data->{PKTABLE_SCHEM},
                                        $data->{'UK_TABLE_NAME'} || $data->{'PKTABLE_NAME'});
            my $fk_column_name = $data->{'FK_COLUMN_NAME'}
                                 || $data->{'FKCOLUMN_NAME'};
            my $r_column_name = $data->{'UK_COLUMN_NAME'}
                                || $data->{'PKCOLUMN_NAME'};

            # MySQL returns primary key info with foreign_key_info()?!
            # They show up here with no $r_table_name or $r_column_name
            next unless ($r_table_name and $r_column_name);

            my $fk = UR::DataSource::RDBMS::FkConstraint->get(fk_constraint_name => $constraint_name,
                                                              table_name         => $fk_table_name,
                                                              r_table_name       => $r_table_name,
                                                              data_source        => $table_object->{'data_source'},
                                                          );
            unless ($fk) {
                $fk = UR::DataSource::RDBMS::FkConstraint->$creation_method(
                    fk_constraint_name => $constraint_name,
                    table_name      => $fk_table_name,
                    r_table_name    => $r_table_name,
                    data_source     => $table_object->{data_source},
                    last_object_revision => $revision_time,
                );
                unless ($fk) {
                    ##$DB::single = 1;
                    1;
                }
                $fk{$fk->fk_constraint_name} = $fk;
                $data_was_changed_for_this_table = 1;
            }

            if ($fk{$fk->fk_constraint_name}) {
                my %fkcol_params = ( fk_constraint_name => $constraint_name,
                                     table_name      => $fk_table_name,
                                     column_name     => $fk_column_name,
                                     r_table_name    => $r_table_name,
                                     r_column_name   => $r_column_name,
                                     data_source     => $table_object->{data_source},
                                 );
                unless ( UR::DataSource::RDBMS::FkConstraintColumn->get(%fkcol_params) ) {
                    UR::DataSource::RDBMS::FkConstraintColumn->$creation_method(%fkcol_params);
                }
            }


            my $fingerprint = $self->_make_foreign_key_fingerprint($fk);
            $fks_in_real_db{$fingerprint} = $fk;

            push @constraints, $fk;
        }
    }

    # Find FKs still in the Meta db that don't exist in the real database anymore
    foreach my $fingerprint ( keys %fks_in_meta_db_by_fingerprint ) {
        unless ($fks_in_real_db{$fingerprint}) {
            my $fk = $fks_in_meta_db_by_fingerprint{$fingerprint};
            my @fk_cols = $fk->get_related_column_objects();
            $_->delete foreach @fk_cols;
            $fk->delete;
        }
    }

    return $data_was_changed_for_this_table;
}

sub _update_primary_key_metadata_for_refresh {
    my($self, $ds_owner, $db_table_name, $qualified_table_name, $creation_method, $revision_time, $table_object) = @_;

    my $data_was_changed_for_this_table = 0;
    my $data_source_id = $self->_my_data_source_id;

    my $pk_sth = $self->get_primary_key_details_from_data_dictionary(undef, $ds_owner, $db_table_name);

    if ($pk_sth) {
        my @new_pk;
        while (my $data = $pk_sth->fetchrow_hashref()) {
            $data->{'COLUMN_NAME'} =~ s/"|'//g;  # Postgres puts quotes around things that look like keywords
            my $pk = UR::DataSource::RDBMS::PkConstraintColumn->get(
                table_name  => $qualified_table_name,
                data_source => $data_source_id,
                column_name => $data->{'COLUMN_NAME'},
            );
            if ($pk) {
                # Since the rank/order is pretty much all that might change, we
                # just delete and re-create these.
                # It's a no-op at save time if there are no changes.
                $pk->delete;
            }

            push @new_pk, [
                            table_name => $qualified_table_name,
                            data_source => $data_source_id,
                            column_name => $data->{'COLUMN_NAME'},
                            rank => $data->{'KEY_SEQ'} || $data->{'ORDINAL_POSITION'},
                        ];
        }

        for my $data (@new_pk) {
            my $pk = UR::DataSource::RDBMS::PkConstraintColumn->$creation_method(@$data);
            unless ($pk) {
                $self->error_message("Failed to create primary key @$data");
                return;
            }
        }
    }
    return $data_was_changed_for_this_table;
}

sub _update_unique_constraint_metadata_for_refresh {
    my($self, $ds_owner, $db_table_name, $qualified_table_name, $creation_method, $revision_time, $table_object) = @_;

    my $data_was_changed_for_this_table = 0;
    my $data_source_id = $self->_my_data_source_id;

    if (my $uc = $self->get_unique_index_details_from_data_dictionary($ds_owner, $db_table_name)) {
        my %uc = %$uc;   # make a copy we can manipulate in case $uc is shared or read-only

        # check for redundant unique constraints
        # there may be both an index and a constraint

        for my $uc_name_1 ( keys %uc ) {

            my $uc_columns_1 = $uc{$uc_name_1}
                or next;
            my $uc_columns_1_serial = join ',', sort @$uc_columns_1;

            for my $uc_name_2 ( keys %uc ) {
                next if ( $uc_name_2 eq $uc_name_1 );
                my $uc_columns_2 = $uc{$uc_name_2}
                    or next;
                my $uc_columns_2_serial = join ',', sort @$uc_columns_2;

                if ( $uc_columns_2_serial eq $uc_columns_1_serial ) {
                    delete $uc{$uc_name_1};
                }
            }
        }

        # compare primary key constraints to unique constraints
        my $pk_columns_serial =
            join(',',
                sort map { $_->column_name }
                    UR::DataSource::RDBMS::PkConstraintColumn->get(
                        data_source => $data_source_id,
                        table_name => $qualified_table_name,
                    )
                );
        for my $uc_name ( keys %uc ) {

            # see if primary key constraint has the same name as
            # any unique constraints
            # FIXME - disabling this for now, the Meta DB dosen't track PK constraint names
            # Isn't it just as goot to check the involved columns?
            #if ( $table_object->primary_key_constraint_name eq $uc_name ) {
            #    delete $uc{$uc_name};
            #    next;
            #}

            # see if any unique constraints cover the exact same column(s) as
            # the primary key column(s)
            my $uc_columns_serial = join ',', sort @{ $uc{$uc_name} };

            if ( $pk_columns_serial eq $uc_columns_serial ) {
                delete $uc{$uc_name};
            }
        }

        # Create new UniqueConstraintColumn objects for the columns that don't exist, and delete the
        # objects if they don't apply anymore
        foreach my $uc_name ( keys %uc ) {
            my %constraint_objs =
                map { $_->column_name => $_ }
                UR::DataSource::RDBMS::UniqueConstraintColumn->get(
                    data_source => $data_source_id,
                    table_name => $qualified_table_name,
                    constraint_name => $uc_name,
                );

            foreach my $col_name ( @{$uc{$uc_name}} ) {
                if ($constraint_objs{$col_name} ) {
                    delete $constraint_objs{$col_name};
                } else {
                    my $uc = UR::DataSource::RDBMS::UniqueConstraintColumn->$creation_method(
                        data_source => $data_source_id,
                        table_name => $qualified_table_name,
                        constraint_name => $uc_name,
                        column_name => $col_name,
                    );
                    1;
                }
            }
            foreach my $obj ( values %constraint_objs ) {
                $obj->delete();
            }
        }
    }

    return $data_was_changed_for_this_table;
}

sub _make_foreign_key_fingerprint {
    my($self,$fk) = @_;

    my @column_objects_with_name = map { [ $_->column_name, $_ ] }
                                       $fk->get_related_column_objects();
    my @fk_cols = map { $_->[1] }
                  sort {$a->[0] cmp $b->[0]}
                  @column_objects_with_name;
    my $fingerprint =
        join(':',
            $fk->table_name,
            $fk->r_table_name,
            map { $_->column_name, $_->r_column_name } @fk_cols
        );
    return $fingerprint;
}


sub _resolve_owner_and_table_from_table_name {
    my($self, $table_name) = @_;

    return (undef, undef) unless $table_name;
    if ($table_name =~ m/(\w+)\.(\w+)/) {
        return($1,$2);
    }
    else {
        return($self->owner, $table_name);
    }
}

sub _resolve_table_and_column_from_column_name {
    my($self, $column_name) = @_;

    if ($column_name =~ m/(\w+)\.(\w+)$/) {
        return ($1, $2);
    } else {
        return (undef, $column_name);
    }
}

# Derived classes should define a method to return a ref to an array of hash refs
# describing all the bitmap indicies in the DB.  Each hash ref should contain
# these keys: table_name, column_name, index_name
# If the DB dosen't support bitmap indicies, it should return an empty listref
# This is used by the part that writes class defs based on the DB schema, and 
# possibly by sync_database()
# Implemented methods should take one optional argument: a table name
#
# FIXME The API for bitmap_index and unique_index methods here aren't the same as
# the other data_dictionary methods.  These two return hashrefs of massaged
# data while the others return DBI statement handles.
sub get_bitmap_index_details_from_data_dictionary {
    my $class = shift;
    Carp::confess("Class $class didn't define its own bitmap_index_info() method");
}


# Derived classes should define a method to return a ref to a hash keyed by constraint
# names.  Each value holds a listref of hashrefs containing these keys:
# CONSTRAINT_NAME and COLUMN_NAME
sub get_unique_index_details_from_data_dictionary {
    my $class = shift;
    Carp::confess("Class $class didn't define its own unique_index_info() method");
}


sub _resolve_table_name_for_class_name {
    my($self, $class_name) = @_;

    for my $parent_class_name ($class_name, $class_name->inheritance) {
        my $parent_class = $parent_class_name->__meta__; # UR::Object::Type->get(class_name => $parent_class_name);
        next unless $parent_class;
        if (my $table_name = $parent_class->table_name) {
            return $table_name;
        }
    }
    return;
}

# For when there's no metaDB info for a class' table, it walks up the
# ancestry of the class, and uses the ID properties to get the column
# names, and assumes they must be the table primary keys.
#
# From there, it guesses the sequence name
sub _resolve_sequence_name_from_class_id_properties {
    my($self, $class_name) = @_;

    my $class_meta = $class_name->__meta__;
    for my $meta ($class_meta, $class_meta->ancestry_class_metas) {
        next unless $meta->table_name;
        my @primary_keys = grep { $_ }  # Only interested in the properties with columns defined
                           map { $_->column_name }
                           $meta->direct_id_property_metas;
        if (@primary_keys > 1) {
            Carp::croak("Tables with multiple primary keys (i.e. " .
                $meta->table_name  . ": " .
                join(',',@primary_keys) .
                ") cannot have a surrogate key created from a sequence.");
        }
        elsif (@primary_keys == 1) {
            my $sequence = $self->_get_sequence_name_for_table_and_column($meta->table_name, $primary_keys[0]);
            return $sequence if $sequence;
        }
    }

}


sub _resolve_sequence_name_for_class_name {
    my($self, $class_name) = @_;

    my $table_name = $self->_resolve_table_name_for_class_name($class_name);

    unless ($table_name) {
        Carp::croak("Could not determine a table name for class $class_name");
    }

    my $table_meta = UR::DataSource::RDBMS::Table->get(
                         table_name => $table_name,
                         data_source => $self->_my_data_source_id);

    my $sequence;
    if ($table_meta) {
        my @primary_keys = $table_meta->primary_key_constraint_column_names;
        if (@primary_keys == 0) {
            Carp::croak("No primary keys found for table " . $table_name . "\n");
        }
        $sequence = $self->_get_sequence_name_for_table_and_column($table_name, $primary_keys[0]);

    } else {
        # No metaDB info... try and make a guess based on the class' ID properties
        $sequence = $self->_resolve_sequence_name_from_class_id_properties($class_name);
    }
    return $sequence;
}

our %sequence_for_class_name;
sub autogenerate_new_object_id_for_class_name_and_rule {
    # The sequences in the database are named by a naming convention which allows us to connect them to the table
    # whose surrogate keys they fill.  Look up the sequence and get a unique value from it for the object.
    # If and when we save, we should not get any integrity constraint violation errors.

    my $self = shift;
    my $class_name = shift;
    my $rule = shift;  # Not used for the moment...

    if ($self->use_dummy_autogenerated_ids) {
        return $self->next_dummy_autogenerated_id;
    }

    my $sequence = $sequence_for_class_name{$class_name} || $class_name->__meta__->id_generator;
    
    my $new_id = eval {
        # FIXME Child classes really should use the same sequence generator as its parent
        # if it doesn't specify its own.
        # It'll be hard to distinguish the case of a class meta not explicitly mentioning its
        # sequence name, but there's a sequence generator in the schema for it (the current
        # mechanism), and when we should defer to the parent's sequence...
        unless ($sequence) {
            $sequence = $self->_resolve_sequence_name_for_class_name($class_name);

            if (!$sequence) {
                Carp::croak("No identity generator found for class " . $class_name . "\n");
            }

            $sequence_for_class_name{$class_name} = $sequence;
        }

        $self->__signal_observers__('sequence_nextval', $sequence);

        $self->_get_next_value_from_sequence($sequence);
    };

    unless (defined $new_id) {
        my $dbh = $self->get_default_handle;
        $self->__signal_observers__('sequence_nextval_failed', '', $sequence, $dbh->errstr);
        no warnings 'uninitialized';
        Carp::croak("Can't get next value for sequence $sequence. Exception: $@.  DBI error: ".$dbh->errstr);
    }

    return $new_id;
}

sub _get_sequence_name_for_table_and_column {
    my($self,$table_name,$column_name) = @_;

    # The default is to take the column name (should be a primary key from a table) and
    # change the _ID at the end of the column name with _SEQ
    # if column_name is all uppercase, make the sequence name end in upper case _SEQ
    my $replacement = $column_name eq uc($column_name) ? '_SEQ' : '_seq';
    $column_name =~ s/_ID/$replacement/i;
    return $column_name;
}

sub resolve_order_by_clause {
    my($self, $query_plan) = @_;

    my $order_by_columns = $query_plan->order_by_column_list;
    return '' unless (@$order_by_columns);

    my $query_class_meta = $query_plan->class_name->__meta__;

    my @order_by_parts = map {
            my $order_by_property_meta = $query_plan->property_meta_for_column($_);
            unless ($order_by_property_meta) {
                Carp::croak("Cannot resolve property metadata for order-by column '$_' of class "
                            . $query_class_meta->class_name);
            }
            $self->_resolve_order_by_clause_for_column($_, $query_plan, $order_by_property_meta);
        }
        @$order_by_columns;

    return  'order by ' . join(', ',@order_by_parts);
}

sub _resolve_order_by_clause_for_column {
    my($self, $column_name, $query_plan) = @_;

    return $query_plan->order_by_column_is_descending($column_name)
            ? $column_name . ' DESC'
            : $column_name;
}

sub _resolve_limit_value_from_query_plan {
    my($self, $query_plan) = @_;
    return $query_plan->limit;
}

sub _resolve_offset_value_from_query_plan {
    my($self, $query_plan) = @_;
    return $query_plan->offset;
}

sub resolve_limit_offset_clause {
    my($self, $query_plan) = @_;

    my $limit_value = $self->_resolve_limit_value_from_query_plan($query_plan);
    my $limit = defined($limit_value)
                    ? sprintf('limit %d', $limit_value)
                    : '';
    my $offset = $self->_resolve_offset_value_from_query_plan($query_plan)
                    ? sprintf('offset %d', $query_plan->offset)
                    : '';

    if ($limit && $offset) {
        return join(' ', $limit, $offset);
    } else {
        return $limit || $offset;
    }
}

sub do_sql {
    my $self = shift;
    my $sql = shift;

    my $dbh = $self->get_default_handle;
    my $rv = $dbh->do($sql);
    unless ($rv) {
        $self->__signal_observers__('do_failed', 'do', $sql, $dbh->errstr);
        Carp::croak("DBI do() failed: ".$dbh->errstr);
    }
    return $rv;
}


sub create_iterator_closure_for_rule {
    my ($self, $rule) = @_; 

    my ($rule_template, @values) = $rule->template_and_values();    
    my $query_plan = $self->_resolve_query_plan($rule_template); 

    #
    # the template has general class data
    #

    my $class_name                                  = $query_plan->{class_name};

    my @lob_column_names                            = @{ $query_plan->{lob_column_names} };
    my @lob_column_positions                        = @{ $query_plan->{lob_column_positions} };    
    my $query_config                                = $query_plan->{query_config}; 

    my $post_process_results_callback               = $query_plan->{post_process_results_callback};

    #
    # the template has explicit template data
    #

    my $select_clause                               = $query_plan->{select_clause};
    my $select_hint                                 = $query_plan->{select_hint};
    my $from_clause                                 = $query_plan->{from_clause};
    my $where_clause                                = $query_plan->{where_clause};
    my $connect_by_clause                           = $query_plan->{connect_by_clause};
    my $group_by_clause                             = $query_plan->{group_by_clause};

    my $sql_params                                  = $query_plan->{sql_params};
    my $filter_specs                                = $query_plan->{filter_specs};

    my @property_names_in_resultset_order           = @{ $query_plan->{property_names_in_resultset_order} };

    # TODO: we get 90% of the way to a full where clause in the template, but 
    # actually have to build it here since ther is no way to say "in (?)" and pass an arrayref :( 
    # It _is_ possible, however, to process all of the filter specs with a constant number of params.
    # This would optimize the common case.
    my @all_sql_params = @$sql_params;
    for my $filter_spec (@$filter_specs) {
        my ($expr_sql, $operator, $value_position) = @$filter_spec;
        my $value = $values[$value_position];
        my ($more_sql, @more_params) = 
            $self->_extend_sql_for_column_operator_and_value($expr_sql, $operator, $value);

        $where_clause .= ($where_clause ? "\nand " : ($connect_by_clause ? "start with " : "where "));

        if ($more_sql) {
            $where_clause .= $more_sql;
            push @all_sql_params, @more_params;
        }
        else {
            # error
            return;
        }
    }

    # The full SQL statement for the template, besides the filter logic, is built here.    
    my $order_by_clause = $self->resolve_order_by_clause($query_plan);

    my $limit_offset_clause;
    $limit_offset_clause = $self->resolve_limit_offset_clause($query_plan) if $self->does_support_limit_offset($rule);

    my $sql = "\nselect ";
    if ($select_hint) {
        my $hint = '';
        foreach (@$select_hint) {
            $hint .= ' ' . $_;
        }
        $hint =~ s/\/\*\s?|\s?\*\///g;  # remove embedded comment marks
        $sql .= "/*$hint */ ";
    }
    $sql .= $select_clause;
    $sql .= "\nfrom $from_clause";
    $sql .= "\n$where_clause" if defined($where_clause) and length($where_clause);
    $sql .= "\n$connect_by_clause" if $connect_by_clause;
    $sql .= "\n$group_by_clause" if $group_by_clause;
    $sql .= "\n$order_by_clause" if $order_by_clause;
    $sql .= "\n$limit_offset_clause" if $limit_offset_clause;

    $self->__signal_change__('query',$sql);

    my $dbh = $self->get_default_handle;
    my $sth = $dbh->prepare($sql,$query_plan->{query_config});
    unless ($sth) {
        $self->__signal_observers__('query_failed', 'prepare', $sql, $dbh->errstr);
        $self->error_message("Failed to prepare SQL $sql\n" . $dbh->errstr . "\n");
        Carp::confess($self->error_message);
    }
    unless ($sth->execute(@all_sql_params)) {
        $self->__signal_observers__('query_failed', 'execute', $sql, $dbh->errstr);
        $self->error_message("Failed to execute SQL $sql\n" . $sth->errstr . "\n" . Data::Dumper::Dumper(\@all_sql_params) . "\n");
        Carp::confess($self->error_message);
    }

    die unless $sth;   # FIXME - this has no effect, right?  

    # buffers for the iterator
    my $next_db_row;
    my $pending_db_object_data;

    my $ur_test_fill_db = $self->alternate_db_dsn
                            &&
                            $self->_create_sub_for_copying_to_alternate_db(
                                    $self->alternate_db_dsn,
                                    $query_plan->{loading_templates}
                                );

    my $iterator = sub {
        unless ($sth) {
            ##$DB::single = 1;
            return;
        }

        $next_db_row = $sth->fetchrow_arrayref;
        #$self->__signal_change__('fetch',$next_db_row);  # FIXME: commented out because it may make fetches too slow

        unless ($next_db_row) {
            $sth->finish;
            $sth = undef;
            return;
        } 

        # this handles things like BLOBS, which have a special interface to get the 'real' data
        if ($post_process_results_callback) {
            $next_db_row = $post_process_results_callback->($next_db_row);
        }

        # this is used for automated re-testing against a private database
        $ur_test_fill_db && $ur_test_fill_db->($next_db_row);

        return $next_db_row;
    }; # end of iterator closure

    Sub::Name::subname('UR::DataSource::RDBMS::__datasource_iterator(closure)__', $iterator);
    return $iterator;
}

sub _create_sub_for_copying_to_alternate_db {
    my($self, $connect_string, $loading_templates) = @_;

    my $ds_type = $self->ur_datasource_class_for_dbi_connect_string($connect_string);
    my $dbh = $ds_type->_create_dbh_for_alternate_db($connect_string)
            || do {
                Carp::carp("Cannot connect to alternate DB for copying: $DBI::errstr");
                return sub {}
            };

    my @saving_templates = $self->_resolve_loading_templates_for_alternate_db($loading_templates);

    foreach my $tmpl ( @saving_templates ) {
        my $class_meta = $tmpl->{data_class_name}->__meta__;
        $ds_type->mk_table_for_class_meta($class_meta, $dbh);
    }

    my @inserter_for_each_table = map { $self->_make_insert_closures_for_loading_template_for_alternate_db($_, $dbh) }
                                    @saving_templates;

    # Iterate through all the inserters, prerequisites first, for each row
    # returned from the database.  Each inserter may return false, which means
    # it did not save anything to the alternate DB, for example if it
    # is asked to save an object with a dummy ID (< 0).  In that case, no
    # subsequent inserters will be processed for that row
    return Sub::Name::subname '__altdb_inserter' => sub {
        foreach my $inserter ( @inserter_for_each_table ) {
            last unless &$inserter;
        }
    };
}

sub _make_insert_closures_for_loading_template_for_alternate_db {
    my($self, $template, $dbh) = @_;

    my %seen_ids;  # don't insert the same object more than once

    my $class_name = $template->{data_class_name};
    my $class_meta = $class_name->__meta__;
    my $table_name = $class_meta->table_name;
    my $columns_string = join(', ',
                            map { $class_meta->column_for_property($_) }
                            @{ $template->{property_names} } );
    my $insert_sql = "insert into $table_name ($columns_string) values ("
                . join(',',
                    map { '?' } @{ $template->{property_names} } )
                . ')';

    my $insert_sth = $dbh->prepare($insert_sql)
        || Carp::croak("Prepare for insert on alternate DB table $table_name failed: ".$dbh->errstr);

    my $check_id_exists_sql = "select count(*) from $table_name where "
                        . join(' and ',
                                map { "$_ = ?" }
                                map { $class_meta->column_for_property($_) }
                                @{ $template->{id_property_names} });
    my $check_id_exists_sth = $dbh->prepare($check_id_exists_sql)
        || Carp::croak("Prepare for check ID select on alternate DB table $table_name failed: ".$dbh->errstr);
    my @id_column_positions = @{$template->{id_column_positions}};

    my @column_positions = @{$template->{column_positions}};

    my $id_resolver = $template->{id_resolver};
    my $check_id_is_not_null = _create_sub_to_check_if_id_is_not_null(@id_column_positions);

    my @prerequisites = $self->_make_insert_closures_for_prerequisite_tables($class_meta, $template);

    my $object_num = $template->{object_num};
    my $inserter = Sub::Name::subname "__altdb_inserter_obj${object_num}_${class_name}" => sub {
        my($next_db_row) = @_;

        my $id = $id_resolver->(@$next_db_row[@id_column_positions]);

        return if _object_was_saved_to_database_by_this_process($class_name, $id);

        if ($check_id_is_not_null->($next_db_row) and ! $seen_ids{$id}++) {
            $check_id_exists_sth->execute( @$next_db_row[@id_column_positions]);
            my($count) = @{ $check_id_exists_sth->fetchrow_arrayref() };
            unless ($count) {
                my @column_values = @$next_db_row[@column_positions];
                $insert_sth->execute(@column_values)
                    || Carp::croak("Inserting to alternate DB for $class_name failed");
            }
        }
        return 1;
    };

    return (@prerequisites, $inserter);
}



# not a method
sub _create_sub_to_check_if_id_is_not_null {
    my(@id_columns) = @_;

    return sub {
        my $next_db_row = $_[0];
        foreach my $col ( @id_columns ) {
            return 1 if defined $next_db_row->[$col];
        }
        return 0;
    };
}

my %cached_fk_data_for_table;
sub _make_insert_closures_for_prerequisite_tables {
    my($self, $class_meta, $loading_template) = @_;

    $cached_fk_data_for_table{$class_meta->table_name} ||= $self->_load_fk_data_for_class_meta($class_meta);

    my %column_idx_for_column_name;
    for (my $i = 0; $i < @{ $loading_template->{property_names} }; $i++) {
        my $column_name = $class_meta->column_for_property( $loading_template->{property_names}->[$i] );
        $column_idx_for_column_name{ $column_name }
            = $loading_template->{column_positions}->[$i];
    }

    my $class_name = $class_meta->class_name;

    return map { $self->_make_prerequisite_insert_closure_for_fk($class_name, \%column_idx_for_column_name, $_) }
            @{ $cached_fk_data_for_table{ $class_meta->table_name } };
}


sub _load_fk_data_for_class_meta {
    my($self, $class_meta) = @_;

    my ($db_owner, $table_name_without_owner) = $self->_resolve_owner_and_table_from_table_name($class_meta->table_name);

    my @fk_data;
    my $fk_sth = $self->get_foreign_key_details_from_data_dictionary('','','','', $db_owner, $table_name_without_owner);
    my %seen_fk_names;
    while( $fk_sth and my $row = $fk_sth->fetchrow_hashref ) {

        foreach my $key (qw(UK_TABLE_CAT UK_TABLE_SCHEM UK_TABLE_NAME UK_COLUMN_NAME FK_TABLE_CAT FK_TABLE_SCHEM FK_TABLE_NAME FK_COLUMN_NAME)) {
            no warnings 'uninitialized';
            $row->{$key} =~ s/"|'//g;  # Postgres puts quotes around entities that look like keywords
        }
        if (!@fk_data or $row->{ORDINAL_POSITION} == 1
            or ( $row->{FK_NAME} and !$seen_fk_names{ $row->{FK_NAME} }++)
        ) {
            # part of a new FK
            push @fk_data, [];
        }

        push @{ $fk_data[-1] }, { %$row };
    }
    return \@fk_data;
}

# return true if this list of FK columns exists for inheritance:
# this table's FKs matches the given class' ID properties, and the FK points
# to every ID property of the parent class
sub _fk_represents_inheritance {
    my($load_class_name, $fk_column_list) = @_;

    my $load_class_meta = $load_class_name->__meta__;

    my %is_pk_column_for_class = map { $_ => 1 }
                                 grep { $_ }
                                 map { $load_class_meta->column_for_property($_) }
                                 $load_class_name->__meta__->id_property_names;

    if (scalar(@$fk_column_list) != scalar(values %is_pk_column_for_class)) {
        # differing number of columns vs ID properties
        return '';
    }

    foreach my $fk ( @$fk_column_list ) {
        return '' unless $is_pk_column_for_class{ $fk->{FK_COLUMN_NAME} };
    }

    my %checked;
    foreach my $parent_class_name ( $load_class_meta->inheritance ) {
        next if ($checked{$parent_class_name}++);

        my $parent_class_meta = eval { $parent_class_name->__meta__ };
        next unless $parent_class_meta;  # for non-ur classes
        my @pk_columns_for_parent = grep { $_ }
                                    map { $parent_class_meta->column_for_property($_) }
                                    $parent_class_meta->id_property_names;
        next if (scalar(@$fk_column_list) != scalar(@pk_columns_for_parent));

        foreach my $parent_pk_column ( @pk_columns_for_parent ) {
            return '' unless $is_pk_column_for_class{ $parent_pk_column };
        }
    }

    return 1;
}

sub _make_prerequisite_insert_closure_for_fk {
    my($self, $load_class_name, $column_idx_for_column_name, $fk_column_list) = @_;

    my $pk_class_name = $self->_lookup_fk_target_class_name($fk_column_list);

    # fks for inheritance are handled inside _resolve_loading_templates_for_alternate_db
    return () if _fk_represents_inheritance($load_class_name, $fk_column_list);

    my $pk_class_meta = $pk_class_name->__meta__;

    my %pk_to_fk_column_name_map = map { @$_{'UK_COLUMN_NAME','FK_COLUMN_NAME'} }
                                   @$fk_column_list;
    my @fk_columns = map { $column_idx_for_column_name->{$_} }
                     map { $pk_to_fk_column_name_map{$_} }
                     $pk_class_meta->id_property_names;

    if (grep { !defined } @fk_columns
        or
        !@fk_columns
    ) {
        Carp::croak(sprintf(q(Couldn't determine column order for inserting prerequisites of %s with foreign key "%s" refering to table %s with columns (%s)),
            $load_class_name,
            $fk_column_list->[0]->{FK_NAME},
            $fk_column_list->[0]->{UK_TABLE_NAME},
            join(', ', map { $_->{UK_COLUMN_NAME} } @$fk_column_list)
        ));
    }

    my $id_resolver = $pk_class_meta->get_composite_id_resolver();
    my $check_id_is_not_null = _create_sub_to_check_if_id_is_not_null(@fk_columns);

    return Sub::Name::subname "__altdb_prereq_inserter_${pk_class_name}" => sub {
        my($next_db_row) = @_;
        if ($check_id_is_not_null->($next_db_row)) {
            my $id = $id_resolver->(@$next_db_row[@fk_columns]);

            return if _object_was_saved_to_database_by_this_process($pk_class_name, $id);

            # here we _do_ want to recurse back in.  That way if these prerequisites
            # have prerequisites of their own, they'll be loaded in the recursive call.
            $pk_class_name->get($id);
        }
        return 1;
    }
}

# not a method
sub _object_was_saved_to_database_by_this_process {
    my($class_name, $id) = @_;

    # Fast common case
    return 1 if exists ($objects_in_database_saved_by_this_process{$class_name})
                &&
                exists($objects_in_database_saved_by_this_process{$class_name}->{$id});

    foreach my $saved_class ( keys %objects_in_database_saved_by_this_process ) {
        next unless ($class_name->isa($saved_class) || $saved_class->isa($class_name));
        return 1 if exists($objects_in_database_saved_by_this_process{$saved_class}->{$id});
    }
    return;
}

# given a UR::DataSource::RDBMS::FkConstraint, find the table this fk refers to
# (the table with the pk_columns), then find which class goes with that table.
sub _lookup_fk_target_class_name {
    my($self, $fk_column_list) = @_;

    my $pk_owner = $fk_column_list->[0]->{UK_TABLE_SCHEM};
    my $pk_table_name = $fk_column_list->[0]->{UK_TABLE_NAME};
    my $pk_table_name_with_owner = $pk_owner ? join('.', $pk_owner, $pk_table_name) : $pk_table_name;
    my $pk_class_name = $self->_lookup_class_for_table_name( $pk_table_name_with_owner )
                        || $self->_lookup_class_for_table_name( $pk_table_name );

    unless ($pk_class_name) {
        # didn't find it.  Maybe the target class isn't loaded yet
        # try looking up the class on the other side of the FK
        # and determine which property matches this FK

        my $fk_owner = $fk_column_list->[0]->{FK_TABLE_SCHEM};
        my $fk_table_name = $fk_column_list->[0]->{FK_TABLE_NAME};
        my $fk_table_name_with_owner = $fk_owner ? join('.', $fk_owner, $fk_table_name) : $fk_table_name;

        my $fk_class_name = $self->_lookup_class_for_table_name( $fk_table_name_with_owner )
                            || $self->_lookup_class_for_table_name( $fk_table_name );
        if ($fk_class_name) {
            # get all the relation property target classes loaded
            my @relation_property_metas = grep { $_->id_by and $_->data_type  }
                                          $fk_class_name->__meta__->properties();
            foreach my $prop_meta ( @relation_property_metas ) {
                eval { $prop_meta->data_type->__meta__ };
            }

            # try looking up again
            $pk_class_name = $self->_lookup_class_for_table_name( $pk_table_name_with_owner )
                             || $self->_lookup_class_for_table_name( $pk_table_name );
        }
    }
    unless ($pk_class_name) {
        Carp::croak(
            sprintf(q(Couldn't determine class with table %s involved in foreign key "%s" from table %s with columns (%s)),
                        $pk_table_name,
                        $fk_column_list->[0]->{FK_NAME},
                        $fk_column_list->[0]->{FK_TABLE_NAME},
                        join(', ', map { $_->{FK_COLUMN_NAME} } @$fk_column_list),
                    ));
    }
    return $pk_class_name;
}

# Given a query plan's loading templates, return a new list of look-alike
# loading templates.  This new list may look different from the original
# list in the case of table inheritance: it separates out each class' table
# and the columns that goes with it.
sub _resolve_loading_templates_for_alternate_db {
    my($self, $original_loading_templates) = @_;

    my @loading_templates;
    foreach my $loading_template ( @$original_loading_templates ) {
        my $load_class_name = $loading_template->{data_class_name};

        my %column_for_property_name;
        for (my $i = 0; $i < @{ $loading_template->{property_names} }; $i++) {
            $column_for_property_name{ $loading_template->{property_names}->[$i] }
                = $loading_template->{column_positions}->[$i];
        }

        my @involved_class_metas = reverse
                                    grep { $_->table_name }
                                    $load_class_name->__meta__->all_class_metas;
        foreach my $class_meta ( @involved_class_metas ) {
            my @id_property_names = map { $_->property_name }
                                    grep { $_->column_name }
                                    $class_meta->direct_id_property_metas;
            my @id_column_positions = map { $column_for_property_name{$_} } @id_property_names;
            my @property_names = map { $_->property_name }
                                 grep { $_->column_name }
                                 $class_meta->direct_property_metas;
            my @column_positions = map { $column_for_property_name{$_} } @property_names;
            my $this_template = {
                    id_property_names   => \@id_property_names,
                    id_column_positions => \@id_column_positions,
                    property_names      => \@property_names,
                    column_positions    => \@column_positions,
                    table_alias         => $class_meta->table_name,
                    data_class_name     => $class_meta->class_name,
                    final_class_name    => $loading_template->{final_class_name},
                    object_num          => $loading_template->{object_num},
                    id_resolver         => $class_meta->get_composite_id_resolver,
                };
            push @loading_templates, $this_template
        }
    }
    return @loading_templates;
}

sub _create_dbh_for_alternate_db {
    my($self, $connect_string) = @_;

    # Support an extension of the connect string to allow user and password.
    # URI::DB supports these kinds of things, too.
    $connect_string =~ s/user=(\w+);?//;
    my $user = $1;
    $connect_string =~ s/password=(\w+);?//;
    my $password = $1;

    # Don't use $self->default_handle_class here
    # Generally, it'll be UR::DBI, which respects the setting for UR_DBI_NO_COMMIT.
    # Tests are usually run with no-commit on, and we still want to fill the
    # test db in that case
    my $handle_class = 'DBI';
    $handle_class->connect($connect_string, $user || '', $password || '', { AutoCommit => 1, PrintWarn => 0 });
}

# Create the table behind this class in the specified database.
# used by the functionality behind the UR_TEST_FILLDB env var
sub mk_table_for_class_meta {
    my($self, $class_meta, $dbh) = @_;
    return 1 unless $class_meta->has_table;

    $dbh ||= $self->get_default_handle;

    my $table_name = $class_meta->table_name();
    $self->_assure_schema_exists_for_table($table_name, $dbh);

    # we only care about properties backed up by a real column
    my @props = grep { $_->column_name } $class_meta->direct_property_metas();

    my $sql = "create table IF NOT EXISTS $table_name (";

    my @cols;
    foreach my $prop ( @props ) {
        my $col = $prop->column_name;
        my $type = $self->data_source_type_for_ur_data_type($prop->data_type);
        my $len = $prop->data_length;
        my $nullable = $prop->is_optional;

        my $string = "$col" . " " . $type;
        $string .= " NOT NULL" unless $nullable;
        push @cols, $string;
    }
    $sql .= join(',',@cols);

    my @id_cols = $class_meta->direct_id_column_names();
    $sql .= ", PRIMARY KEY (" . join(',',@id_cols) . ")" if (@id_cols);

    # Should we also check for the unique properties?

    $sql .= ")";
    unless ($dbh->do($sql) ) {
        $self->error_message("Can't create table $table_name: ".$DBI::errstr."\nSQL: $sql");
        return undef;
    }

    1;
}

sub _assure_schema_exists_for_table {
    my($self, $table_name, $dbh) = @_;

    $dbh ||= $self->get_default_handle;

    my($schema_name, undef) = $self->_extract_schema_and_table_name($table_name);
    if ($schema_name) {
        $dbh->do("CREATE SCHEMA IF NOT EXISTS $schema_name")
            || Carp::croak("Could not create schema $schema_name: ".$dbh->errstr);
    }
}

sub _extract_schema_and_table_name {
    my($self, $string) = @_;

    my($schema_name, $table_name) = $string =~ m/(.*)\.(\w+)$/;
    return ($schema_name, $table_name);
}

sub _default_sql_like_escape_string {
    return '\\';  # Most RDBMSs support an 'escape' as part of a 'like' operator, except mysql
}

sub _format_sql_like_escape_string {
    my $class = shift;
    my $escape = shift;
    return "'$escape'";
}

# This method is used when generating SQL for a rule template, in the joins
# and also on a per-query basis to turn specific values into a where clause
sub _extend_sql_for_column_operator_and_value {
    my($self, $expr_sql, $op, $val, $escape) = @_;

    my $class = $self->_sql_generation_class_for_operator($op);

    $escape ||= $self->_default_sql_like_escape_string;
    $escape = $self->_format_sql_like_escape_string($escape);
    return $class->generate_sql_for($expr_sql, $val, $escape);
}

sub _sql_generation_class_for_operator {
    my($self, $op) = @_;
    my $suffix = UR::Util::class_suffix_for_operator($op);
    my @classes = $self->inheritance;
    foreach my $class ( @classes ) {
        my $op_class_name = join('::', $class, 'Operator', $suffix);

        return $op_class_name if UR::Util::use_package_optimistically($op_class_name);
    }
    Carp::croak("Can't load SQL generation class for operator $op: $@");
}

sub _value_is_null {
    my ($class, $value) = @_;
    return 1 if not defined $value;
    return 1 if $value eq '';
    return 1 if (ref($value) eq 'HASH' and $value->{operator} eq '=' and (!defied($value->{value}) or $value->{value} eq ''));
    return 0;
}

sub _resolve_ids_from_class_name_and_sql {
    my $self = shift;

    my $class_name = shift;
    my $sql = shift;

    my $query;
    my @params;
    if (ref($sql) eq "ARRAY") {
        ($query, @params) = @{$sql};
    } else {
        $query = $sql;
    }

    my $class_meta = $class_name->__meta__;
    my @id_columns = map
                         { $class_meta->property_meta_for_name($_)->column_name } 
                         $class_meta->id_property_names;

    # query for the ids

    my $dbh = $self->get_default_handle();

    my $sth = $dbh->prepare($query);

    unless ($sth) {
        Carp::croak("Could not prepare query $query: $DBI::errstr");
    }
    unless ($sth->{NUM_OF_PARAMS} == scalar(@params)) {
        Carp::croak('The number of params supplied ('
                    . scalar(@params)
                    . ') does not match the number of placeholders (' . $sth->{NUM_OF_PARAMS}
                    . ") in the supplied sql: $query");
    }

    $sth->execute(@params);

    # After execute, we can see if the SQL contained all the required primary keys
    my @id_column_idx = map { $sth->{NAME_lc_hash}->{$_} }
                        map { lc }
                        @id_columns;
    if (grep { ! defined } @id_column_idx) {
        @id_columns  = sort @id_columns;
        my @missing_ids = sort grep { ! defined($sth->{NAME_lc_hash}->{lc($_)}) } @id_columns;
        Carp::croak("The SQL supplied is missing one or more ID columns.\n\tExpected: "
                    . join(', ', @id_columns)
                    . ' but some were missing: '
                    . join(', ', @missing_ids)
                   . " for query: $query");
    }

    my $id_resolver = $class_name->__meta__->get_composite_id_resolver();

    my $id_values = $sth->fetchall_arrayref(\@id_column_idx);
    return [ map { $id_resolver->(@$_) } @$id_values ];
}

sub _sync_database {
    my $self = shift;
    my %params = @_;

    unless (ref($self)) {
        if ($self->isa("UR::Singleton")) {
            $self = $self->_singleton_object;
        }
        else {
            die "Called as a class-method on a non-singleton datasource!";
        }
    }

    my $changed_objects = delete $params{changed_objects};
    my %objects_by_class_name;
    for my $obj (@$changed_objects) {
        my $class_name = ref($obj);
        $objects_by_class_name{$class_name} ||= [];
        push @{ $objects_by_class_name{$class_name} }, $obj;

        if ($self->alternate_db_dsn) {
            $objects_in_database_saved_by_this_process{$class_name}->{$obj->id} = 1;
        }
    }

    my $dbh = $self->get_default_handle;

    #
    # Determine what commands need to be executed on the database
    # to sync those changes, and categorize them by type and table.
    #

    # As we iterate through changes, keep track of all of the involved tables.
    my %all_tables;      # $all_tables{$table_name} = $number_of_commands;

    # Make a hash for each type of command keyed by table name.
    my %insert;          # $insert{$table_name} = [ $change1, $change2, ...];
    my %update;          # $update{$table_name} = [ $change1, $change2, ...];
    my %delete;          # $delete{$table_name} = [ $change1, $change2, ...];

    # Make a master hash referencing each of the above.
    # $explicit_commands_by_type_and_table{'insert'}{$table} = [ $change1, $change2 ...]
    my %explicit_commands_by_type_and_table = (
        'insert' => \%insert,
        'update' => \%update,
        'delete' => \%delete
    );

    # Build the above data structures.
    {
        no warnings;
        for my $class_name (sort keys %objects_by_class_name) {
            for my $obj (@{ $objects_by_class_name{$class_name} }) {
                my @commands = $self->_default_save_sql_for_object($obj);
                next unless @commands;

                for my $change (@commands)
                {
                    #$commands{$change} = $change;

                    # Example change:
                    # { type => 'update', table_name => $table_name,
                    # column_names => \@changed_cols, sql => $sql,
                    # params => \@values, class => $table_class, id => $id };

                    # There are often multiple changes per object, espeically
                    # when the object is spread across multiple tables because of
                    # inheritance.  We classify each change by the table and
                    # the class immediately associated with the table, even if
                    # the class in an abstract parent class on the object.
                    my $table_name = $change->{table_name};
                    my $id = $change->{id};                    
                    $all_tables{$table_name}++;

                    if ($change->{type} eq 'insert')
                    {
                        push @{ $insert{$table_name} }, $change;
                    }
                    elsif ($change->{type} eq 'update')
                    {
                        push @{ $update{$table_name} }, $change;
                    }
                    elsif ($change->{type} eq 'delete')
                    {
                        push @{ $delete{$table_name} }, $change;
                    }
                    else
                    {
                        print "UNKNOWN COMMAND TYPE $change->{type} $change->{sql}\n";
                    }
                }
            }
        }
    }

    # Determine which tables require a lock;

    my %tables_requiring_lock;
    for my $table_name (keys %all_tables) {
		my $table_object = $self->_get_table_object($table_name);

        unless ($table_object) {
            warn "looking up schema for RDBMS table $table_name...\n";
            $table_object = $self->refresh_database_metadata_for_table_name($table_name);
            unless ($table_object) {
                die "Failed to generate table data for $table_name!";
            }
        }

        if (my @bitmap_index_names = $table_object->bitmap_index_names) {
            my $changes;
            if ($changes = $insert{$table_name} or $changes = $delete{$table_name}) {
                $tables_requiring_lock{$table_name} = 1;
            }
            elsif (not $tables_requiring_lock{$table_name}) {
                $changes = $update{$table_name};
                my @column_names = sort map { @{ $_->{column_names} } } @$changes;
                my $last_column_name = "";
                for my $column_name (@column_names) {
                    next if $column_name eq $last_column_name;
                    my $column_obj = UR::DataSource::RDBMS::TableColumn->get(
                        data_source => $table_object->data_source,
                        table_name  => $table_name,
                        column_name => $column_name,
                    );
                    if ($column_obj->bitmap_index_names) {
                        $tables_requiring_lock{$table_name} = 1;
                        last;
                    }
                    $last_column_name = $column_name;
                }
            }
        }
    }

    #
    # Make a mapping of prerequisites for each command,
    # and a reverse mapping of dependants for each command.
    #

    my %all_table_commands;
    my %prerequisites;
    my %dependants;

    for my $table_name (keys %all_tables) {
		my $table = $self->_get_table_object($table_name);

        my @fk = $table->fk_constraints;

        my $matched_table_name;
        if ($insert{$table_name})
        {
            $matched_table_name = 1;
            $all_table_commands{"insert $table_name"} = 1;
        }

        if ($update{$table_name})
        {
            $matched_table_name = 1;
            $all_table_commands{"update $table_name"} = 1;
        }

        if ($delete{$table_name})
        {
            $matched_table_name = 1;
            $all_table_commands{"delete $table_name"} = 1;
        }

        unless ($matched_table_name) {
            Carp::carp("Possible metadata inconsistency: A change on table $table_name was not an insert, update or delete!");
        }

        my $tmparray;

        # handle multiple differnt ops on the same table
        if ($insert{$table_name} and $update{$table_name}) {
            # insert before update
            $tmparray = $prerequisites{"update $table_name"}{"insert $table_name"} ||= [];
            $tmparray = $dependants{"insert $table_name"}{"update $table_name"} ||= [];
        }
        if ($delete{$table_name} and $update{$table_name}) {
            # update before delete
            $tmparray = $prerequisites{"delete $table_name"}{"update $table_name"} ||= [];
            $tmparray = $dependants{"update $table_name"}{"delete $table_name"} ||= [];
        }
        if ($delete{$table_name} and $insert{$table_name} and not $update{$table_name}) {
            # delete before insert
            $tmparray = $prerequisites{"insert $table_name"}{"delete $table_name"} ||= [];
            $tmparray = $dependants{"delete $table_name"}{"insert $table_name"} ||= [];
        }
        
        # Go through the constraints.
        for my $fk (@fk)
        {
            my $r_table_name = $fk->r_table_name;

            # RULES:
            # insert r_table_name       before insert table_name
            # insert r_table_name       before update table_name
            # delete table_name         before delete r_table_name
            # update table_name         before delete r_table_name

            if ($insert{$table_name} and $insert{$r_table_name})
            {
                $tmparray = $prerequisites{"insert $table_name"}{"insert $r_table_name"} ||= [];
                push @$tmparray, $fk;

                $tmparray = $dependants{"insert $r_table_name"}{"insert $table_name"} ||= [];
                push @$tmparray, $fk;
            }

            if ($update{$table_name} and $insert{$r_table_name})
            {
                $tmparray = $prerequisites{"update $table_name"}{"insert $r_table_name"} ||= [];
                push @$tmparray, $fk;

                $tmparray = $dependants{"insert $r_table_name"}{"update $table_name"} ||= [];
                push @$tmparray, $fk;
            }

            if ($delete{$r_table_name} and $delete{$table_name})
            {
                $tmparray = $prerequisites{"delete $r_table_name"}{"delete $table_name"} ||= [];
                push @$tmparray, $fk;

                $tmparray = $dependants{"delete $table_name"}{"delete $r_table_name"} ||= [];
                push @$tmparray, $fk;
            }

            if ($delete{$r_table_name} and $update{$table_name})
            {
                $tmparray = $prerequisites{"delete $r_table_name"}{"update $table_name"} ||= [];
                push @$tmparray, $fk;

                $tmparray = $dependants{"update $table_name"}{"delete $r_table_name"} ||= [];
                push @$tmparray, $fk;
            }
        }
    }

    #
    # Use the above mapping to build an ordered list of general commands.
    # Note that the general command is something like "insert EMPLOYEES",
    # while the explicit command is an exact insert statement with params.
    #

    my @general_commands_in_order;
    my %self_referencing_table_commands;

    my %all_unresolved = %all_table_commands;
    my $unresolved_count;
    my $last_unresolved_count = 0;
    my @ready_to_add = ();

    while ($unresolved_count = scalar(keys(%all_unresolved)))
    {
        if ($unresolved_count == $last_unresolved_count)
        {
            # We accomplished nothing on the last iteration.
            # We are in an infinite loop unless something is done.
            # Rather than die with an error, issue a warning and attempt to
            # brute-force the sync.

            # Process something with minimal deps as a work-around.
            my @ordered_by_least_number_of_prerequisites =
                sort{ scalar(keys(%{$prerequisites{$a}})) <=>  scalar(keys(%{$prerequisites{$b}})) }
                grep { $prerequisites{$_} }
                keys %all_unresolved;

            @ready_to_add = ($ordered_by_least_number_of_prerequisites[0]);
            warn "Circular dependency! Pushing @ready_to_add to brute-force the save.\n";
            #print STDERR Data::Dumper::Dumper(\%objects_by_class_name, \%prerequisites, \%dependants ) . "\n";
        }
        else
        {
            # This is the normal case.  It is either the first iteration,
            # or we are on additional iterations with some progress made
            # in the last iteration.

            # Find commands which have no unresolved prerequisites.
            @ready_to_add =
                grep { not $prerequisites{$_} }
                keys %all_unresolved;

            # If there are none of the above, find commands
            # with only self-referencing prerequisites.
            unless (@ready_to_add)
            {
                # Find commands with only circular dependancies.
                @ready_to_add =
                    # The circular prerequisite must be the only prerequisite on the table.
                    grep { scalar(keys(%{$prerequisites{$_}})) == 1 }

                    # The prerequisite must be the same as the the table itself.
                    grep { $prerequisites{$_}{$_} }

                    # There must be prerequisites for the given table,
                    grep { $prerequisites{$_} }

                    # Look at all of the unresolved table commands.
                    keys %all_unresolved;

                # Note this for below.
                # It records the $fk object which is circular.
                for my $table_command (@ready_to_add)
                {
                    $self_referencing_table_commands{$table_command} = $prerequisites{$table_command}{$table_command};
                }
            }
        }

        # Record our current unresolved count for comparison on the next iteration.
        $last_unresolved_count = $unresolved_count;

        for my $db_command (@ready_to_add)
        {
            # Put it in the list.
            push @general_commands_in_order, $db_command;

            # Delete it from the main hash of command/table pairs
            # for which dependencies are not resolved.
            delete $all_unresolved{$db_command};

            # Find anything which depended on this command occurring first
            # and remove this command from that command's prerequisite list.
            for my $dependant (keys %{ $dependants{$db_command} })
            {
                # Tell it to take us out of its list of prerequisites.
                delete $prerequisites{$dependant}{$db_command} if $prerequisites{$dependant};

                # Get rid of the prereq entry if it is empty;
                delete $prerequisites{$dependant} if (keys(%{ $prerequisites{$dependant} }) == 0);
            }

            # Note that nothing depends on this command any more since it has been queued.
            delete $dependants{$db_command};
        }
    }

    # Go through the ordered list of general commands (ie "insert TABLE_NAME")
    # and build the list of explicit commands.
    my @explicit_commands_in_order;
    for my $general_command (@general_commands_in_order)
    {
        my ($dml_type,$table_name) = split(/\s+/,$general_command);


        if (my $circular_fk_list = $self_referencing_table_commands{$general_command})
        {
            # A circular foreign key requires that the
            # items be inserted in a specific order.
            my (@rcol_sets) = 
                map { [ $_->column_names ] } 
                @$circular_fk_list;

            # Get the IDs and objects which need to be saved.
            my @cmds = @{ $explicit_commands_by_type_and_table{$dml_type}{$table_name} };
            my @ids =  map { $_->{id} } @cmds;

            # my @objs = $cmds[0]->{class}->is_loaded(\@ids);
            my $is_loaded_class =
                ($dml_type eq 'delete')
                ? $cmds[0]->{class}->ghost_class
                : $cmds[0]->{class};

            my @objs = $is_loaded_class->is_loaded(\@ids);
            my %objs = map { $_->id => $_ } @objs;

            # Produce the explicit command list in dep order.
            my %unsorted_cmds = map { $_->{id} => $_ } @cmds;
            my $add;
            my @local_explicit_commands;
            my %adding;
            $add = sub {
                my ($cmd) = @_;
                if ($adding{$cmd}) {
                    ##$DB::single = 1;
                    Carp::confess("Circular foreign key!") unless $main::skip_croak;
                }
                $adding{$cmd} = 1;
                my $obj = $objs{$cmd->{id}};
                my $class_meta = $obj->class->__meta__;
                for my $rcol_set (@rcol_sets) {
                    my @ordered_values = map { $obj->$_ }
                                         map { $class_meta->property_for_column($_) }
                                         @$rcol_set;
                    my $pid = $obj->class->__meta__->resolve_composite_id_from_ordered_values(@ordered_values);
                    if (defined $pid) {   # This recursive foreign key dep may have been optional
                        my $pcmd = delete $unsorted_cmds{$pid};
                        $add->($pcmd) if $pcmd;
                    }
                }
                delete $adding{$cmd};
                push @local_explicit_commands, $cmd;
            };
            for my $cmd (@cmds) {
                next unless $unsorted_cmds{$cmd->{id}};
                $add->(delete $unsorted_cmds{$cmd->{id}});
            }

            if ($dml_type eq 'delete') {
                @local_explicit_commands = reverse @local_explicit_commands;
            }

            push @explicit_commands_in_order, @local_explicit_commands;
        }
        else
        {
            # Order is irrelevant on non-self-referencing tables.
            push @explicit_commands_in_order, @{ $explicit_commands_by_type_and_table{$dml_type}{$table_name} };
        }
    }

    my %table_objects_by_class_name;
    my %column_objects_by_class_and_column_name;

    # Make statement handles.
    my %sth;
    for my $cmd (@explicit_commands_in_order)
    {
        my $sql = $cmd->{sql};

        unless ($sth{$sql})
        {
            my $class_name = $cmd->{class};

            # get the db handle to use for this class
            my $dbh = $cmd->{dbh};
            my $sth = $dbh->prepare($sql);
            $sth{$sql} = $sth;

            unless ($sth)
            {
                $self->__signal_observers__('commit_failed', 'prepare', $sql, $dbh->errstr);
                $self->error_message("Error preparing SQL:\n$sql\n" . $dbh->errstr . "\n");
                return;
            }

            my $tables = $table_objects_by_class_name{$class_name};
            my $class_object = $class_name->__meta__;
            unless ($tables) {                
                my $tables;
                my @all_table_names = $class_object->all_table_names;                
                for my $table_name (@all_table_names) {                    
					my $table = $self->_get_table_object($table_name);
					
                    push @$tables, $table;
                    $column_objects_by_class_and_column_name{$class_name} ||= {};             
                    my $columns = $column_objects_by_class_and_column_name{$class_name};
                    unless (%$columns) {
                        for my $column ($table->columns) {
                            $columns->{$column->column_name} = $column;
                        }
                    }
                }
                $table_objects_by_class_name{$class_name} = $tables;
            }

            my @column_objects;
            foreach my $column_name ( @{ $cmd->{column_names} } ) {
                my $column = $column_objects_by_class_and_column_name{$class_name}->{$column_name};
                unless ($column) {
                    FIND_IN_ANCESTRY:
                    for my $ancestor_class_name ($class_object->ancestry_class_names) {
                        $column = $column_objects_by_class_and_column_name{$ancestor_class_name}->{$column_name};
                        if ($column) {
                            $column_objects_by_class_and_column_name{$class_name}->{$column_name} = $column;
                            last FIND_IN_ANCESTRY;
                        }
                    }
                }
                # If we didn't find a column object, then $column will be undef
                # and we'll have to guess what it looks like
                push @column_objects, $column;
            }

            # print "Column Types: @column_types\n";

            $self->_alter_sth_for_selecting_blob_columns($sth,\@column_objects);
        }
    }

    # DBI docs say that if AutoCommit is on, then starting a transaction will temporarily
    # turn it off.  When the handle gets commit() or rollback(), it will get turned back
    # on automatically by DBI
    if ($dbh->{AutoCommit}
        and
        ! eval { $dbh->begin_work; 1 }
    ) {
        Carp::croak(sprintf('Cannot begin transaction on data source %s: %s',
                            $self->id, $dbh->errstr));
    }

    # Set a savepoint if possible.
    my $savepoint;
    if ($self->can_savepoint) {
        $savepoint = $self->_last_savepoint;
        if ($savepoint) {
            $savepoint++;
        }
        else {
            $savepoint=1;
        }
        my $sp_name = "sp".$savepoint;
        unless ($self->set_savepoint($sp_name)) {
            $self->error_message("Failed to set a savepoint on "
                . $self->class
                . ": "
                . $dbh->errstr
            );
            return;
        }
        $self->_last_savepoint($savepoint);
    }

    # Do any explicit table locking necessary.
    if (my @tables_requiring_lock = sort keys %tables_requiring_lock) {
        $self->debug_message("Locking tables: @tables_requiring_lock.");
        my $max_failed_attempts = 10;
        for my $table_name (@tables_requiring_lock) {
			my $table = $self->_get_table_object($table_name);
            my $dbh = $table->dbh;
            my $sth = $dbh->prepare("lock table $table_name in exclusive mode");
            my $failed_attempts = 0;
            my @err;
            for (1) {
                unless ($sth->execute) {
                    $failed_attempts++;
                    $self->warning_message(
                        "Failed to lock $table_name (attempt # $failed_attempts): "
                        . $sth->errstr
                    );
                    push @err, $sth->errstr;
                    unless ($failed_attempts >= $max_failed_attempts) {
                        redo;
                    }
                }
            }
            if ($failed_attempts > 1) {
                my $err = join("\n",@err);
                if ($failed_attempts >= $max_failed_attempts) {
                    $self->error_message(
                        "Could not obtain an exclusive table lock on table "
                        . $table_name . " after $failed_attempts attempts"
                    );
                    $self->rollback_to_savepoint($savepoint);
                    return;
                }
            }
        }
    }

    # Execute the commands in the correct order.

    my @failures;
    my $last_failure_count = 0;
    my @previous_failure_sets;

    # If there are failures, we fall-back to brute force and send
    # a message to support to debug the inefficiency.
    my $skip_fault_tolerance_check = 1;

    for (1) {
        @failures = ();
        for my $cmd (@explicit_commands_in_order) {
            unless ($sth{$cmd->{sql}}->execute(@{$cmd->{params}}))
            {
                my $dbh = $cmd->{dbh};
                # my $dbh = UR::Context->resolve_data_source_for_object($cmd->{class})->get_default_handle;
                $self->__signal_observers__('commit_failed', 'execute', $cmd->{sql}, $dbh->errstr);
                push @failures, {cmd => $cmd, error_message => $sth{$cmd->{sql}}->errstr};
                last if $skip_fault_tolerance_check;
            }
            $sth{$cmd->{sql}}->finish();
        }

        if (@failures) {
            # There have been some failures.  In case the error has to do with
            # a failure to correctly determine dependencies in the code above,
            # we will retry the set of failed commands.  This repeats as long
            # as some progress is made on each iteration.
            if ( (@failures == $last_failure_count) or $skip_fault_tolerance_check) {
                # We've tried this exact set of comands before and failed.
                # This is a real error.  Stop retrying and report.
                for my $error (@failures)
                {
                    $self->error_message($self->id . ": Error executing SQL:\n$error->{cmd}{sql}\n" .
                                         "PARAMS: " . join(', ',map { defined($_) ? "'$_'" : '(undef)' } @{$error->{cmd}{params}}) . "\n" .
                                         $error->{error_message} . "\n");
                }
                last;
            }
            else {
                # We've failed, but we haven't retried this exact set of commands
                # and found the exact same failures.  This is either the first failure,
                # or we had failures before and had success on the last brute-force
                # approach to sorting commands.  Try again.
                push @previous_failure_sets, \@failures;
                @explicit_commands_in_order = map { $_->{cmd} } @failures;
                $last_failure_count = scalar(@failures);
                $self->warning_message("RETRYING SAVE");
                redo;
            }
        }
    }

    # Rollback to savepoint if there are errors.
    if (@failures) {
        if (!$savepoint or $savepoint eq "NONE") {
            # A failure on a database which does not support savepoints.
            # We must rollback the entire transacation.
            # This is only a problem for a mixed raw-sql and UR::Object environment.
            $dbh->rollback;
        }
        else {
            $self->_reverse_sync_database();
        }
        # Return false, indicating failure.
        return;
    }

    unless ($self->_set_specified_objects_saved_uncommitted($changed_objects)) {
        Carp::confess("Error setting objects to a saved state after sync_database.  Exiting.");
        return;
    }

    if (exists $params{'commit_on_success'} and ($params{'commit_on_success'} eq '1')) {
        # Commit the current transaction.
        # The handles will automatically update their objects to 
        # a committed state from the one set above.
        # It will throw an exception on failure.
        $dbh->commit;
    }

    # Though we succeeded, see if we had to use the fault-tolerance code to
    # do so, and warn software support.  This should never occur.
    if (@previous_failure_sets) {
        my $msg = "Dependency failure saving: " . Dumper(\@explicit_commands_in_order)
                  . "\n\nThe following error sets were produced:\n"
                  . Dumper(\@previous_failure_sets) . "\n\n" . Carp::cluck() . "\n\n";

        $self->warning_message($msg);
        $UR::Context::current->send_email(
            To => UR::Context::Process->support_email,
            Subject => 'sync_database dependency sort failure',
            Message => $msg
        ) or $self->warning_message("Failed to send error email!");
    }

    return 1;
}

# this is necessary for overriding data source names when looking up table metadata with 
# bifurcated oracle/postgres syncs in testing.
sub _my_data_source_id {
	my $self = shift;
	return ref($self) ? $self->id : $self;
}

sub _get_table_object {
	my($self, $ds_table) = @_;
	
    my $data_source_id = $self->_my_data_source_id;
	
    my $table = UR::DataSource::RDBMS::Table->get(
                    table_name => $ds_table,
                    data_source => $data_source_id)
                ||
                UR::DataSource::RDBMS::Table->get(
                    table_name => $ds_table,
                    data_source => 'UR::DataSource::Meta');
    return $table;
}

sub _alter_sth_for_selecting_blob_columns {
    my($self, $sth, $column_objects) = @_;

    return;
}


sub _reverse_sync_database {
    my $self = shift;

    unless ($self->can_savepoint) {
        # This will not respect manual DML
        # Developers must not use this back door on non-savepoint databases.
        $self->get_default_handle->rollback;
        return "NONE";
    }

    my $savepoint = $self->_last_savepoint;
    unless ($savepoint) {
        Carp::confess("No savepoint set!");
    }

    my $sp_name = "sp".$savepoint;
    unless ($self->rollback_to_savepoint($sp_name)) {
        $self->error_message("Error removing savepoint $savepoint " . $self->get_default_handle->errstr);
        return 1;
    }

    $self->_last_savepoint(undef);
    return $savepoint;
}

# Given a table object and a list of primary key values, return
# a where clause to match a row.  Some values may be undef (NULL)
# and it properly writes "column IS NULL".  As a side effect, the 
# @$values list is altered to remove the undef value
sub _matching_where_clause {
    my($self,$table_obj,$values) = @_;

    unless ($table_obj) {
        Carp::confess("No table passed to _matching_where_clause for $self!");
    }

    my @pks = $table_obj->primary_key_constraint_column_names;

    my @where;
    # in @$values, the updated data values always seem to be before the where clause
    # values but still in the right order, so start at the right place
    my $skip = scalar(@$values) - scalar(@pks);
    for (my($pk_idx,$values_idx) = (0,$skip); $pk_idx < @pks;) {
        if (defined $values->[$values_idx]) {
            push(@where, $pks[$pk_idx] . ' = ?');
            $pk_idx++; 
            $values_idx++;
        } else {
            push(@where, $pks[$pk_idx] . ' IS NULL');
            splice(@$values, $values_idx, 1);
            $pk_idx++;
        }
    }

    return join(' and ', @where);
}

sub _id_values_for_primary_key {
    my ($self,$table_obj,$object_to_save) = @_;

    unless ($table_obj && $object_to_save) {
        Carp::confess("Both table and object_to_save should be passed for $self!");
    }

    my $class_obj; # = $object_to_save->__meta__;
    foreach my $possible_class_obj ($object_to_save->__meta__->all_class_metas) {
        next unless ($possible_class_obj->table_name);

        if ( $possible_class_obj->table_name eq $table_obj->table_name ) {

            $class_obj = $possible_class_obj;
            last;
        }
    }
    unless (defined $class_obj) {
        Carp::croak("Can't find class object with table " . $table_obj->table_name . " while searching inheritance for object of class ".$self->class);
    }

    my @pk_cols = $table_obj->primary_key_constraint_column_names;
    my %pk_cols = map { $_ => 1 } @pk_cols;
    # this previously went to $object_to_save->__meta__, which is nearly the same thing but not quite
    my @values = $class_obj->resolve_ordered_values_from_composite_id($object_to_save->id);
    my @columns = $class_obj->direct_id_column_names;

    foreach my $col_in_class ( @columns ) {
        unless ($pk_cols{$col_in_class}) {
            my $table_name = $table_obj->table_name;
            my $class_name = $class_obj->class_name;
            Carp::croak("While committing, metadata for table $table_name does not match class $class_name.\n  Table primary key columns are " .
                        join(', ',@pk_cols) .
                        "\n  class ID property columns " .
                        join(', ', @columns));
        }
    }

    my $i=0;    
    my %column_index = map { $_ => $i++ } @columns;
    my @bad_pk_cols = grep { ! exists($column_index{$_}) } @pk_cols;
    if (@bad_pk_cols) {
        my $table_name = $table_obj->table_name;
        Carp::croak("Metadata for table $table_name is inconsistent with class ".$class_obj->class_name.".\n"
                    . "Column(s) named " . join(',',@bad_pk_cols) . " appear as primary key constraint columns, "
                    . "but do not appear as ID column names.  Check the dd_pk_constraint_columns data in the "
                    . "MetaDB and the ID properties of the class definition");
    }

    my @id_values_in_pk_order = @values[@column_index{@pk_cols}];

    return @id_values_in_pk_order;
}

sub _lookup_class_for_table_name {
    my $self = shift;
    my $table_name = shift;

    my @table_class_obj = grep { $_->class_name !~ /::Ghost$/ } UR::Object::Type->is_loaded(data_source_id => $self->id, table_name => $table_name);

    # Like _get_table_object, we need to look in the data source and if the
    # object wasn't found then in 'UR::DataSource::Meta' in order to mimic
    # behavior elsewhere.
    unless (@table_class_obj) {
        @table_class_obj = grep { $_->class_name !~ /::Ghost$/ } UR::Object::Type->is_loaded(data_source_id => 'UR::DataSource::Meta', table_name => $table_name);
    }
    my $table_class;
    my $table_class_obj;
    if (@table_class_obj == 1) {
        $table_class_obj = $table_class_obj[0]; 
        return $table_class_obj->class_name; 
    } elsif (@table_class_obj > 1) {
        Carp::confess("Got more than one class object for $table_name, this should not happen: @table_class_obj");
    }
}


sub _default_save_sql_for_object {
    my $self = shift;        
    my $object_to_save = shift;
    my %params = @_;

    my ($class,$id) = ($object_to_save->class, $object_to_save->id);

    my $class_object = $object_to_save->__meta__;

    # This object may have uncommitted changes already saved.  
    # If so, work from the last saved data.
    # Normally, we go with the last committed data.

    my $compare_version = ($object_to_save->{'db_saved_uncommitted'} ? 'db_saved_uncommitted' : 'db_committed');

    # Determine what the overall save action for the object is,
    # and get a specific change summary if we're doing an update.

    my ($action,$change_summary);
    if ($object_to_save->isa('UR::Object::Ghost'))
    {
        $action = 'delete';
    }                    
    elsif ($object_to_save->{$compare_version})
    {
        $action = 'update';
        $change_summary = $object_to_save->property_diff($object_to_save->{$compare_version});         
    }
    else
    {
        $action = 'insert';
    }

    # Handle each table.  There is usually only one, unless,
    # there is inheritance within the schema.
    my @save_table_names = 
        grep { not /[^\w\.]/ } # remove any views from the list
        List::MoreUtils::uniq($class_object->all_table_names);

    @save_table_names = reverse @save_table_names unless ($object_to_save->isa('UR::Entity::Ghost'));

    my @commands;
    for my $table_name (@save_table_names)
    {
        # Get general info on the table we're working-with.                

        my $dsn = ref($self) ? $self->_my_data_source_id: $self;  # The data source name

		my $table = $self->_get_table_object($table_name);

        unless ($table) {
            $self->generate_schema_for_class_meta($class_object,1);
            # try again...
			$table = $self->_get_table_object($table_name);
            unless ($table) {
                Carp::croak("No table $table_name found for data source $dsn");
            }
        }        

        my $table_class = $self->_lookup_class_for_table_name($table_name);
        if (!$table_class) {
            Carp::croak("NO CLASS FOR $table_name\n");
        }        
	

        my $data_source = $UR::Context::current->resolve_data_source_for_object($object_to_save);
        unless ($data_source) {
            Carp::croak("Couldn't resolve data source for object ".$object_to_save->__display_name__.":\n"
                        . Data::Dumper::Dumper($object_to_save));
        }

        # The "action" now can vary on a per-table basis.

        my $table_action = $action;

        # Handle re-classification of objects.
        # We skip deletion and turn insert into update in these cases.

        if ( ($table_class ne $class) and ( ($table_class . "::Ghost") ne $class) ) {
            if ($action eq 'delete') {
                # see if the object we're deleting actually exists reclassified
                my $replacement = $table_class->is_loaded($id);
                if ($replacement) {
                    next;
                }
            }
            elsif ($action eq 'insert') {
                # see if the object we're inserting is actually a reclassification
                # of a pre-existing object
                my $replacing = $table_class->ghost_class->is_loaded($id);
                if ($replacing) {
                    $table_action = 'update';
                    $change_summary = $object_to_save->property_diff(%$replacing);
                }
            }
        }

        # Determine the $sql and @values needed to save this object.

        if ($table_action eq 'delete')
        {
            # A row loaded from the database with its object deleted.
            # Delete the row in the database.

            #grab fk_constraints so we can undef non primary-key nullable fks before delete
            my @non_pk_nullable_fk_columns = $self->get_non_primary_key_nullable_foreign_key_columns_for_table($table);

            my @values = $self->_id_values_for_primary_key($table,$object_to_save);
            my $where = $self->_matching_where_clause($table, \@values);

            if (@non_pk_nullable_fk_columns) {
                #generate an update statement to set nullable fk columns to null pre delete
                my $update_sql = "UPDATE ";
                $update_sql .= "$table_name SET ";
                $update_sql .= join(", ", map { "$_=?"} @non_pk_nullable_fk_columns);
                $update_sql .= " WHERE $where";
                my @update_values = @values;
                for (@non_pk_nullable_fk_columns){
                    unshift @update_values, undef;
                }
                my $update_command = { type         => 'update',
                                       table_name   => $table_name,
                                       column_names => \@non_pk_nullable_fk_columns,
                                       sql          => $update_sql,
                                       params       => \@update_values,
                                       class        => $table_class,
                                       id           => $id,
                                       dbh          => $data_source->get_default_handle
                                     };
                push @commands, $update_command;
            }


            my $sql = " DELETE FROM ";
            $sql .= "$table_name WHERE $where";

            push @commands, { type         => 'delete',
                              table_name   => $table_name,
                              column_names => undef,
                              sql          => $sql,
                              params       => \@values,
                              class        => $table_class,
                              id           => $id,
                              dbh          => $data_source->get_default_handle
                           };

            #print Data::Dumper::Dumper \@commands;
        }                    
        elsif ($table_action eq 'update')
        {
            # Pre-existing row.  
            # Update in the database if there are columns which have changed.

            my $changes_for_this_table;
            if (@save_table_names > 1)
            {
                my @changes = 
                    map { $_ => $change_summary->{$_} }
                    grep { $class_object->table_for_property($_) eq $table_name }
                    keys %$change_summary;
                $changes_for_this_table = {@changes};
            }
            else
            {
                # Shortcut and use the overall changes summary when
                # there is only one table.
                $changes_for_this_table = $change_summary;
            }

            my(@changed_cols,@values);
            for my $property (keys %$changes_for_this_table)
            {
                my $column_name = $class_object->column_for_property($property); 
                Carp::croak("No column in table $table_name for property $property?") unless $column_name;
                push @changed_cols, $column_name;
                push @values, $changes_for_this_table->{$property};
            }

            if (@changed_cols)
            {
                my @changed_values = map { defined ($_) && $object_to_save->can($_)
                                           ? $object_to_save->$_
                                           : undef }
                                     map { $class_object->property_for_column($_) || undef }
                                     @changed_cols;

                my @id_values = $self->_id_values_for_primary_key($table,$object_to_save);

                if (scalar(@changed_cols) != scalar(@changed_values)) {
                   no warnings 'uninitialized';
                   my $mapping = join("\n", map { "  $_ => ".$class_object->property_for_column($_) } @changed_cols);
                   Carp::croak("Column count mismatch while updating table $table_name.  "
                               . "The table metadata expects to see ".scalar(@changed_cols)
                               . " columns, but ".scalar(@values)." were retrieved from the object of type "
                               . $object_to_save->class . ".\nCurrent column => property mapping:\n$mapping\n"
                               . "There is probably a mismatch between the database column metadata and the column_name "
                               . "property metadata");
                }

                my @all_values = ( @changed_values, @id_values );
                my $where = $self->_matching_where_clause($table, \@all_values);

                my $sql = " UPDATE ";
                $sql .= "$table_name SET " . join(",", map { "$_ = ?" } @changed_cols) . " WHERE $where";

                push @commands, { type         => 'update',
                                  table_name   => $table_name,
                                  column_names => \@changed_cols,
                                  sql          => $sql,
                                  params       => \@all_values,
                                  class        => $table_class,
                                  id           => $id,
                                  dbh          => $data_source->get_default_handle
                                };
            }
        }
        elsif ($table_action eq 'insert')
        {
            # An object without a row in the database.
            # Insert into the database.

            my @changed_cols = reverse sort
                               map { $class_object->column_for_property($_->property_name) }
                               grep { ! $_->is_transient }
                               grep { ($class_object->table_for_property($_->property_name) || '') eq $table_name }
                               grep { $_->column_name }
                               List::MoreUtils::uniq($class_object->all_property_metas());

            my $sql = " INSERT INTO ";
            $sql .= "$table_name (" 
                    . join(",", @changed_cols) 
                    . ") VALUES (" 
                    . join(',', split(//,'?' x scalar(@changed_cols))) . ")";

            my @values = map {
                           # when there is a column but no property, use NULL as the value
                           defined($_) && $object_to_save->can($_)
                           ? $object_to_save->$_
                           : undef
                       }
                       map { $class_object->property_for_column($_) || undef }
                      (@changed_cols);

            if (scalar(@changed_cols) != scalar(@values)) {
               no warnings 'uninitialized';
               my $mapping = join("\n", map { "  $_ => ".$class_object->property_for_column($_) } @changed_cols);
               Carp::croak("Column count mismatch while inserting into table $table_name.  "
                           . "The table metadata expects to see ".scalar(@changed_cols)
                           . " columns, but ".scalar(@values)." were retrieved from the object of type "
                           . $object_to_save->class . ".\nCurrent column => property mapping:\n$mapping\n"
                           . "There is probably a mismatch between the database column metadata and the column_name "
                           . "property metadata");
            }

            #grab fk_constraints so we can undef non primary-key nullable fks before delete
            my %non_pk_nullable_fk_columns = map { $_ => 1 }
                                                 $self->get_non_primary_key_nullable_foreign_key_columns_for_table($table);

            if (%non_pk_nullable_fk_columns){
                my @insert_values;
                my %update_values;
                for (my $i = 0; $i < @changed_cols; $i++){
                    my $col = $changed_cols[$i];
                    if ($non_pk_nullable_fk_columns{$col}) {
                        push @insert_values, undef;
                        $update_values{$col} = $values[$i];
                    }else{
                        push @insert_values, $values[$i];
                    }
                }

                push @commands, { type         => 'insert',
                                  table_name   => $table_name,
                                  column_names => \@changed_cols,
                                  sql          => $sql,
                                  params       => \@insert_values,
                                  class        => $table_class,
                                  id           => $id,
                                  dbh          => $data_source->get_default_handle
                                };

                ##$DB::single = 1;
                # %update_values can be empty if the Metadb is out of date, and has a fk constraint column
                # that no longer exists in the class metadata
                if (%update_values) {
                    my @pk_values = $self->_id_values_for_primary_key($table, $object_to_save);
                    my $where = $self->_matching_where_clause($table, \@pk_values);
                
                    my @update_cols = keys %update_values;
                    my @update_values = ((map {$update_values{$_}} @update_cols), @pk_values);
                
                

                    my $update_sql = " UPDATE ";
                    $update_sql .= "$table_name SET ". join(",", map { "$_ = ?" } @update_cols) . " WHERE $where";

                    push @commands, { type         => 'update',
                                      table_name   => $table_name,
                                      column_names => \@update_cols,
                                      sql          => $update_sql,
                                      params       => \@update_values,
                                      class        => $table_class,
                                      id           => $id,
                                      dbh          => $data_source->get_default_handle
                                    };
                }
            }
            else 
            {
                push @commands, { type         => 'insert',
                                  table_name   => $table_name,
                                  column_names => \@changed_cols,
                                  sql          => $sql,
                                  params       => \@values,
                                  class        => $table_class,
                                  id           => $id,
                                  dbh          => $data_source->get_default_handle
                                };
            }

        }
        else
        {
            die "Unknown action $table_action for $object_to_save" . Dumper($object_to_save) . "\n";
        }

    } # next table 

    return @commands;
}

sub _do_on_default_dbh {
    my $self = shift;
    my $method = shift;

    return 1 unless $self->has_default_handle();

    my $dbh = $self->get_default_handle;
    unless ($dbh->$method(@_)) {
        $self->error_message("DataSource ".$self->get_name." failed to $method: ".$dbh->errstr);
        return undef;
    }

    return 1;
}

sub commit {
    my $self = shift;
    if ($self->has_default_handle) {
        if (my $dbh = $self->get_default_handle) {
            if ($dbh->{AutoCommit} ) {
                $self->debug_message('Ignoring ineffective commit because AutoCommit is on');
                return 1;
            }
        }
    }
    $self->_do_on_default_dbh('commit', @_);
}

sub rollback {
    my $self = shift;
    if ($self->has_default_handle) {
        if (my $dbh = $self->get_default_handle) {
            if ($dbh->{AutoCommit} ) {
                $self->debug_message('Ignoring ineffective rollback because AutoCommit is on');
                return 1;
            }
        }
    }
    $self->_do_on_default_dbh('rollback', @_);
}

sub disconnect {
    my $self = shift;
    if (! ref($self) and $self->isa('UR::Singleton')) {
        $self = $self->_singleton_object;
    }
    my $rv = $self->_do_on_default_dbh('disconnect', @_);
    $self->__invalidate_get_default_handle__;
    $self->is_connected(0);
    return $rv;
}

sub _generate_class_data_for_loading {
    my ($self, $class_meta) = @_;

    my $parent_class_data = $self->SUPER::_generate_class_data_for_loading($class_meta);

    my @class_hierarchy = ($class_meta->class_name,$class_meta->ancestry_class_names);
    my $order_by_columns;
    do {
        my @id_column_names;    
        for my $inheritance_class_name (@class_hierarchy) {
            my $inheritance_class_object = UR::Object::Type->get($inheritance_class_name);
            unless ($inheritance_class_object->table_name) {
                next;
            }
            @id_column_names =
                map { 
                    my $t = $inheritance_class_object->table_name;
                    ($t) = ($t =~ /(\S+)\s*$/); 
                    $t . '.' . $_ 
                }
                grep { defined }
                map { 
                    my $p = $inheritance_class_object->property_meta_for_name($_);
                    Carp::croak("No property $_ found for " . $inheritance_class_object->class_name) unless $p;
                    $p->column_name;
                } 
                map { $_->property_name }
                grep { $_->column_name }
                $inheritance_class_object->direct_id_property_metas;

            last if (@id_column_names);
        }
        $order_by_columns = \@id_column_names;
    };

    my @all_table_properties;
    my @direct_table_properties;
    my $first_table_name = $class_meta->first_table_name;
    my $sub_classification_method_name;
    my ($sub_classification_meta_class_name, $subclassify_by);

    my @base_joins;
    my $prev_table_name;
    my $prev_id_column_name;

    my %seen;
    for my $co ( $class_meta, @{ $parent_class_data->{parent_class_objects} } ) {   
        next if $seen{ $co->class_name }++;
        my $table_name = $co->first_table_name;
        next unless $table_name;

        #$first_table_name ||= $co->table_name;
        $sub_classification_method_name ||= $co->sub_classification_method_name;
        $sub_classification_meta_class_name ||= $co->sub_classification_meta_class_name;
        $subclassify_by   ||= $co->subclassify_by;

        my $sort_sub = sub ($$) { return $_[0]->property_name cmp $_[1]->property_name };
        push @all_table_properties, 
            map { [$co, $_, $table_name, 0 ] }
            sort $sort_sub
            grep { (defined $_->column_name && $_->column_name ne '') or
                (defined $_->calculate_sql && $_->calculate_sql ne '') }
            UR::Object::Property->get( class_name => $co->class_name );

        @direct_table_properties = @all_table_properties if $class_meta eq $co;
    }

    my @lob_column_names;
    my @lob_column_positions;
    my $pos = 0;
    for my $class_property (@all_table_properties) {
        my ($sql_class,$sql_property,$sql_table_name) = @$class_property;
        my $data_type = $sql_property->data_type || '';             
        if ($data_type =~ /LOB$/i) {
            push @lob_column_names, $sql_property->column_name;
            push @lob_column_positions, $pos;
        }
        $pos++;
    }

    my $query_config; 
    my $post_process_results_callback;
    if (@lob_column_names) {
        $query_config = $self->_prepare_for_lob;
        if ($query_config) {
            my $results_row_arrayref;
            my @lob_ids;
            my @lob_values;
            $post_process_results_callback = sub { 
                $results_row_arrayref = shift;
                my $dbh = $self->get_default_handle;
                @lob_ids = @$results_row_arrayref[@lob_column_positions];
                @lob_values = $self->_post_process_lob_values($dbh,\@lob_ids);
                @$results_row_arrayref[@lob_column_positions] = @lob_values;
                $results_row_arrayref;
            };
        }
    }

    my $class_data = {
        %$parent_class_data,

        all_table_properties                => \@all_table_properties,
        direct_table_properties             => \@direct_table_properties,

        first_table_name                    => $first_table_name,
        sub_classification_method_name      => $sub_classification_method_name,
        sub_classification_meta_class_name  => $sub_classification_meta_class_name,
        subclassify_by    => $subclassify_by,

        base_joins                          => \@base_joins,   
        order_by_columns                    => $order_by_columns,

        lob_column_names                    => \@lob_column_names,
        lob_column_positions                => \@lob_column_positions,

        query_config                        => $query_config,
        post_process_results_callback       => $post_process_results_callback,
    };

    return $class_data;
}

sub _select_clause_for_table_property_data {
    my $self = shift;
    my $column_data = $self->_select_clause_columns_for_table_property_data(@_);
    my $select_clause = join(', ',@$column_data);
    return $select_clause;
}

sub _select_clause_columns_for_table_property_data {
    my $self = shift;

    my @column_data;
    for my $class_property (@_) {
        my ($sql_class,$sql_property,$sql_table_name) = @$class_property;
        $sql_table_name ||= $sql_class->table_name;
        my ($select_table_name) = ($sql_table_name =~ /(\S+)\s*$/s);

        # FIXME - maybe a better way would be for these sql-calculated properties, the column_name()
        # or maybe some other related property name) is actually calculated, so this logic
        # gets encapsulated in there?
        if (my $sql_function = $sql_property->calculate_sql) {
            my @calculate_from = ref($sql_property->calculate_from) eq 'ARRAY' ? @{$sql_property->calculate_from} : ( $sql_property->calculate_from );
            foreach my $sql_column_name ( @calculate_from ) {
                $sql_function =~ s/($sql_column_name)/$sql_table_name\.$1/g;
            }
            push(@column_data, $sql_function);
        } else {
            push(@column_data, $select_table_name . "." . $sql_property->column_name);
        }
    }
    return \@column_data;
}


# These seem to be standard for most RDBMSs
my %ur_data_type_for_vendor_data_type = (
     # DB type      UR Type
    'VARCHAR'          => ['Text', undef],
    'CHAR'             => ['Text', 1],
    'CHARACTER'        => ['Text', 1],
    'XML'              => ['Text', undef],

    'INTEGER'          => ['Integer', undef],
    'UNSIGNED INTEGER' => ['Integer', undef],
    'SIGNED INTEGER'   => ['Integer', undef],
    'INT'              => ['Integer', undef],
    'LONG'             => ['Integer', undef],
    'BIGINT'           => ['Integer', undef],
    'SMALLINT'         => ['Integer', undef],

    'FLOAT'            => ['Number', undef],
    'NUMBER'           => ['Number', undef],
    'DOUBLE'           => ['Number', undef],
    'DECIMAL'          => ['Number', undef],
    'REAL'             => ['Number', undef],

    'BOOL'             => ['Boolean', undef],
    'BOOLEAN'          => ['Boolean', undef],
    'BIT'              => ['Boolean', undef],

    'DATE'             => ['DateTime', undef],
    'DATETIME'         => ['DateTime', undef],
    'TIMESTAMP'        => ['DateTime', undef],
    'TIME'             => ['DateTime', undef],
);

sub normalize_vendor_type {
    my ($class, $type) = @_;
    $type = uc($type);
    $type =~ s/\(\d+\)$//;
    return $type;
}

sub ur_data_type_for_data_source_data_type {
    my($class,$type) = @_;

    $type = $class->normalize_vendor_type($type);
    my $urtype = $ur_data_type_for_vendor_data_type{$type};
    unless (defined $urtype) {
        $urtype = $class->SUPER::ur_data_type_for_data_source_data_type($type);
    }
    return $urtype;
}


sub _vendor_data_type_for_ur_data_type {
    return ( TEXT        => 'VARCHAR',
             STRING      => 'VARCHAR',
             INTEGER     => 'INTEGER',
             DECIMAL     => 'INTEGER',
             NUMBER      => 'FLOAT',
             BOOLEAN     => 'INTEGER',
             DATETIME    => 'DATETIME',
             TIMESTAMP   => 'TIMESTAMP',
             __default__ => 'VARCHAR',
         );
}

sub data_source_type_for_ur_data_type {
    my($class, $type) = @_;

    if ($type and $type->isa('UR::Value')) {
        ($type) =~ m/UR::Value::(\w+)/;
    }
    my %types = $class->_vendor_data_type_for_ur_data_type();
    return $type && $types{uc($type)}
            ? $types{uc($type)}
            : $types{__default__};
}


# Given two properties with different 'is', return a 2-element list of
# SQL functions to apply to perform a comparison in the DB.  0th element
# gets applied to the left side, 1st element to the right.  This implementation
# uses printf formats where the %s gets fed an SQL expression like
# "table.column"
#
# SQLite basically treats everything as strings, so needs no conversion.
# other DBs will have their own conversions
#
# $sql_clause will be one of "join", "where"
sub cast_for_data_conversion {
    my($class, $left_type, $right_type, $operator, $sql_clause) = @_;

    return ('%s', '%s');
}

sub do_after_fork_in_child {
    my $self = shift->_singleton_object;
    my $dbhs = $self->_all_dbh_hashref;
    for my $k (keys %$dbhs) {
        if ($dbhs->{$k}) {
            $dbhs->{$k}->{InactiveDestroy} = 1;
            delete $dbhs->{$k};
        }
    }

    # reset our state back to being "disconnected"
    $self->__invalidate_get_default_handle__;
    $self->_all_dbh_hashref({});
    $self->is_connected(0);

    # now force a reconnect
    $self->get_default_handle();
    return 1;
}

sub parse_view_and_alias_from_inline_view {
    my($self, $sql) = @_;

    return ($sql and $sql =~ m/^(.*?)(?:\s+as)?\s+(\w+)\s*$/s)
        ? ($1, $2)
        : ();
}

1;

=pod

=head1 NAME

UR::DataSource::RDBMS - Abstract base class for RDBMS-type data sources

=head1 DESCRIPTION

This class implements the interface UR uses to query RDBMS databases with
DBI.  It encapsulates the system's knowledge of classes/properties relation
to tables/columns, and how to generate SQL to create, retrieve, update and
delete table rows that represent object instances.

=head1 SEE ALSO

UR::DataSource, UR::DataSource::Oracle, UR::DataSource::Pg, UR::DataSource::SQLite
UR::DataSource::MySQL

=cut

package UR::DataSource::Oracle;
use strict;
use warnings;

require UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => 'UR::DataSource::Oracle',
    is => ['UR::DataSource::RDBMS'],
    is_abstract => 1,
);

sub driver { "Oracle" }

sub owner { shift->_singleton_object->login }

sub can_savepoint { 1 }  # Oracle supports savepoints inside transactions

sub does_support_limit_offset { 0 }

sub does_support_recursive_queries { 'connect by' };

sub set_savepoint {
my($self,$sp_name) = @_;

    my $dbh = $self->get_default_handle;
    my $sp = $dbh->quote($sp_name);
    $dbh->do("savepoint $sp_name");
}


sub rollback_to_savepoint {
my($self,$sp_name) = @_;

    my $dbh = $self->get_default_handle;
    my $sp = $dbh->quote($sp_name);
    $dbh->do("rollback to $sp_name");
}


my $DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS';
my $TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SSXFF';
sub _set_date_format {
    my $self = shift;

    foreach my $sql ("alter session set NLS_DATE_FORMAT = '$DATE_FORMAT'",
                    "alter session set NLS_TIMESTAMP_FORMAT = '$TIMESTAMP_FORMAT'"
    ) {
        $self->do_sql($sql);
    }
}


*_init_created_dbh = \&init_created_handle;
sub init_created_handle {
    my ($self, $dbh) = @_;
    return unless defined $dbh;
    $dbh->{LongTruncOk} = 0;

    $self->_set_date_format();

    return $dbh;
}

sub _dbi_connect_args {
    my @args = shift->SUPER::_dbi_connect_args(@_);
    $args[3]{ora_module_name} = (UR::Context::Process->get_current->prog_name || $0);
    return @args;
}

sub _prepare_for_lob {
    { ora_auto_lob => 0 }
}

sub _post_process_lob_values {
    my ($self, $dbh, $lob_id_arrayref) = @_;
    return 
        map { 
            if (defined($_)) {
                my $length = $dbh->ora_lob_length($_);
                my $data = $dbh->ora_lob_read($_, 1, $length);
                # TODO: bind to a file for items of a certain size to save RAM.
                # Special work with tying a scalar to the file?
                $data;
            }
            else {
                undef;
            }
        } @$lob_id_arrayref;
}

sub _ignore_table {
    my $self = shift;
    my $table_name = shift;
    return 1 if $table_name =~ /\$/;
}

sub get_table_last_ddl_times_by_table_name { 
    my $self = shift;
    my $sql =  qq|
        select object_name table_name, last_ddl_time
        from all_objects o        
        where o.owner = ?
        and (o.object_type = 'TABLE' or o.object_type = 'VIEW')
    |;
    my $data = $self->get_default_handle->selectall_arrayref(
        $sql, 
        undef, 
        $self->owner
    );
    return { map { @$_ } @$data };
};

sub _get_next_value_from_sequence {
my($self,$sequence_name) = @_;

    # we may need to change how this db handle is gotten
    my $dbh = $self->get_default_handle;
    my $new_id = $dbh->selectrow_array("SELECT " . $sequence_name . ".nextval from DUAL");

    if ($dbh->err) {
        die "Failed to prepare SQL to generate a column id from sequence: $sequence_name.\n" . $dbh->errstr . "\n";
        return;
    }

    return $new_id;
}

sub get_bitmap_index_details_from_data_dictionary {
    my($self, $table_name) = @_;
    my $sql = qq(
        select c.table_name,c.column_name,c.index_name
        from all_indexes i join all_ind_columns c on i.index_name = c.index_name
        where i.index_type = 'BITMAP'
    );

    my @select_params;
    if ($table_name) {
        @select_params = $self->_resolve_owner_and_table_from_table_name($table_name);
        $sql .= " and i.table_owner = ? and i.table_name = ?";
    }

    my $dbh = $self->get_default_handle;
    my $rows = $dbh->selectall_arrayref($sql, undef, @select_params);
    return undef unless $rows;
    
    my @ret = map { { table_name => $_->[0], column_name => $_->[1], index_name => $_->[2] } } @$rows;

    return \@ret;
}


sub get_unique_index_details_from_data_dictionary {
    my ($self, $owner_name, $table_name) = @_;
    my $sql = qq(
        select cc.constraint_name, cc.column_name
        from all_cons_columns cc
        join all_constraints c
        on c.constraint_name = cc.constraint_name
        and c.owner = cc.owner
        and c.constraint_type = 'U'
        where cc.table_name = ?
        and cc.owner = ?

        union

        select ai.index_name, aic.column_name
        from all_indexes ai
        join all_ind_columns aic
        on aic.index_name = ai.index_name
        and aic.index_owner = ai.owner
        where ai.uniqueness = 'UNIQUE'
        and aic.table_name = ?
        and aic.index_owner = ?
    );

    my $dbh = $self->get_default_handle();
    return undef unless $dbh;

    my $sth = $dbh->prepare($sql);
    return undef unless $sth;

    $sth->execute($table_name, $owner_name, $table_name, $owner_name);

    my $ret;
    while (my $data = $sth->fetchrow_hashref()) {
        $ret->{$data->{'CONSTRAINT_NAME'}} ||= [];
        push @{ $ret->{ $data->{CONSTRAINT_NAME} } }, $data->{COLUMN_NAME};
    }

    return $ret;
}

sub set_userenv {

    # there are two places to set these oracle variables-
    # 1. this method in UR::DataSource::Oracle is a class method
    # that can be called to change the values later
    # 2. the method in YourSubclass::DataSource::Oracle is called in
    # init_created_handle which is called while the datasource
    # is still being set up- it operates directly on the db handle 

    my ($self, %p) = @_;

    my $dbh = $p{'dbh'} || $self->get_default_handle();

    # module is application name
    my $module = $p{'module'} || $0;

    # storing username in 'action' oracle variable
    my $action = $p{'action'};
    if (! defined($action)) {
        $action = getpwuid($>); # real UID
    }

    my $sql = q{BEGIN dbms_application_info.set_module(?, ?); END;};

    my $sth = $dbh->prepare($sql);
    if (!$sth) {
        warn "Couldnt prepare query to set module/action in Oracle";
        return undef;
    }

    $sth->execute($module, $action) || warn "Couldnt set module/action in Oracle";
}

sub get_userenv {

    # there are two ways to set these values but this is
    # the only way to retrieve the values after they are set

    my ($self, $dbh) = @_;

    if (!$dbh) {
        $dbh = $self->get_default_handle();
    }

    if (!$dbh) {
        warn "No dbh";
        return undef;
    }

    my $sql = q{
        SELECT sys_context('USERENV','MODULE') as module,
               sys_context('USERENV','ACTION') as action
          FROM dual
    };

    my $sth = $dbh->prepare($sql);
    return undef unless $sth;

    $sth->execute() || die "execute failed: $!";
    my $r = $sth->fetchrow_hashref();

    return $r;
}


my %ur_data_type_for_vendor_data_type = (
    'VARCHAR2'  => ['Text', undef],
    'BLOB'  => ['XmlBlob', undef],
);
sub ur_data_type_for_data_source_data_type {
    my($class,$type) = @_;

    $type = $class->normalize_vendor_type($type);
    my $urtype = $ur_data_type_for_vendor_data_type{$type};
    unless (defined $urtype) {
        $urtype = $class->SUPER::ur_data_type_for_data_source_data_type($type);
    }
    return $urtype;
}

sub _alter_sth_for_selecting_blob_columns {
    my($self, $sth, $column_objects) = @_;

    for (my $n = 0; $n < @$column_objects; $n++) {
        next unless defined ($column_objects->[$n]);  # No metaDB info for this one
        if ($column_objects->[$n]->data_type eq 'BLOB') {
            $sth->bind_param($n+1, undef, { ora_type => 23 });
        }
    }
}

sub get_connection_debug_info {
    my $self = shift;
    my @debug_info = $self->SUPER::get_connection_debug_info(@_);
    push @debug_info, (
        "DBD::Oracle Version: ", $DBD::Oracle::VERSION, "\n",
        "TNS_ADMIN: ", $ENV{TNS_ADMIN}, "\n",
        "ORACLE_HOME: ", $ENV{ORACLE_HOME}, "\n",
    );
    return @debug_info;
}


# This is a near cut-and-paste from DBD::Oracle, with the exception that
# the query hint is removed, since it performs poorly on Oracle 11
sub get_table_details_from_data_dictionary {
    my $self = shift;

    my $version = $self->_get_oracle_major_server_version();
    if ($version < '11') {
        return $self->SUPER::get_table_details_from_data_dictionary(@_);
    }

    my($CatVal, $SchVal, $TblVal, $TypVal) = @_;
    my $dbh = $self->get_default_handle();
    # XXX add knowledge of temp tables, etc
    # SQL/CLI (ISO/IEC JTC 1/SC 32 N 0595), 6.63 Tables
    if (ref $CatVal eq 'HASH') {
        ($CatVal, $SchVal, $TblVal, $TypVal) =
        @$CatVal{'TABLE_CAT','TABLE_SCHEM','TABLE_NAME','TABLE_TYPE'};
    }
    my @Where = ();
    my $SQL;
    if ( defined $CatVal && $CatVal eq '%' && (!defined $SchVal || $SchVal eq '') && (!defined $TblVal || $TblVal eq '')) { # Rule 19a
        $SQL = <<'SQL';
SELECT NULL TABLE_CAT
     , NULL TABLE_SCHEM
     , NULL TABLE_NAME
     , NULL TABLE_TYPE
     , NULL REMARKS
  FROM DUAL
SQL
    }
    elsif ( defined $SchVal && $SchVal eq '%' && (!defined $CatVal || $CatVal eq '') && (!defined $TblVal || $TblVal eq '')) { # Rule 19b
        $SQL = <<'SQL';
SELECT NULL TABLE_CAT
     , s    TABLE_SCHEM
     , NULL TABLE_NAME
     , NULL TABLE_TYPE
     , NULL REMARKS
  FROM
(
  SELECT USERNAME s FROM ALL_USERS
  UNION
  SELECT 'PUBLIC' s FROM DUAL
)
 ORDER BY TABLE_SCHEM
SQL
    }
    elsif ( defined $TypVal && $TypVal eq '%' && (!defined $CatVal || $CatVal eq '') && (!defined $SchVal || $SchVal eq '') && (!defined $TblVal || $TblVal eq '')) { # Rule 19c
        $SQL = <<'SQL';
SELECT NULL TABLE_CAT
     , NULL TABLE_SCHEM
     , NULL TABLE_NAME
     , t.tt TABLE_TYPE
     , NULL REMARKS
  FROM
(
  SELECT 'TABLE'    tt FROM DUAL
    UNION
  SELECT 'VIEW'     tt FROM DUAL
    UNION
  SELECT 'SYNONYM'  tt FROM DUAL
    UNION
  SELECT 'SEQUENCE' tt FROM DUAL
) t
 ORDER BY TABLE_TYPE
SQL
    }
    else {
        $SQL = <<'SQL';
SELECT *
  FROM
(
  SELECT
       NULL         TABLE_CAT
     , t.OWNER      TABLE_SCHEM
     , t.TABLE_NAME TABLE_NAME
     , decode(t.OWNER
      , 'SYS'    , 'SYSTEM '
      , 'SYSTEM' , 'SYSTEM '
          , '' ) || t.TABLE_TYPE TABLE_TYPE
     , c.COMMENTS   REMARKS
  FROM ALL_TAB_COMMENTS c
     , ALL_CATALOG      t
 WHERE c.OWNER      (+) = t.OWNER
   AND c.TABLE_NAME (+) = t.TABLE_NAME
   AND c.TABLE_TYPE (+) = t.TABLE_TYPE
)
SQL
        if ( defined $SchVal ) {
            push @Where, "TABLE_SCHEM LIKE '$SchVal' ESCAPE '\\'";
        }
        if ( defined $TblVal ) {
            push @Where, "TABLE_NAME  LIKE '$TblVal' ESCAPE '\\'";
        }
        if ( defined $TypVal ) {
            my $table_type_list;
            $TypVal =~ s/^\s+//;
            $TypVal =~ s/\s+$//;
            my @ttype_list = split (/\s*,\s*/, $TypVal);
            foreach my $table_type (@ttype_list) {
                if ($table_type !~ /^'.*'$/) {
                    $table_type = "'" . $table_type . "'";
                }
                $table_type_list = join(", ", @ttype_list);
            }
            push @Where, "TABLE_TYPE IN ($table_type_list)";
        }
        $SQL .= ' WHERE ' . join("\n   AND ", @Where ) . "\n" if @Where;
        $SQL .= " ORDER BY TABLE_TYPE, TABLE_SCHEM, TABLE_NAME\n";
    }
    my $sth = $dbh->prepare($SQL) or return undef;
    $sth->execute or return undef;
    $sth;
}

sub get_column_details_from_data_dictionary {
    my $self = shift;

    my $version = $self->_get_oracle_major_server_version();
    if ($version < '11') {
        return $self->SUPER::get_column_details_from_data_dictionary(@_);
    }

    my $dbh = $self->get_default_handle();
    my $attr = ( ref $_[0] eq 'HASH') ? $_[0] : {
        'TABLE_SCHEM' => $_[1],'TABLE_NAME' => $_[2],'COLUMN_NAME' => $_[3] };
    my($typecase,$typecaseend) = ('','');
    my $v = DBD::Oracle::db::ora_server_version($dbh);
    if (!defined($v) or $v->[0] >= 8) {
        $typecase = <<'SQL';
CASE WHEN tc.DATA_TYPE LIKE 'TIMESTAMP% WITH% TIME ZONE' THEN 95
     WHEN tc.DATA_TYPE LIKE 'TIMESTAMP%'                 THEN 93
     WHEN tc.DATA_TYPE LIKE 'INTERVAL DAY% TO SECOND%'   THEN 110
     WHEN tc.DATA_TYPE LIKE 'INTERVAL YEAR% TO MONTH'    THEN 107
ELSE
SQL
        $typecaseend = 'END';
    }
    my $SQL = <<"SQL";
SELECT *
  FROM
(
  SELECT
         to_char( NULL )     TABLE_CAT
       , tc.OWNER            TABLE_SCHEM
       , tc.TABLE_NAME       TABLE_NAME
       , tc.COLUMN_NAME      COLUMN_NAME
       , $typecase decode( tc.DATA_TYPE
         , 'MLSLABEL' , -9106
         , 'ROWID'    , -9104
         , 'UROWID'   , -9104
         , 'BFILE'    ,    -4 -- 31?
         , 'LONG RAW' ,    -4
         , 'RAW'      ,    -3
         , 'LONG'     ,    -1
         , 'UNDEFINED',     0
         , 'CHAR'     ,     1
         , 'NCHAR'    ,     1
         , 'NUMBER'   ,     decode( tc.DATA_SCALE, NULL, 8, 3 )
         , 'FLOAT'    ,     8
         , 'VARCHAR2' ,    12
         , 'NVARCHAR2',    12
         , 'BLOB'     ,    30
         , 'CLOB'     ,    40
         , 'NCLOB'    ,    40
         , 'DATE'     ,    93
         , NULL
         ) $typecaseend      DATA_TYPE          -- ...
       , tc.DATA_TYPE        TYPE_NAME          -- std.?
       , decode( tc.DATA_TYPE
         , 'LONG RAW' , 2147483647
         , 'LONG'     , 2147483647
         , 'CLOB'     , 2147483647
         , 'NCLOB'    , 2147483647
         , 'BLOB'     , 2147483647
         , 'BFILE'    , 2147483647
         , 'NUMBER'   , decode( tc.DATA_SCALE
                        , NULL, 126
                        , nvl( tc.DATA_PRECISION, 38 )
                        )
         , 'FLOAT'    , tc.DATA_PRECISION
         , 'DATE'     , 19
         , tc.DATA_LENGTH
         )                   COLUMN_SIZE
       , decode( tc.DATA_TYPE
         , 'LONG RAW' , 2147483647
         , 'LONG'     , 2147483647
         , 'CLOB'     , 2147483647
         , 'NCLOB'    , 2147483647
         , 'BLOB'     , 2147483647
         , 'BFILE'    , 2147483647
         , 'NUMBER'   , nvl( tc.DATA_PRECISION, 38 ) + 2
         , 'FLOAT'    ,  8 -- ?
         , 'DATE'     , 16
         , tc.DATA_LENGTH
         )                   BUFFER_LENGTH
       , decode( tc.DATA_TYPE
         , 'DATE'     ,  0
         , tc.DATA_SCALE
         )                   DECIMAL_DIGITS     -- ...
       , decode( tc.DATA_TYPE
         , 'FLOAT'    ,  2
         , 'NUMBER'   ,  decode( tc.DATA_SCALE, NULL, 2, 10 )
         , NULL
         )                   NUM_PREC_RADIX
       , decode( tc.NULLABLE
         , 'Y'        ,  1
         , 'N'        ,  0
         , NULL
         )                   NULLABLE
       , cc.COMMENTS         REMARKS
       , tc.DATA_DEFAULT     COLUMN_DEF         -- Column is LONG!
       , decode( tc.DATA_TYPE
         , 'MLSLABEL' , -9106
         , 'ROWID'    , -9104
         , 'UROWID'   , -9104
         , 'BFILE'    ,    -4 -- 31?
         , 'LONG RAW' ,    -4
         , 'RAW'      ,    -3
         , 'LONG'     ,    -1
         , 'UNDEFINED',     0
         , 'CHAR'     ,     1
         , 'NCHAR'    ,     1
         , 'NUMBER'   ,     decode( tc.DATA_SCALE, NULL, 8, 3 )
         , 'FLOAT'    ,     8
         , 'VARCHAR2' ,    12
         , 'NVARCHAR2',    12
         , 'BLOB'     ,    30
         , 'CLOB'     ,    40
         , 'NCLOB'    ,    40
         , 'DATE'     ,     9 -- not 93!
         , NULL
         )                   SQL_DATA_TYPE      -- ...
       , decode( tc.DATA_TYPE
         , 'DATE'     ,     3
         , NULL
         )                   SQL_DATETIME_SUB   -- ...
       , to_number( NULL )   CHAR_OCTET_LENGTH  -- TODO
       , tc.COLUMN_ID        ORDINAL_POSITION
       , decode( tc.NULLABLE
         , 'Y'        , 'YES'
         , 'N'        , 'NO'
         , NULL
         )                   IS_NULLABLE
    FROM ALL_TAB_COLUMNS  tc
       , ALL_COL_COMMENTS cc
   WHERE tc.OWNER         = cc.OWNER
     AND tc.TABLE_NAME    = cc.TABLE_NAME
     AND tc.COLUMN_NAME   = cc.COLUMN_NAME
)
 WHERE 1              = 1
SQL
    my @BindVals = ();
    while ( my ( $k, $v ) = each %$attr ) {
        if ( $v ) {
        $SQL .= "   AND $k LIKE ? ESCAPE '\\'\n";
        push @BindVals, $v;
        }
    }
    $SQL .= " ORDER BY TABLE_SCHEM, TABLE_NAME, ORDINAL_POSITION\n";
    my $sth = $dbh->prepare( $SQL ) or return undef;
    $sth->execute( @BindVals ) or return undef;
    $sth;
}

sub get_primary_key_details_from_data_dictionary {
    my $self = shift;

    my $version = $self->_get_oracle_major_server_version();
    if ($version < '11') {
        return $self->SUPER::get_primary_key_details_from_data_dictionary(@_);
    }

    my $dbh = $self->get_default_handle();
    my($catalog, $schema, $table) = @_;
    if (ref $catalog eq 'HASH') {
        ($schema, $table) = @$catalog{'TABLE_SCHEM','TABLE_NAME'};
        $catalog = undef;
    }
    my $SQL = <<'SQL';
SELECT *
  FROM
(
  SELECT
         NULL              TABLE_CAT
       , c.OWNER           TABLE_SCHEM
       , c.TABLE_NAME      TABLE_NAME
       , c.COLUMN_NAME     COLUMN_NAME
       , c.POSITION        KEY_SEQ
       , c.CONSTRAINT_NAME PK_NAME
    FROM ALL_CONSTRAINTS   p
       , ALL_CONS_COLUMNS  c
   WHERE p.OWNER           = c.OWNER
     AND p.TABLE_NAME      = c.TABLE_NAME
     AND p.CONSTRAINT_NAME = c.CONSTRAINT_NAME
     AND p.CONSTRAINT_TYPE = 'P'
)
 WHERE TABLE_SCHEM = ?
   AND TABLE_NAME  = ?
 ORDER BY TABLE_SCHEM, TABLE_NAME, KEY_SEQ
SQL
#warn "@_\n$Sql ($schema, $table)";
    my $sth = $dbh->prepare($SQL) or return undef;
    $sth->execute($schema, $table) or return undef;
    $sth;
}



sub get_foreign_key_details_from_data_dictionary {
    my $self = shift;

    my $version = $self->_get_oracle_major_server_version();
    if ($version < '11') {
        return $self->SUPER::get_foreign_key_details_from_data_dictionary(@_);
    }

    my $dbh = $self->get_default_handle();
    my $attr = ( ref $_[0] eq 'HASH') ? $_[0] : {
        'UK_TABLE_SCHEM' => $_[1],'UK_TABLE_NAME ' => $_[2]
        ,'FK_TABLE_SCHEM' => $_[4],'FK_TABLE_NAME ' => $_[5] };
    my $SQL = <<'SQL';  # XXX: DEFERABILITY
SELECT *
  FROM
(
  SELECT
         to_char( NULL )    UK_TABLE_CAT
       , uk.OWNER           UK_TABLE_SCHEM
       , uk.TABLE_NAME      UK_TABLE_NAME
       , uc.COLUMN_NAME     UK_COLUMN_NAME
       , to_char( NULL )    FK_TABLE_CAT
       , fk.OWNER           FK_TABLE_SCHEM
       , fk.TABLE_NAME      FK_TABLE_NAME
       , fc.COLUMN_NAME     FK_COLUMN_NAME
       , uc.POSITION        ORDINAL_POSITION
       , 3                  UPDATE_RULE
       , decode( fk.DELETE_RULE, 'CASCADE', 0, 'RESTRICT', 1, 'SET NULL', 2, 'NO ACTION', 3, 'SET DEFAULT', 4 )
                            DELETE_RULE
       , fk.CONSTRAINT_NAME FK_NAME
       , uk.CONSTRAINT_NAME UK_NAME
       , to_char( NULL )    DEFERABILITY
       , decode( uk.CONSTRAINT_TYPE, 'P', 'PRIMARY', 'U', 'UNIQUE')
                            UNIQUE_OR_PRIMARY
    FROM ALL_CONSTRAINTS    uk
       , ALL_CONS_COLUMNS   uc
       , ALL_CONSTRAINTS    fk
       , ALL_CONS_COLUMNS   fc
   WHERE uk.OWNER            = uc.OWNER
     AND uk.CONSTRAINT_NAME  = uc.CONSTRAINT_NAME
     AND fk.OWNER            = fc.OWNER
     AND fk.CONSTRAINT_NAME  = fc.CONSTRAINT_NAME
     AND uk.CONSTRAINT_TYPE IN ('P','U')
     AND fk.CONSTRAINT_TYPE  = 'R'
     AND uk.CONSTRAINT_NAME  = fk.R_CONSTRAINT_NAME
     AND uk.OWNER            = fk.R_OWNER
     AND uc.POSITION         = fc.POSITION
)
 WHERE 1              = 1
SQL
    my @BindVals = ();
    while ( my ( $k, $v ) = each %$attr ) {
        if ( $v ) {
        $SQL .= "   AND $k = ?\n";
        push @BindVals, $v;
        }
    }
    $SQL .= " ORDER BY UK_TABLE_SCHEM, UK_TABLE_NAME, FK_TABLE_SCHEM, FK_TABLE_NAME, ORDINAL_POSITION\n";
    my $sth = $dbh->prepare( $SQL ) or return undef;
    $sth->execute( @BindVals ) or return undef;
    $sth;
}


sub _get_oracle_major_server_version {
    my $self = shift;

    unless (exists $self->{'__ora_major_server_version'}) {
        my $dbh = $self->get_default_handle();
        my @data = $dbh->selectrow_arrayref('select version from v$instance');
        $self->{'__ora_major_server_version'} = (split(/\./, $data[0]->[0]))[0];
    }
    return $self->{'__ora_major_server_version'};
}

sub cast_for_data_conversion {
    my($class, $left_type, $right_type, $operator, $sql_clause) = @_;

    my @retval = ('%s','%s');

    # compatible types
    if ($left_type->isa($right_type)
        or
        $right_type->isa($left_type)
    ) {
        return @retval;
    }

    if (! $left_type->isa('UR::Value::Text')
        and
        ! $right_type->isa('UR::Value::Text')
    ) {
        # We only support cases where one is a string, for now
        # hopefully the DB can sort it out
        return @retval;
    }

    # Oracle can auto-convert strings into numbers and dates in the 'where'
    # clause, but has issues in joins
    if ($sql_clause eq 'where') {
        return @retval;
    }

    # Figure out which one is the non-string
    my($data_type, $i) = $left_type->isa('UR::Value::Text')
                        ? ( $right_type, 1)
                        : ( $left_type, 0);

    if ($data_type->isa('UR::Value::Number')) {
        $retval[$i] = q{to_char(%s)};

    } elsif ($data_type->isa('UR::Value::Timestamp')) {
        # These time formats shoule match what's given in init_created_handle
        $retval[$i] = qq{to_char(%s, '$TIMESTAMP_FORMAT')};

    } elsif ($data_type->isa('UR::Value::DateTime')) {
        $retval[$i] = qq{to_char(%s, '$DATE_FORMAT')};

    } else {
        @retval = $class->SUPER::cast_for_data_conversion($left_type, $right_type);
    }

    return @retval;
}

sub _vendor_data_type_for_ur_data_type {
    return ( TEXT        => 'VARCHAR2',
             STRING      => 'VARCHAR2',
             BOOLEAN      => 'INTEGER',
             __default__ => 'VARCHAR2',
             shift->SUPER::_vendor_data_type_for_ur_data_type(),
            );
};


1;

=pod

=head1 NAME

UR::DataSource::Oracle - Oracle specific subclass of UR::DataSource::RDBMS

=head1 DESCRIPTION

This module provides the Oracle-specific methods necessary for interacting with
Oracle databases

=head1 SEE ALSO

L<UR::DataSource>, L<UR::DataSource::RDBMS>

=cut


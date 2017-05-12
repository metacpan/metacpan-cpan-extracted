=head1 NAME

XAO::DO::FS::Glue::Base_MySQL - MySQL specific overrides - base for MySQL_DBI and MySQL drivers

=head1 SYNOPSIS

Should not be used directly.

=head1 DESCRIPTION

This module implements some functionality required by FS::Glue
in MySQL specific way.

=head1 METHODS

=over

=cut

###############################################################################
package XAO::DO::FS::Glue::Base_MySQL;
use strict;
use Error qw(:try);
use XAO::Utils qw(:debug :args :keys);
use XAO::Objects;

use base XAO::Objects->load(objname => 'FS::Glue::Base');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Base_MySQL.pm,v 2.11 2008/12/10 05:33:26 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

=item new ($%)

Creates new instance of the driver connected to the given database using
DSN, user and password.

Example:

 my $driver=XAO::Objects->new(objname => 'FS::Glue::MySQL',
                              dsn => 'OS:MySQL_DBI:dbname',
                              user => 'username',
                              password => '123123123');

=cut

sub new ($%) {
    my $proto=shift;
    my $args=get_args(\@_);

    my $self=$proto->SUPER::new($args);

    my $dsn=$args->{'dsn'};
    $dsn || $self->throw("new - required parameter missed 'dsn'");
    $dsn=~/^OS:(\w+):(\w+)(;.*)?$/ || $self->throw("new - bad format of 'dsn' ($dsn)");
    my $driver=$1;
    my $dbname=$2;
    my $options=$3 || '';

    # Parsing dbopts, separating what we know about from what is passed
    # directly to the driver.
    #
    my $dbopts='';
    foreach my $pair (split(/[,;]/,$options)) {
        next unless length($pair);
        if($pair =~ /^table_type\s*=\s*(.*?)\s*$/) {
            $self->{'table_type'}=lc($1);
        }
        else {
            $dbopts.=';' . $pair;
        }
    }

    $driver =~ '^MySQL' ||
        throw $self "new - wrong driver type ($driver)";

    $self->connector->sql_connect(
        dsn         => "DBI:mysql:$dbname$dbopts",
        user        => $args->{'user'},
        password    => $args->{'password'},
    );

    # Without this option we risk getting weird results -- for instance
    # a 'koi8r' column might be returned encoded in 'utf8' otherwise
    # depending on the server config.
    #
    # SET NAMES is the same as assigning the value to each of
    # character-set-{client,connection,results} separately.
    #
    my $cn=$self->connector;
    $cn->sql_do("SET NAMES 'binary'");

    # Getting DB version
    #
    my $sth=$cn->sql_execute(q(SHOW VARIABLES LIKE 'version'));
    my $row=$cn->sql_first_row($sth);
    my $version=($row && $row->[0] eq 'version') ? $row->[1] : '4.0-fake';
    my $vnum=($version=~/^(\d+)\.(\d+)(?:\.(\d+))?/) ? sprintf('%u.%03u%03u',$1,$2,$3||0) : 4.0;

    $self->{'mysql_version'}=$vnum;
    $self->{'mysql_version_full'}=$version;

    ### dprint "MySQL version $version ($vnum)";

    # Just to make sure that even if the server has some different
    # encoding set, we enforce transparency.
    #
    if($vnum>=5.006) {
        $cn->sql_do("SET character_set_client='binary'");
        $cn->sql_do("SET character_set_connection='binary'");
        $cn->sql_do("SET character_set_results='binary'");
    }

    # Done preparing
    #
    return $self;
}

###############################################################################

=item add_field_integer ($$$$)

Adds new integer field to the given table. First parameter is table
name, then field name, then index flag, then unique flag, then minimal
value and then maximum value and default value.

B<Note:> Indexes only work with MySQL 3.23 and later.

=cut

sub add_field_integer ($$$$$) {
    my $self=shift;
    my ($table,$name,$index,$unique,$min,$max,$default,$connected)=@_;
    $name.='_';

    if($self->tr_loc_active || $self->tr_ext_active) {
        throw $self "add_field_integer - modifying structure in transaction scope is not supported";
    }

    $min=-0x80000000 unless defined $min;
    $min=int($min);
    if(!defined($max)) {
        $max=($min<0) ? 0x7FFFFFFF : 0xFFFFFFFF;
    }

    my $sql;
    if($min<0) {
        if($min>=-0x80 && $max<=0x7F) {
            $sql='TINYINT';
        }
        elsif($min>=-0x8000 && $max<=0x7FFF) {
            $sql='SMALLINT';
        }
        elsif($min>=-0x800000 && $max<=0x7FFFFF) {
            $sql='MEDIUMINT';
        }
        else {
            $sql='INT';
        }
    }
    else {
        if($max<=0xFF) {
            $sql='TINYINT UNSIGNED';
        }
        elsif($max<=0xFFFF) {
            $sql='SMALLINT UNSIGNED';
        }
        elsif($max<=0xFFFFFF) {
            $sql='MEDIUMINT UNSIGNED';
        }
        else {
            $sql='INT UNSIGNED';
        }
    }

    $sql.=" NOT NULL DEFAULT $default";

    $sql="ALTER TABLE $table ADD $name $sql";

    my $cn=$self->connector;
    $cn->sql_do($sql);

    if(($index || $unique) && (!$unique || !$connected)) {
        my $usql=$unique ? " UNIQUE" : "";
        $sql="ALTER TABLE $table ADD$usql INDEX fsi__$name ($name)";
        #dprint ">>>$sql<<<";
        $cn->sql_do($sql);
    }

    if($unique && $connected) {
        $sql="ALTER TABLE $table ADD UNIQUE INDEX fsu__$name (parent_unique_id_,$name)";
        #dprint ">>>$sql<<<";
        $cn->sql_do($sql);
    }
}

###############################################################################

=item add_field_real ($$;$$)

Adds new real field to the given table. First parameter is table name,
then field name, then index flag, then unique flag, then optional
minimal value and then optional maximum value and default value.

B<Note:> Indexes only work with MySQL 3.23 and later.

=cut

sub add_field_real ($$$;$$) {
    my $self=shift;
    my ($table,$name,$index,$unique,$min,$max,$scale,$default,$connected)=@_;
    $name.='_';

    if($self->tr_loc_active || $self->tr_ext_active) {
        throw $self "add_field_real - modifying structure in transaction scope is not supported";
    }

    my $sql=
        "ALTER TABLE $table ADD $name ".
        $self->real_field_definition($min,$max,$scale);

    ### dprint ">>>$sql<<<";

    my $cn=$self->connector;

    $cn->sql_do($sql,[$default || 0]);

    if(($index || $unique) && (!$unique || !$connected)) {
        my $usql=$unique ? " UNIQUE" : "";
        $sql="ALTER TABLE $table ADD$usql INDEX fsi__$name ($name)";
        ### dprint ">>>$sql<<<";
        $cn->sql_do($sql);
    }

    if($unique && $connected) {
        $sql="ALTER TABLE $table ADD UNIQUE INDEX fsu__$name (parent_unique_id_,$name)";
        ### dprint ">>>$sql<<<";
        $cn->sql_do($sql);
    }
}

###############################################################################

=item add_field_text ($$$$$)

Adds new text field to the given table. First is table name, then field
name, then index flag, then unique flag, maximum length, default value
and 'connected' flag. Depending on maximum length it will create CHAR,
TEXT, MEDIUMTEXT or LONGTEXT.

'Connected' flag must be set if that table holds elements deeper into
the tree then the top level.

B<Note:> Modifiers 'index' and 'unique' only work with MySQL 3.23 and
later.

=cut

sub add_field_text ($$$$$$) {
    my $self=shift;
    my ($table,$name,$index,$unique,$maxlength,$default,$charset,$connected)=@_;
    $name.='_';

    if($self->tr_loc_active || $self->tr_ext_active) {
        throw $self "add_field_text - modifying structure in transaction scope is not supported";
    }

    $charset ||
        throw $self "add_field_text - 'charset' is required for text fields";

    my $def=$self->text_field_definition($charset,$maxlength);

    my $cn=$self->connector;
    $cn->sql_do("ALTER TABLE $table ADD $name $def",$default);

    !$unique || $maxlength<=255 ||
        throw $self "add_field_text - property is too long to make it unique ($maxlength)";
    !$index || $maxlength<=255 ||
        throw $self "add_field_text - property is too long for an index ($maxlength)";

    if(($index || $unique) && (!$unique || !$connected)) {
        my $usql=$unique ? " UNIQUE" : "";
        my $sql="ALTER TABLE $table ADD$usql INDEX fsi__$name ($name)";
        ### dprint ">>>$sql<<<";
        $cn->sql_do($sql);
    }

    if($unique && $connected) {
        my $sql="ALTER TABLE $table ADD UNIQUE INDEX fsu__$name (parent_unique_id_,$name)";
        ### dprint ">>>$sql<<<";
        $cn->sql_do($sql);
    }
}

###############################################################################

=item add_table ($$$)

Creates new empty table with unique_id, key and optionally connector
fields.

=cut

sub add_table ($$$$$) {
    my $self=shift;
    my ($table,$key,$key_length,$key_charset,$connector)=@_;
    $key.='_';
    $connector.='_' if $connector;

    if($self->tr_loc_active || $self->tr_ext_active) {
        throw $self "add_table - modifying structure in transaction scope is not supported";
    }

    my $def=$self->text_field_definition($key_charset,$key_length);

    my $sql="CREATE TABLE $table (" .
            " unique_id INT UNSIGNED AUTO_INCREMENT NOT NULL PRIMARY KEY," .
            " $key $def," .
            (defined($connector) ? " $connector INT UNSIGNED NOT NULL," .
                                   " INDEX $key($key)," .
                                   " INDEX $connector($connector)"
                                 : " UNIQUE INDEX $key($key)") .
            ")";

    $sql.=" ENGINE=".$self->{'table_type'}
        if $self->{'table_type'} && $self->{'table_type'} ne 'mixed';

    $self->connector->sql_do($sql,'');
}

###############################################################################

=item charset_change_prepare ($)

Prepares an internal structure for a later one-shot modification of
charsets in a table.

=cut

sub charset_change_prepare ($$) {
    my ($self,$table)=@_;

    $table || throw $self "charset_change_prepare - no 'table' given";

    return {
        sql     => '',
        table   => $table,
        defaults=> [ ],
    };
}

###############################################################################

=item charset_change_field

Adds a field to the list of things to alter on charset_change_execute()

=cut

sub charset_change_field ($$$$$$) {
    my ($self,$csh,$name,$charset,$maxlength,$default)=@_;

    my $def=$self->text_field_definition($charset,$maxlength);

    $csh->{'sql'}.=', ' if $csh->{'sql'};
    $csh->{'sql'}.="CHANGE ".
                   $self->mangle_field_name($name)." ".
                   $self->mangle_field_name($name)." ".$def;

    push(@{$csh->{'defaults'}},$default);
}

###############################################################################

=item charset_change_execute

Executes actual SQL collected from charset_change_field()

=cut

sub charset_change_execute ($$) {
    my ($self,$csh)=@_;

    my $sql="ALTER TABLE ".$csh->{'table'}." ".$csh->{'sql'};
    $self->connector->sql_do($sql,$csh->{'defaults'});
}

###############################################################################

=item scale_change_prepare ($)

Prepares an internal structure for a later one-shot modification of
scale values in a table.

=cut

sub scale_change_prepare ($$) {
    my ($self,$table)=@_;

    $table || throw $self "- no 'table' given";

    return {
        sql     => '',
        table   => $table,
        defaults=> [ ],
    };
}

###############################################################################

=item scale_change_field

Adds a field to the list of things to alter on scale_change_execute()

=cut

sub scale_change_field ($$$$$$) {
    my ($self,$csh,$name,$scale,$minvalue,$maxvalue,$default)=@_;

    my $def=$self->real_field_definition($minvalue,$maxvalue,$scale);

    $csh->{'sql'}.=', ' if $csh->{'sql'};
    $csh->{'sql'}.="CHANGE ".
                   $self->mangle_field_name($name)." ".
                   $self->mangle_field_name($name)." ".$def;

    push(@{$csh->{'defaults'}},$default);
}

###############################################################################

=item scale_change_execute

Executes actual SQL collected from scale_change_field()

=cut

sub scale_change_execute ($$) {
    my ($self,$csh)=@_;

    my $sql="ALTER TABLE ".$csh->{'table'}." ".$csh->{'sql'};

    ### dprint "...SQL: $sql";

    $self->connector->sql_do($sql,$csh->{'defaults'});
}

###############################################################################

=item consistency_checked

Returns true if load_structure() was asked to and performed meta-data
consistency checks (SHOW TABLE STATUS, compare requested table_type to
on-disk type, table & db version compatibility, etc).

=cut

sub consistency_checked ($) {
    my $self=shift;
    return $self->{'consistency_checked'};
}

###############################################################################

=item consistency_check_set

If called before load_structure() with a true argument then the
load_structure will also check meta-data consistency.

=cut

sub consistency_check_set ($$) {
    my ($self,$cc)=@_;
    if($cc && $self->{'structure_loaded'}) {
        eprint "consistency_check_set($cc) must be called before load_structure(), ignoring it";
        return;
    }
    $self->{'consistency_check_requested'}=($cc ? 1 : undef);
}

###############################################################################

=item delete_row ($$)

Deletes a row from the given name and unique_id.

=cut

sub delete_row ($$$) {
    my $self=shift;
    my ($table,$uid)=@_;

    $self->tr_loc_begin;
    $self->connector->sql_do("DELETE FROM $table WHERE unique_id=?",$uid);
    $self->tr_loc_commit;
}

###############################################################################

=item disconnect ()

Permanently disconnects driver from database. Normally perl's garbage collector
will do that for you.

=cut

sub disconnect ($) {
    my $self=shift;
    if($self->{'table_type'} eq 'innodb') {
        $self->tr_ext_rollback if $self->tr_ext_active;
        $self->tr_loc_rollback if $self->tr_loc_active;
    }
    else {
        $self->unlock_tables;
    }
    $self->connector->sql_disconnect;
}

###############################################################################

=item drop_field ($$$$$)

Drops the given field from the given table in the database. Whatever
content was in that field is lost irrevocably.

If index, unique and connected flags are given then it first will drop
the appropriate index.

=cut

sub drop_field ($$$$$$) {
    my $self=shift;
    my ($table,$name,$index,$unique,$connected)=@_;

    if($self->tr_loc_active || $self->tr_ext_active) {
        throw $self "drop_field - modifying structure in transaction scope is not supported";
    }

    $name.='_';

    my $cn=$self->connector;
    if($index && (!$unique || !$connected)) {
        my $sql="ALTER TABLE $table DROP INDEX fsi__$name";
        # dprint ">>>$sql<<<";
        $cn->sql_do($sql);
    }

    if($unique && $connected) {
        my $sql="ALTER TABLE $table DROP INDEX fsu__$name";
        # dprint ">>>$sql<<<";
        $cn->sql_do($sql);
    }

    $cn->sql_do("ALTER TABLE $table DROP $name");
}

###############################################################################

=item drop_table ($)

Drops the given table with all its data. Whatever content was in that
table before is lost irrevocably.

=cut

sub drop_table ($$) {
    my $self=shift;
    my $table=shift;

    if($self->tr_loc_active || $self->tr_ext_active) {
        throw $self "drop_table - modifying structure in transaction scope is not supported";
    }

    $self->connector->sql_do("DROP TABLE $table");
}

###############################################################################

=item increment_key_seq ($)

Increments the value of key_seq in Global_Fields table identified by the
given row unique ID. Returns previous value.

B<Note:> Always executed as a part of some outer level transaction. Does
not create any locks or starts transactions.

=cut

sub increment_key_seq ($$) {
    my $self=shift;
    my $uid=shift;

    my $cn=$self->connector;

    $cn->sql_do('UPDATE Global_Fields SET key_seq_=key_seq_+1 WHERE unique_id=?',$uid);

    my $sth=$cn->sql_execute('SELECT key_seq_ FROM Global_Fields WHERE unique_id=?',$uid);
    my $seq=$cn->sql_first_row($sth)->[0];
    if($seq==1) {
        $cn->sql_do('UPDATE Global_Fields SET key_seq_=key_seq_+1 WHERE unique_id=?',$uid);
        $sth=$cn->sql_execute('SELECT key_seq_ FROM Global_Fields WHERE unique_id=?',$uid);
        $seq=$cn->sql_first_row($sth)->[0];
    }

    return $seq-1;
}

###############################################################################

=item initialize_database ($)

Removes all data from all tables and creates minimal tables that support
objects database.

=cut

sub initialize_database ($) {
    my $self=shift;

    if($self->tr_loc_active || $self->tr_ext_active) {
        throw $self "initialize_database - modifying structure in transaction scope is not supported";
    }

    my $cn=$self->connector;
    my $sth=$cn->sql_execute('SHOW TABLE STATUS');
    my $table_type=$self->{'table_type'};
    while(my $row=$self->connector->sql_fetch_row($sth)) {
        my ($name,$type)=@$row;
        $table_type||=lc($type);
        $cn->sql_do("DROP TABLE $name");
    }
    $cn->sql_finish($sth);

    my @initseq=(
        <<'END_OF_SQL',
CREATE TABLE Global_Fields (
  unique_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  table_name_ CHAR(30) CHARACTER SET utf8 NOT NULL DEFAULT '',
  field_name_ CHAR(30) CHARACTER SET utf8 NOT NULL DEFAULT '',
  type_ CHAR(20) CHARACTER SET latin1 NOT NULL DEFAULT '',
  refers_ CHAR(30) CHARACTER SET latin1 DEFAULT NULL,
  key_format_ CHAR(100) CHARACTER SET utf8 DEFAULT NULL,
  key_seq_ INT UNSIGNED DEFAULT NULL,
  index_ TINYINT DEFAULT NULL,
  default_ VARBINARY(30) DEFAULT NULL,
  charset_ CHAR(30) CHARACTER SET latin1 DEFAULT NULL,
  maxlength_ INT UNSIGNED DEFAULT NULL,
  maxvalue_ DOUBLE DEFAULT NULL,
  minvalue_ DOUBLE DEFAULT NULL,
  PRIMARY KEY  (table_name_,field_name_),
  UNIQUE KEY unique_id (unique_id)
)
END_OF_SQL
        <<'END_OF_SQL',
INSERT INTO Global_Fields VALUES (1,'Global_Data','project',
                                  'text','',NULL,NULL,0,'','utf8',40,NULL,NULL)
END_OF_SQL
        <<'END_OF_SQL',
CREATE TABLE Global_Data (
  unique_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  project_ char(40) CHARACTER SET utf8 NOT NULL DEFAULT '',
  PRIMARY KEY (unique_id)
)
END_OF_SQL
        <<'END_OF_SQL',
INSERT INTO Global_Data VALUES (1,'XAO::FS New Database')
END_OF_SQL
        <<'END_OF_SQL',
CREATE TABLE Global_Classes (
  unique_id int(10) unsigned NOT NULL AUTO_INCREMENT,
  class_name_ char(100) NOT NULL DEFAULT '',
  table_name_ char(30) NOT NULL DEFAULT '',
  PRIMARY KEY  (unique_id),
  UNIQUE KEY  (class_name_)
)
END_OF_SQL
        <<'END_OF_SQL',
INSERT INTO Global_Classes VALUES (1,'FS::Global','Global_Data')
END_OF_SQL
    );

    foreach my $sql (@initseq) {
        $sql.=" ENGINE=$table_type" if $table_type && $sql =~ /^CREATE/;
        $cn->sql_do($sql);
    }
}

###############################################################################

=item list_keys ($$$$)

Returns a reference to an array containing all possible values of a
given field (list key) in the given table. If connector is given - then
it is used in select too.

=cut

sub list_keys ($$$$$) {
    my $self=shift;
    my ($table,$key,$conn_name,$conn_value)=@_;
    $key.='_' unless $key eq 'unique_id';
    $conn_name.='_' if $conn_name;

    my $cn=$self->connector;

    my $sth;
    if($conn_name) {
        $sth=$cn->sql_execute("SELECT $key FROM $table WHERE $conn_name=?",
                                $conn_value);
    }
    else {
        $sth=$cn->sql_execute("SELECT $key FROM $table");
    }

    return $cn->sql_first_column($sth);
}

###############################################################################

=item load_structure ()

Loads Global_Fields and Global_Classes tables into internal hash for
use in Glue.

Returns the hash reference.

B<TODO:> This should be changed so that data types would not be
hard-coded here. Probably a reference to a subroutine that will parse
and store them would do the job?

=cut

sub load_structure ($) {
    my $self=shift;

    if($self->tr_loc_active || $self->tr_ext_active) {
        throw $self "load_structure - modifying structure in transaction scope is not supported";
    }

    my $cn=$self->connector;
    my $sth;

    # Checking table types, if requested
    #
    my %table_types;
    if($self->{'consistency_check_requested'}) {
        ### dprint "Meta-data consistency check requested, loading 'table status', etc";

        my %type_counts;
        my $table_count=0;

        $sth=$cn->sql_execute("SHOW TABLE STATUS");
        while(my $row=$cn->sql_fetch_row($sth)) {
            my ($name,$type,$row_format,$rows)=@$row;
            $type=lc($type);
            $type_counts{$type}++;
            $table_types{$name}=$type;
            $table_count++;
            # dprint "Table '$name', type=$type, row_format=$row_format, rows=$rows";
        }

        if($self->{'table_type'}) {
            my $table_type=$self->{'table_type'};
            if($table_type eq 'innodb' || $table_type eq 'myisam') {
                my $warning_shown;
                foreach my $table_name (keys %table_types) {
                    next if $table_types{$table_name} eq $table_type;

                    my $debug_status=XAO::Utils::get_debug();
                    XAO::Utils::set_debug(1);

                    unless($warning_shown) {
                        dprint "Some tables in your database differ from the requested table type ($table_type)";
                        dprint "In 5 seconds they will be converted to the new table type, interrupt to abort..";
                        sleep 5;
                        dprint "Converting...";
                        $warning_shown=1;
                    }

                    dprint "...table '$table_name' type from '$table_types{$table_name}' to '$table_type'";
                    $cn->sql_do("ALTER TABLE $table_name ENGINE=$table_type");

                    XAO::Utils::set_debug($debug_status);
                }
            }
            else {
                throw $self "Unsupported table_type '$table_type' in DSN options";
            }
        }
        elsif($type_counts{'innodb'} && $type_counts{'innodb'}==$table_count) {
            $self->{'table_type'}='innodb';
        }
        elsif($type_counts{'myisam'} && $type_counts{'myisam'}==$table_count) {
            $self->{'table_type'}='myisam';
        }
        else {
            $self->{'table_type'}='mixed';
            eprint "You have mixed table types in the database (" .
                   join(',',map { $_ . '=' . $table_types{$_} } sort keys %table_types) .
                   ")";
        }

        # Checking if Global_Fields table has key_format_ and key_seq_
        # fields. Adding them if it does not.
        #
        $sth=$cn->sql_execute("DESC Global_Fields");
        my $flist=$cn->sql_first_column($sth);
        if(! grep { $_ eq 'key_format_' } @$flist) {
            dprint "Old database detected, adding Global_Fields.key_format_";
            $cn->sql_do('ALTER TABLE Global_Fields ADD key_format_ CHAR(100) CHARACTER SET latin1 DEFAULT NULL');
        }
        if(! grep { $_ eq 'key_seq_' } @$flist) {
            dprint "Old database detected, adding Global_Fields.key_seq_";
            $cn->sql_do('ALTER TABLE Global_Fields ADD key_seq_ INT UNSIGNED DEFAULT NULL');
        }

        ##
        # Checking for charset field, adding it if needed.
        #
        if(! grep { $_ eq 'charset_' } @$flist) {
            dprint "Old database detected, adding Global_Fields.charset_";
            $cn->sql_do(q{ALTER TABLE Global_Fields ADD charset_ CHAR(30) CHARACTER SET latin1 DEFAULT NULL});
        }
    }

    # Since we don't do 'show table status' by default any more it is
    # possible that we won't know the table type. Warning about it and
    # assuming transactional without checking.
    #
    if(!$self->{'table_type'}) {
        eprint "It is recommended to always have '...;table_type=TYPE' as part of DSN, assuming 'innodb'";
        $self->{'table_type'}='innodb';
    }

    # Loading fields descriptions from the database.
    #
    my %fields;
    my %tkeys;
    my %ckeys;
    my %tbdesc;
    $sth=$cn->sql_execute(
        "SELECT unique_id,table_name_,field_name_," .
               "type_,refers_,key_format_," .
               "index_,default_,charset_," .
               "maxlength_,minvalue_,maxvalue_" .
         " FROM Global_Fields");

    while(my $row=$cn->sql_fetch_row($sth)) {
        my ($uid,$table,$field,$type,$refers,$key_format,
            $index,$default,$charset,$maxlength,$minvalue,$maxvalue)=@$row;

        ##
        # Getting table description from the database. Comparing default
        # values later. If they contain spaces the database is probably
        # a badly converted 4.1 to 5.0, needs some rebuilding.
        #
        if(!$tbdesc{$table}) {
            my $tbsth=$cn->sql_execute("DESC $table");
            while(my $tbrow=$cn->sql_fetch_row($tbsth)) {
                my ($tb_field,$tb_type,$tb_null,$tb_key,$tb_default)=@$tbrow;
                $tbdesc{$table}->{$tb_field}={
                    type        => $tb_type,
                    null        => $tb_null,
                    key         => $tb_key,
                    default     => $tb_default,
                };
            }
        }

        my $data;
        if($type eq 'list') {
            $refers || $self->throw("load_structure - no class name at Global_Fields($table,$field,..)");
            $data={
                type        => $type,
                class       => $refers,
            };
            $ckeys{$refers}=$field;
        }
        elsif($type eq 'key') {
            $refers || $self->throw("load_structure - no class name at Global_Fields($table,$field,..)");
            $data={
                type        => $type,
                refers      => $refers,
                key_format  => $key_format || '<$RANDOM$>',
                key_unique_id => $uid,
                key_length  => $maxlength || 30,
                key_charset => $charset,
            };
            $tkeys{$table}=$field;
        }
        elsif($type eq 'connector') {
            $refers || $self->throw("load_structure - no class name at Global_Fields($table,$field,..)");
            $data={
                type        => $type,
                refers      => $refers
            };
        }
        elsif($type eq 'blob') {
            $data={
                type        => $type,
                index       => $index ? 1 : 0,
                unique      => $index==2 ? 1 : 0,
                default     => $default,
                maxlength   => $maxlength,
            };
        }
        elsif($type eq 'text' || $type eq 'words') {
            $data={
                type        => $type,
                index       => $index ? 1 : 0,
                unique      => $index==2 ? 1 : 0,
                default     => $default,
                maxlength   => $maxlength || 100,
                charset     => $charset,
            };
        }
        elsif($type eq 'real' || $type eq 'integer') {
            $data={
                type        => $type,
                index       => $index ? 1 : 0,
                unique      => $index==2 ? 1 : 0,
                default     => $default,
                minvalue    => defined($minvalue) ? 0+$minvalue : undef,
                maxvalue    => defined($maxvalue) ? 0+$maxvalue : undef,
                scale       => ($type eq 'real' ? $maxlength : 0),
            };
        }
        else {
            $self->throw("load_structure - unknown type ($type) for table=$table, field=$field");
        }
        $fields{$table}->{$field}=$data;
    }
    $cn->sql_finish($sth);

    # Doing some meta-data consistency checks & automatic upgrades if we are asked to.
    #
    if($self->{'consistency_check_requested'}) {

        # Checking if this is a 4.1 database running in a 5.0 engine. In
        # this situation all our text & binary fields will get unstripped
        # (and unstrippable!) spaces in the end.
        #
        my $need_50_upgrade=$ENV{'XAO_MYSQL_50_UPGRADE'};
        if(!$need_50_upgrade && !$ENV{'XAO_MYSQL_50_SKIP_UPGRADE'}) {
            TABLE_LOOP:
            foreach my $table (keys %fields) {
                my $flist=$fields{$table};
                foreach my $fname (keys %$flist) {
                    my $type=$flist->{$fname}->{'type'};
                    next if ($type eq 'list' || $type eq 'key' || $type eq 'connector');

                    my $tbdata=$tbdesc{$table}->{$fname.'_'} ||
                        throw $self "load_structure - no table definition for $fname in $table (how could it be?)";

                    if(defined($tbdata->{'default'}) && $tbdata->{'default'} =~ /^\s+$/) {
                        if(defined($flist->{$fname}->{'default'}) && $tbdata->{'default'} eq $flist->{$fname}->{'default'}) {
                            eprint "Very suspicious spaces in field defaults, is it a 4.1 database running in 5.0 engine?";
                            eprint "Set XAO_MYSQL_50_UPGRADE if you want to force an upgrade";
                            next;
                        }
                        else {
                            $need_50_upgrade=1;
                            last TABLE_LOOP;
                        }
                    }
                    elsif($flist->{$fname}->{'default'} =~ m/^\s{30}$/) {
                        $need_50_upgrade=1;
                        last TABLE_LOOP;
                    }
                }
            }

        }
        if($need_50_upgrade) {
            my $debug_status=XAO::Utils::get_debug();
            XAO::Utils::set_debug(1);
            dprint "This database seems to be a 4.1 MySQL database running in a 5.0 MySQL engine.";
            dprint "Difference in treating trailing spaces will prevent the database from working properly.";
            dprint "If you believe this to be incorrect please set XAO_MYSQL_50_SKIP_UPGRADE env. variable.";
            dprint "**";
            dprint "** A fully automatic upgrade will be attempted in 15 seconds, interrupt to abort.";
            dprint "** It MAY BE dangerous, a restore from a textual backup made in 4.1 is always better!";
            dprint "** The update may take a long time and it's better to let it run all the way through";
            dprint "** once it is started";
            dprint "**";
            sleep 15;

            dprint "Converting meta-data (Global_Fields & Global_Classes) to new format";
            dprint "-";
            my %to_convert;
            my %metatables=(
                Global_Fields => [
                    ['table_name_','latin1',30,''],
                    ['field_name_','latin1',30,''],
                    ['type_','latin1',20,undef],
                    ['refers_','latin1',30,undef],
                    ['key_format_','latin1',100,undef],
                    ['charset_','latin1',30,undef],
                    ['default_','binary',30,undef],
                ],
                Global_Classes => [
                    ['class_name_','latin1',100,''],
                    ['table_name_','latin1',30,''],
                ],
            );
            foreach my $table (keys %metatables) {
                my $sql='';
                my @def;
                foreach my $fd (@{$metatables{$table}}) {
                    my ($fname,$charset,$maxlength,$default)=@$fd;
                    my $tdef=$self->text_field_definition($charset,$maxlength,defined $default ? undef : 1);
                    $sql.=', ' if $sql;
                    $sql.="CHANGE $fname $fname $tdef";
                    push(@def,$default) if defined $default;
                    $to_convert{$table}->{$fname}=1;
                }
                $sql="ALTER TABLE $table $sql";
                dprint "-- $sql";
                $cn->sql_do($sql,@def);
            }
            dprint "-";

            dprint "Converting BINARY fields to VARBINARY as this is the only way to store unpadded";
            dprint "strings of varying length";
            dprint "-";
            foreach my $table (keys %tbdesc) {
                my $tbdata=$tbdesc{$table};
                my $sql='';
                my @def;
                foreach my $fname (keys %$tbdata) {
                    next if $fname eq 'unique_id';

                    my $sfname=substr($fname,0,-1);
                    my $fdata=$fields{$table}->{$sfname} ||
                        throw $self "load_structure - can't find field description $table/$fname/$sfname";

                    my $charset;
                    my $maxlength;
                    my $default;
                    if($fdata->{'type'} eq 'blob') {
                        $charset='binary';
                        $maxlength=$fdata->{'maxlength'};
                        $default=$fdata->{'default'};
                    }
                    elsif($fdata->{'type'} eq 'text') {
                        $charset=$fdata->{'charset'} || throw $self "load_structure - no charset in '$fname'";
                        $maxlength=$fdata->{'maxlength'};
                        $default=$fdata->{'default'};
                    }
                    elsif($fdata->{'type'} eq 'key') {
                        $charset=$fdata->{'key_charset'} || throw $self "load_structure - no key_charset in '$fname'";
                        $maxlength=$fdata->{'key_length'};
                        $default='';
                    }
                    else {
                        next;   # nothing to do for other types
                    }
                    ### dprint "fname=$fname, charset=$charset, ml=$maxlength, def=$default";

                    ##
                    # Multiple spaces in defaults are probably there because
                    # the table is in the old format. Stripping them to the
                    # empty string.
                    #
                    if($default =~ /^\s+$/) {
                        $default='';
                        $fdata->{'default'}='';
                    }

                    ##
                    # Converting all strings, not just BINARY columns to update the DEFAULT value
                    #
                    my $tdef=$self->text_field_definition($charset,$maxlength);
                    $sql.=', ' if $sql;
                    $sql.="CHANGE $fname $fname $tdef";
                    push(@def,$default);

                    $to_convert{$table}->{$fname}=1;
                }
                if($sql) {
                    $sql="ALTER TABLE $table $sql";
                    dprint "-- $sql";
                    $cn->sql_do($sql,@def);
                }
            }
            dprint "-";

            if(!$ENV{'XAO_MYSQL_50_SKIP_TABLE_TYPE'}) {
                my @uptables=('Global_Fields','Global_Classes',keys %tbdesc);
                dprint "Upgrading tables to the new binary format.";
                dprint "The following tables will be upgraded:";
                dprint join(',',@uptables);
                dprint "-";
                foreach my $table (@uptables) {
                    my $sql="ALTER TABLE $table ENGINE=$table_types{$table}";
                    dprint "-- $sql";
                    $cn->sql_do($sql);
                }
                dprint "-";
            }

            dprint "Trimming trailing spaces on all text & binary fields.";
            dprint "Since spaces were always trimmed in MySQL up to 4.1 supposedly it is safe.";
            dprint "Use XAO_MYSQL_50_BROKEN_BINARY=1 if some fields got zero-padded (unsafe).";
            dprint "-";
            foreach my $table (keys %to_convert) {
                foreach my $fname (keys %{$to_convert{$table}}) {
                    my $sql;
                    if($ENV{'XAO_MYSQL_50_BROKEN_BINARY'}) {
                        $sql="UPDATE $table SET $fname=LEFT($fname,LENGTH(RTRIM(REPLACE($fname,'\0',' '))))";
                    }
                    else {
                        $sql="UPDATE $table SET $fname=RTRIM($fname)";
                    }
                    dprint "-- $sql";
                    $cn->sql_do($sql);
                }
            }
            dprint "-";
            dprint "All done";

            XAO::Utils::set_debug($debug_status);
        }

        # Checking that we have a charset for every text field. Altering
        # tables to binary for compatibility if the charset is not defined.
        #
        my $warning_shown;
        foreach my $table (keys %fields) {
            my $debug_status=XAO::Utils::get_debug();
            XAO::Utils::set_debug(1);

            my $sql='';
            my $flist=$fields{$table};
            my @deflist;
            my @altered_fields;
            foreach my $fname (keys %$flist) {
                my $fdata=$flist->{$fname};

                next unless ($fdata->{'type'} eq 'text' && !$fdata->{'charset'}) ||
                            ($fdata->{'type'} eq 'key' && !$fdata->{'key_charset'});

                unless($warning_shown) {
                    dprint "Some key and text fields in your database have no 'charset' value";
                    dprint "In 10 seconds we will start converting them to 'binary' for behavior compatibility.";
                    dprint "For large datasets this may require a lot of time, interrupt to abort.";
                    sleep 10;
                    $warning_shown=1;
                }

                dprint "...table '$table' has empty charset for text field '$fname', altering to 'binary'";

                my $default;
                my $maxlength;
                if($fdata->{'type'} eq 'text') {
                    $default=$fdata->{'default'};
                    $maxlength=$fdata->{'maxlength'};
                }
                else {
                    $default='';
                    $maxlength=$fdata->{'key_length'};
                }

                my $def=$self->text_field_definition('binary',$maxlength);

                $sql.=', ' if $sql;
                $sql.="CHANGE ".$fname."_ ".$fname."_ ".$def;

                push(@deflist,$default);
                push(@altered_fields,$fname);

                if($fdata->{'type'} eq 'text') {
                    $fdata->{'charset'}='binary';
                }
                else {
                    $fdata->{'key_charset'}='binary';
                }
            }
            if($sql) {
                dprint "....preparing to execute, LAST CHANCE TO ABORT";
                sleep 3;
                dprint ".....executing SQL instructions, do not interrupt";
                $sql="ALTER TABLE $table $sql";
                ### dprint $sql;
                $cn->sql_do($sql,@deflist);
                foreach my $fname (@altered_fields) {
                    $sql="UPDATE Global_Fields SET charset_='binary' WHERE table_name_='$table' AND field_name_='$fname'";
                    ### dprint $sql;
                    $cn->sql_do($sql);
                }
            }

            XAO::Utils::set_debug($debug_status);
        }
    }

    # Now loading classes translation table and putting fields
    # descriptions inside of it as well.
    #
    $sth=$cn->sql_execute("SELECT class_name_,table_name_ FROM Global_Classes");
    my %classes;
    while(my $row=$cn->sql_fetch_row($sth)) {
        my ($class,$table)=@$row;
        my $f=$fields{$table};
        $f || $self->throw("load_structure - no description for $table table (class $class)");
        $classes{$class}={
            table   => $table,
            fields  => $f,
        };
    }
    $cn->sql_finish($sth);

    # Copying key related stuff to list description which is very
    # helpful for build_structure
    #
    foreach my $class (keys %ckeys) {
        my $upper_key_name=$ckeys{$class};
        my ($data,$table)=@{$classes{$class}}{'fields','table'};
        my $key_name=$tkeys{$table};
        my $key_data=$data->{$key_name};
        my $upper_data=$classes{$key_data->{'refers'}}->{'fields'}->{$upper_key_name};
        @{$upper_data}{qw(key key_format key_length key_charset)}=
            ($key_name,@{$key_data}{qw(key_format key_length key_charset)});
    }

    # Marking that we loaded structure, and optionally that we checked meta-data consistency
    #
    $self->{'structure_loaded'}=1;
    $self->{'consistency_checked'}=$self->{'consistency_check_requested'};

    # Resulting structure
    #
    return \%classes;
}

###############################################################################

=item mangle_field_name ($)

Adds underscore to the end of field name to avoid problems with reserved
words. Could do something else in other drivers, do not count on the
fact that there would be underscore at the end.

=cut

sub mangle_field_name ($$) {
    my $self=shift;
    my $name=shift;
    defined($name) ? $name . '_' : undef;
}

###############################################################################

=item reset ()

Brings driver to usable state. Unlocks tables if they were somehow left
in locked state. Reconnects to the database if the connection expired.

=cut

sub reset () {
    my $self=shift;

    if($self->connector->sql_connected) {
        if($self->{'table_type'} eq 'innodb') {
            $self->tr_loc_rollback();
        }
        else {
            $self->unlock_tables();
        }
    }
    else {  # no point unlocking tables if we just reconnected
        dprint "Database connection expired, re-connecting";
        $self->connector->sql_connect;
    }
}

###############################################################################

=item retrieve_fields ($$$@)

Retrieves individual fields from the given table by unique ID of the
row. Always returns array reference even if there is just one field in
it.

=cut

sub retrieve_fields ($$$@) {
    my $self=shift;
    my $table=shift;
    my $unique_id=shift;

    $unique_id ||
        $self->throw("retrieve_field($table,...) - no unique_id given");

    my @names=map { $_ . '_' } @_;

    my $sql=join(',',@names);
    $sql="SELECT $sql FROM $table WHERE unique_id=?";

    my $cn=$self->connector;
    my $sth=$cn->sql_execute($sql,$unique_id);
    return $cn->sql_first_row($sth);
}

###############################################################################

=item search (\%query)

performs a search on the given query and returns a reference to an array
of arrays containing search results. Query hash is as prepared by
_build_search_query() in the Glue.

=cut

sub search ($%) {
    my $self=shift;
    my $query=get_args(\@_);

    my $sql=$query->{'sql'};

    if($query->{'options'}) {
        my $limit=int($query->{'options'}->{'limit'} || 0);
        my $offset=int($query->{'options'}->{'offset'} || 0);

        # MySQL has no syntax to specify offset without a non-zero
        # limit. Using a very large number per recommendation of mysql
        # docs.
        #
        if($limit>0 || $offset>0) {
            $sql.=' LIMIT '.($limit || '18446744073709551615');
        }

        if($offset>0) {
            $sql.=' OFFSET '.$offset;
        }
    }

    # dprint "SQL: $sql";

    my $cn=$self->connector;
    my $sth=$cn->sql_execute($sql,$query->{'values'});

    if(scalar(@{$query->{'fields_list'}})>1) {
        my @results;

        ##
        # We need to copy the array we get here to avoid replicating the
        # last row into all rows by using reference to the same array.
        #
        while(my $row=$cn->sql_fetch_row($sth)) {
            push @results,[ @$row ];
        }
        $cn->sql_finish($sth);
        return \@results;
    }
    else {
        return $cn->sql_first_column($sth);
    }

}

###############################################################################

=item search_clause_wq ($field $string)

Returns database specific syntax for REGEX matching a complete word
if database supports it or undef otherwise. For MySQL returns REGEXP
clause.

=cut

sub search_clause_wq ($$$) {
    my $self=shift;
    my ($field,$rha)=@_;
    $rha=~s/([\\'\[\]\|\{\}\(\)\.\*\?\$\^])/\\$1/g;
    ("$field REGEXP ?","[[:<:]]" . $rha . "[[:>:]]");
}

###############################################################################

=item search_clause_ws ($field $string)

Returns database specific syntax for REGEX matching the beginning of
a word if database supports it or undef otherwise. For MySQL returns
REGEXP clause.

=cut

sub search_clause_ws ($$$) {
    my $self=shift;
    my ($field,$rha)=@_;
    $rha=~s/([\\'\[\]])/\\$1/g;
    ("$field REGEXP ?","[[:<:]]$rha");
}

###############################################################################

=item store_row ($$$$$$$)

Stores complete row of data into the given table. New name is generated
in the given key field if there is no name given.

Example:

 $self->_driver->store_row($table,
                           $key_name,$key_value,
                           $conn_name,$conn_value,
                           \%row);

Connector name and connector value are optional if this list is directly
underneath of Global.

=cut

sub store_row ($$$$$$$) {
    my $self=shift;
    my ($table,$key_name,$key_value,$conn_name,$conn_value,$row)=@_;
    $key_name.='_';
    $conn_name.='_' if $conn_name;

    # If we have no transaction support we need to lock Global_Fields
    # too as it might be used in AUTOINC key formats.
    #
    my @ltab;
    if($self->{'table_type'} eq 'innodb') {
        ### dprint "store_row: transaction begin";
        $self->tr_loc_begin;
    }
    else {
        ### dprint "store_row: locking tables";
        #@ltab=($table eq 'Global_Fields' || $table eq 'Global_Classes') ? ($table) : ($table,'Global_Fields','Global_Classes');
        @ltab=($table eq 'Global_Fields') ? ($table) : ($table,'Global_Fields');
        $self->lock_tables(@ltab);
    }

    my $uid;
    if(ref($key_value) eq 'CODE') {
        my $kv;
        while(1) {
            $kv=&{$key_value};
            last unless $self->unique_id($table,
                                         $key_name,$kv,
                                         $conn_name,$conn_value,
                                         1);
        }
        $key_value=$kv;
    }
    elsif($key_value) {
        $uid=$self->unique_id($table,
                              $key_name,$key_value,
                              $conn_name,$conn_value,
                              1);
    }
    else {
        throw $self "store_row - no key_value given (old usage??)";
    }

    # Trapping for errors.
    #
    # This seems to be only needed for MySQL < 5.0.38 with MyISAM, newer versions
    # auto-unlock and auto-rollback apparently. This code adds a pretty significant
    # penalty (about 10% based on bench.pl - probably less on DB bound cases).
    # So avoiding it where we can.
    #
    if(1) {
        my $connector=$self->connector;

        local($SIG{'__DIE__'})=sub {
            my $msg=shift;
            if($self->{'table_type'} eq 'innodb') {
                $self->tr_loc_rollback;
            }
            else {
                $self->unlock_tables(@ltab);
            }
            die $msg;
        } if ($self->{'mysql_version'} < 5.00038 || $connector->need_unlock_on_error);

        # Updating or inserting
        #
        if($uid) {
            # TODO: Needs to be split into local version that is called from
            # underneath transactional cover and "public" one.
            #
            $self->update_fields($table,$uid,$row,0);
        }
        else {
            my @fn=($key_name, map { $_.'_' } keys %{$row});
            my @fv=($key_value, values %{$row});
            if($conn_name && $conn_value) {
                unshift @fn,$conn_name;
                unshift @fv,$conn_value;
            }

            my $sql="INSERT INTO $table (";
            $sql.=join(',',@fn);
            $sql.=') VALUES (';
            $sql.=join(',',('?') x scalar(@fn));
            $sql.=')';
            $connector->sql_do($sql,\@fv);
        }
    }

    if($self->{'table_type'} eq 'innodb') {
        $self->tr_loc_commit;
    }
    else {
        $self->unlock_tables(@ltab);
    }

    return $key_value;
}

###############################################################################

sub real_field_definition ($$$$) {
    my ($self,$min,$max,$scale)=@_;

    # Real translates to two different field types depending on whether
    # the scale is set or not.
    #
    my $def;
    if($scale) {
        my $pmin=defined $min ? length(abs(int($min))) : 20;
        my $pmax=defined $max ? length(abs(int($max))) : 20;
        my $precision=$pmin>$pmax ? $pmin : $pmax;
        $precision+=$scale;
        $def="DECIMAL($precision,$scale)";
    }
    else {
        $def="DOUBLE";
    }

    $def.=" NOT NULL DEFAULT ?";

    ### dprint "definition for real(",$min,",",$max,",",$scale,"): $def";

    return $def;
}

###############################################################################

=item text_field_definition

Returns a MySQL definition for the field suitable for use in CREATE
TABLE or ALTER TABLE.

Something like "TEXT CHARACTER SET 'charset' NOT NULL DEFAULT ?".

Note that the default needs to be substituted in later!

=cut

sub text_field_definition ($$$;$) {
    my ($self,$charset,$maxlength,$null)=@_;

    my $def;
    if($charset eq 'binary') {
        if($maxlength<255) {
            $def="VARBINARY($maxlength)";
        } elsif($maxlength<65535) {
            $def="BLOB";
        } elsif($maxlength<16777215) {
            $def="MEDIUMBLOB";
        } else {
            $def="LONGBLOB";
        }
    }
    else {
        if($maxlength<255) {
            $def="CHAR($maxlength)";
        } elsif($maxlength<65535) {
            $def="TEXT";
        } elsif($maxlength<16777215) {
            $def="MEDIUMTEXT";
        } else {
            $def="LONGTEXT";
        }
        $def.=" CHARACTER SET '$charset'";
    }

    return $null ? $def : "$def NOT NULL DEFAULT ?";
}

###############################################################################

=item unique_id ($$$$$)

Looks up row unique ID by given key name and value (required) and
connector name and value (optional for top level lists).

=cut

sub unique_id ($$$$$$$) {
    my $self=shift;
    my ($table,$key_name,$key_value,$conn_name,$conn_value,$translated)=@_;
    $key_name.='_' unless $translated;
    $conn_name.='_' unless $translated || !$conn_name;

    my $cn=$self->connector;
    my $sth;
    if(defined($conn_name) && defined($conn_value)) {
        $sth=$cn->sql_execute("SELECT unique_id FROM $table WHERE $conn_name=? AND $key_name=?",
                                ''.$conn_value,''.$key_value);
    }
    else {
        $sth=$cn->sql_execute("SELECT unique_id FROM $table WHERE $key_name=?",
                                ''.$key_value);
    }

    my $row=$cn->sql_first_row($sth);
    return $row ? $row->[0] : undef;
}

###############################################################################

=item update_fields ($$$;$) {

Stores new values. Example:

 $self->_driver->update_field($table,$unique_id,{ name => 'value' });

Optional last argument can be used to disable transactional wrapping if
set to a non-zero value.

=cut

sub update_fields ($$$$;$) {
    my ($self,$table,$unique_id,$data,$internal)=@_;

    ### dprint "update_fields($table,$unique_id,...)";

    $unique_id ||
        throw $self "update_field($table,..) - no unique_id given";

    my @names=keys %$data;
    return unless @names;

    my $sql="UPDATE $table SET ";
    $sql.=join(',',map { "${_}_=?" } @names);
    $sql.=' WHERE unique_id=?';

    if(!$internal && $self->{'table_type'} eq 'innodb') {
        #dprint "store_row: transaction begin";
        $self->tr_loc_begin;
    }

    $self->connector->sql_do($sql,values %$data,$unique_id);

    if(!$internal && $self->{'table_type'} eq 'innodb') {
        #dprint "store_row: transaction commit";
        $self->tr_loc_commit;
    }
}

###############################################################################

=item tr_loc_active ()

Checks if we currently have active local or external transaction.

=cut

sub tr_loc_active ($) {
    my $self=shift;
    return $self->{'tr_loc_active'} || $self->{'tr_ext_active'};
}

###############################################################################

=item tr_loc_begin ()

Starts new local transaction. Will only really start it if we do not
have currently active external transaction. Does nothing for MyISAM.

=cut

sub tr_loc_begin ($) {
    my $self=shift;
    return if $self->{'table_type'} ne 'innodb' ||
              $self->{'tr_ext_active'} ||
              $self->{'tr_loc_active'};
    $self->connector->sql_do('START TRANSACTION');
    $self->{'tr_loc_active'}=1;
}

###############################################################################

=item tr_loc_commit ()

Commits changes for local transaction if it is active.

=cut

sub tr_loc_commit ($) {
    my $self=shift;
    return unless $self->{'tr_loc_active'};
    $self->connector->sql_do('COMMIT');
    $self->{'tr_loc_active'}=0;
}

###############################################################################

=item tr_loc_rollback ()

Rolls back changes for local transaction if it is active. Called
automatically on errors.

=cut

sub tr_loc_rollback ($) {
    my $self=shift;
    return unless $self->{'tr_loc_active'};
    $self->connector->sql_do('ROLLBACK');
    $self->{'tr_loc_active'}=0;
}

###############################################################################

=item tr_ext_active ()

Checks if an external transaction is currently active.

=cut

sub tr_ext_active ($) {
    my $self=shift;
    return $self->{'tr_ext_active'};
}

###############################################################################

sub tr_ext_begin ($) {
    my $self=shift;
    $self->{'tr_ext_active'} &&
        throw $self "tr_ext_begin - attempt to nest transactions";
    $self->{'tr_loc_active'} &&
        throw $self "tr_ext_begin - internal error, still in local transaction";
    if($self->{'table_type'} eq 'innodb') {
        $self->connector->sql_do('START TRANSACTION');
    }
    $self->{'tr_ext_active'}=1;
}

###############################################################################

sub tr_ext_can ($) {
    my $self=shift;
    return $self->{'table_type'} eq 'innodb' ? 1 : 0;
}

###############################################################################

sub tr_ext_commit ($) {
    my $self=shift;

    $self->{'tr_ext_active'} ||
        throw $self "tr_ext_commit - no active transaction";

    if($self->{'table_type'} eq 'innodb') {
        $self->connector->sql_do('COMMIT');
    }
    $self->{'tr_ext_active'}=0;
}

###############################################################################

sub tr_ext_rollback ($) {
    my $self=shift;

    $self->{'tr_ext_active'} ||
        throw $self "tr_ext_rollback - no active transaction";

    if($self->{'table_type'} eq 'innodb') {
        $self->connector->sql_do('ROLLBACK');
    }
    $self->{'tr_ext_active'}=0;
}

###################################################################### PRIVATE

sub lock_tables ($@) {
    my $self=shift;
    my $sql='LOCK TABLES ';
    $sql.=join(',',map { "$_ WRITE" } @_);
    ### dprint "lock_tables: caller=".((caller(1))[3])." sql=$sql";
    $self->connector->sql_do($sql);
}

sub unlock_tables ($) {
    my $self=shift;
    ### return unless $self->connector->sql_connected;
    ### dprint "unlock_tables: caller=".((caller(1))[3])." sql=$sql";
    ### eprint "unlock_tables2: caller=".((caller(2))[3]);
    ### eprint "unlock_tables1: caller=".((caller(1))[3]);
    ### eprint "unlock_tables0: caller=".((caller(0))[3]);
    $self->connector->sql_do_no_error('UNLOCK TABLES');
    ### eprint "unlock_tables:DONE";
}

sub throw ($@) {
    my $self=shift;
    if($self->{'table_type'} eq 'innodb') {
        $self->tr_loc_rollback();
    }
    else {
        $self->unlock_tables();
    }

    $self->SUPER::throw(@_);
}

###############################################################################
1;
__END__

=back

=head1 AUTHORS

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Further reading:
L<XAO::FS>,
L<XAO::DO::FS::Glue::SQL_DBI>,
L<XAO::DO::FS::Glue>.

=cut

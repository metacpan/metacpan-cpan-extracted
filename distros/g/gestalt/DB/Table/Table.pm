
package DB::Table;

use Carp qw(cluck confess);
use Data::Dumper;
use strict;

=pod
=head1 NAME

DB::Table - An interface a database table & columns.

=head1 SYNOPSIS

    use DB::Table;

    my $table = DB::Table->open($dbh, $tableName);

    my @primaryKeys = $table->primaryKeys(); # Primary Key(s) of table
    my @fieldNames  = $table->fields();      # All other fields
    my @foreignKeys = $table->foreignKeys(); # Which fields reference other tables?

    my $field = $tabe->field('user_id');      # Get Field Data
    print "Type: " . $field->{'type'};        # varchar? int?
    print "Description: " . $field->{'desc'}; # User Description of Field.

=head1 DESCRIPTION

DB::Table is designed to be an abstrated description of a database table,
such as which columns a table has, the type/length/etc. of a columnm and
any descriptions of the table name/column names etc.

It tries to figure this information out by interrogating the database directly
(when the table is open()ed) but it this module can also be subclassed, so that
you can provide all this information yourself.

=head1 METHODS

=cut

# /* open */ {{{

=pod

=head2 Class Methods

=over 4

=item my $table = DB::Table->open($dbh, [$tableName | $tableStructure]);

If you specify a table name (string) then DB::Table will
create and return an object which represents all the information
about the table specified by the string $tableName. This table
must exist in the database that $dbh is currently connected to.

This method interrogates the database and attempts to make as much
information available as what the database can provide. If the database
supports comments on tables/columns, they are used as descriptions
such that the internal name of a column can be 'user_id' while it
can be presented to the user as 'User ID' (as an example).

You may also, however, specify your own $tableStructure (a hash-ref
which describes the table) instead of having it pulled out of the
database directly. This firstly allows one to subclass DB::Table,
so that (as an example) one can have a DB::Table::User module who's
open method can supply a pre-built table-structure to DB::Table's
open method, but also allows for customising the representation of
a given database table without modifying the database itself.

See the L</SUBCLASSING> section below for more information on the way
in which this can be done.

=back

=cut

sub open
{
    my $ref   = shift;
    my $class = ref($ref) || $ref;

    my $dbh   = shift;
    my $table = shift;

    my $tableData;

    if (ref($table) eq 'HASH')
    {
        $tableData = $table;
    }
    elsif (!ref($table))
    {
        $tableData = $class->_init($dbh, $table);
    }

    my $self = {'dbh'   => $dbh,
                'table' => $tableData};
    bless ($self, $class);

    return $self;
}
# /* open */ }}}

# /* _init */ {{{ 
sub _init
{
    my $ref    = shift;
    my $class  = ref($ref) || $ref;

    my $dbh       = shift;
    my $tableName = shift;

    # I've discovered that 'location' is a postgresql non-reserved key-word, and as such
    # $dbh->table_into() returns the TABLE_NAME in double-quotes. We protect from this by
    # removing the quotes.
    $tableName =~ s/(^\"|\"$)//g;

    my $tableSth = $dbh->table_info(undef, undef, $tableName, "TABLE");
    my $t = $tableSth->fetchrow_hashref || confess("Could not retrieve information about $tableName. Are you sure it exists?");

    my @tableDesc = split(/,/, $t->{'REMARKS'});
    my $table = { tableName  => $tableName,
                  tableDesc  => \@tableDesc,
                  fields     => [],
                  pkeyFields => [],
                  fkeyFields => [],
                  field      => {}};

    my $pkeySth = $dbh->primary_key_info(undef, undef, $tableName);
    while (my $p = $pkeySth->fetchrow_hashref)
    {
        $p->{'COLUMN_NAME'} =~ s/(^\"|\"$)//g; # See comment against $tableName
        push @{$table->{'pkeyFields'}}, $p->{'COLUMN_NAME'};
        $table->{'field'}->{$p->{'COLUMN_NAME'}}->{'pkey'} = 1;
    }

    my $fkeySth = $dbh->foreign_key_info(undef, undef, undef,
                                         undef, undef, $tableName);
    if (defined ($fkeySth))
    {
        while (my $f = $fkeySth->fetchrow_hashref)
        {
            $f->{'FK_COLUMN_NAME'} =~ s/(^\"|\"$)//g; # See comment against $tableName
            $f->{'UK_COLUMN_NAME'} =~ s/(^\"|\"$)//g; # See comment against $tableName
            $f->{'UK_TABLE_NAME'}  =~ s/(^\"|\"$)//g; # See comment against $tableName
            next unless (defined ($f->{'FK_NAME'}));
            push @{$table->{'fkeyFields'}}, $f->{'FK_COLUMN_NAME'};
            $table->{'field'}->{$f->{'FK_COLUMN_NAME'}}->{'fkey'} = {table  => $f->{'UK_TABLE_NAME'},
                                                                     field  => $f->{'UK_COLUMN_NAME'}};
        }
    }

    my $refKeySth = $dbh->foreign_key_info(undef, undef, $tableName,
                                           undef, undef, undef);
    my $refKeySth = $dbh->foreign_key_info(undef, undef, $tableName,
                                           undef, undef, undef);
    if (defined ($refKeySth))
    {
        while (my $ref = $refKeySth->fetchrow_hashref)
        {
            $ref->{'FK_TABLE_NAME'}  =~ s/(^\"|\"$)//g; # See comment against $tableName
            $ref->{'FK_COLUMN_NAME'} =~ s/(^\"|\"$)//g; # See comment against $tableName
            $ref->{'UK_COLUMN_NAME'} =~ s/(^\"|\"$)//g; # See comment against $tableName
            next unless (defined ($ref->{'FK_NAME'}));
            push @{$table->{'rkeys'}}, {table  => $ref->{'FK_TABLE_NAME'},
                                        field  => $ref->{'FK_COLUMN_NAME'},
                                        pkey   => $ref->{'UK_COLUMN_NAME'}};
        }
    }

    my $columnSth = $dbh->column_info(undef, undef, $tableName, undef);
    while (my $c = $columnSth->fetchrow_hashref)
    {
        $c->{'COLUMN_NAME'} =~ s/(^\"|\"$)//g; # See comment against $tableName
        push @{$table->{'fields'}}, $c->{'COLUMN_NAME'} unless ($table->{'field'}->{$c->{'COLUMN_NAME'}}->{'pkey'});

        my $is_array = 0;
        if ($c->{'TYPE_NAME'} =~ s/\[\]$//g)
        {
            $is_array = 1;
        }

        $table->{'field'}->{$c->{'COLUMN_NAME'}}->{'name'}     = $c->{'COLUMN_NAME'};
        $table->{'field'}->{$c->{'COLUMN_NAME'}}->{'desc'}     = $c->{'REMARKS'};
        $table->{'field'}->{$c->{'COLUMN_NAME'}}->{'type'}     = $c->{'TYPE_NAME'};
        $table->{'field'}->{$c->{'COLUMN_NAME'}}->{'type_num'} = $c->{'DATA_TYPE'};
        $table->{'field'}->{$c->{'COLUMN_NAME'}}->{'length'}   = $c->{'COLUMN_SIZE'};
        $table->{'field'}->{$c->{'COLUMN_NAME'}}->{'read'}     = 1;
        $table->{'field'}->{$c->{'COLUMN_NAME'}}->{'write'}    = 1 unless ($table->{'field'}->{$c->{'COLUMN_NAME'}}->{'pkey'});
        $table->{'field'}->{$c->{'COLUMN_NAME'}}->{'nullable'} = $c->{'NULLABLE'};
        $table->{'field'}->{$c->{'COLUMN_NAME'}}->{'is_array'} = $is_array;
        # There is no equivalent in MySQL, but if the user wishes to customise
        # this manually they may. The evaluation/checking of the constraint should
        # still work.
        $table->{'field'}->{$c->{'COLUMN_NAME'}}->{'constraint'} = $c->{'pg_constraint'};
        $table->{'field'}->{$c->{'COLUMN_NAME'}}->{'validate'} = { regex => '^.*$',
                                                                   error => ''};
    }
    return $table;
}
# /* _init */ }}} 

# /* componentName */ {{{

=pod

=head2 Object Methods

=over 4

=item my $name = $table->componentName();

If this module is used as part of a MCV-type framework, then this
method can be used to get at a version of the table-name that
is all lower-case except for the first character. Its so that
you can use it to derive the name of perl modules that handle the
different aspects of the of the Controll/Model/View, for example,
you may have a controller, called MyApp::Controller::[Table_name]
who's job is to interact with the Model layer (of which this module
can form a part).

If you are not using this module in an MCV-type framework, then you
can just ignore this method

=cut

sub componentName
{
    my $self = shift;
    return ucfirst(lc($self->{'table'}->{'tableName'}));
}
# /* componentName */ }}}

# /* fields */ {{{

=pod

=item my @fieldNames = $table->fields();

This method returns an array (of strings) of the names of all fields (columns)
in this table, except for the primary keys. To get the list of primary keys
see the L</primaryKeys> method below.

=cut

sub fields
{
    my $self = shift;

    return @{$self->{'table'}->{'fields'}};
}
# /* fields */ }}}

# /* summaryFields */ {{{

=pod

=item my @summaryFields = $table->summaryFields();

If you have supplied your own tableStructure, you can provide
a list of "summaryFields" which can be a subset of the full
list of fields, so that (as an example) if your application is
displaying a list of users, you might not want to display everything
about every user, but rather just display their name & date-of-birth.

If no summaryFields are defined, however, then this method acts the
same as the L<fields|fields()> method.

=cut
sub summaryFields
{
    my $self = shift;

    if (exists($self->{'table'}->{'summaryFields'}))
    {
        return @{$self->{'table'}->{'summaryFields'}};
    }
    return $self->fields;
}
# /* summaryFields */ }}}

# /* primaryKeys */ {{{
=pod

=item my @primaryKeys = $table->primaryKeys();

This method returns a list of the names of field(s) which are primary keys.

=cut
sub primaryKeys
{
    my $self = shift;
    return @{$self->{'table'}->{'pkeyFields'}};
}
# /* primaryKeys */ }}}

# /* foreignKeys */ {{{
=pod

=item my @foreignKeys = $table->foreignKeys();

This method returns the list of field\column names in this table that
refer to other tables.

=cut
sub foreignKeys
{
    my $self = shift;
    return @{$self->{'table'}->{'fkeyFields'}};
}
# /* foreignKeys */ }}}

# /* field */ {{{
=pod

=item my $field = $table->field($fieldName);

This method returns a hash reference structure which represents all of the
properties the individual field specified by $fieldName

  The elements of this hash are as follows (* means required):
  name*      => scalar(string) : The name of the field/column
  type*      => scalar(string) : The SQL data type of the field/column
  type_num   => scalar(int)    : The numeric data type
  is_array   => scalar(bool)   : If the column can hold arrays (Postgres Only).
  length*    => scalar(int)    : The size of the field in bytes
  nullable   => scalar(boolean): If this field/column can store NULL values
  desc       => scalar(string) : The human description of this field/column
  read       => scalar(boolean): Indicate if this column/field can be read *** NOT YET USED ***
  write      => scalar(boolean): Indicate if this column/field can be modified *** NOT YET USED ***
  constraint => scalar(string) : The SQL constraint associated with the field/column
                                 for example, '(character_length(username) >= 5)' will evaluate
                                 the query against the database before inserting/updating.
                                 This is useful because, although PostgreSQL has built-in constraints,
                                 I havent found a nice way to trap which field/value caused the failure,
                                 and has the added advantage that databases that dont support
                                 constraints but do support CASE..END can also make use of this.
  validate   => {regex  => scalar(string) : In addition to the constraint field,
                                            data can also be validated using regular expressions,
                                            eg:  '^[\w\.]+\@[\w\.]+\.(com|net|org)$'
                                            could be used to validate that an email address
                                            belongs to the .com, .net or .org domain.
                 error  => scalar(string)}: If validation fails, then this error message will be used.

The constraint field is prefered over using the validate regular expression,
because (provided the database supports them in the first place) they will still apply
regardless of the means in which  the database is accessed. If the database does not support
CASE...END statements, however, then this can be used as a fall-back.

=cut
sub field
{
    my $self = shift;
    my $name = shift;
    return $self->{'table'}->{'field'}->{$name};
}
# /* field */ }}}

# /* name */ {{{
=pod

=item my $tableName = $table->name();

This method provides access to the underlying table name.

=cut
sub name
{
    my $self = shift;
    return $self->{'table'}->{'tableName'};
}
# /* name */ }}}

# /* desc */ {{{
=pod

=item my $desc = $table->desc();

The return value of the desc() method actually returns an array-reference. The first
element being the singular description, to be used in the context of 1 row, while
the second element is the plural of the first.

Tables have 2 descriptions: The first being the singular, the second being
the plural of. For example, a table called 'software_users' could have a singular
description of 'User' while the plural could be 'Users'. As this (and other) information
is best stored in the database itself (in the form of comments) the comment 
should be 'User,Users' (ie, singular/plural seperated by a comma).

=cut
sub desc
{
    my $self = shift;
    return $self->{'table'}->{'tableDesc'};
}
# /* desc */ }}}

# /* constructRow */ {{{
=pod

=item my $row = $table->constructRow($hashRef);

This method can be used to construct an instance of a DB::Table::Row object.
If there happens to be a module called DB::Table::Row::[ current table name]
then that module is used instead of the vanilla DB::Table::Row module. This
allows the table to interact with subclasses of DB::Table::Row, so that you
can customise it.

See L<DB::Table::Row> for more info.

=cut
sub constructRow
{
    my $self = shift;
    my $obj  = shift;

    my $className = sprintf("DB::Table::Row::%s", $self->componentName());
    if ($className->can('construct'))
    {
        return $className->construct($self->{'dbh'}, $self, $obj);
    }
    return DB::Table::Row->construct($self->{'dbh'}, $self, $obj);
}
# /* constructRow */ }}}

# /* getRowByPKey */ {{{
=pod

=item my $row = $table->getRowByPKey($id);

This method will return a DB::Table::Row object which represents
the row identified by the primary key $id. If there happens to be
a module called DB::Table::Row::[ current table name] then that
module is used instead of the vanilla DB::Table::Row module. This
allows the table to interact with subclasses of DB::Table::Row, so
that you can customise it.

See L<DB::Table::Row> for more info.

=cut
sub getRowByPKey
{
    my $self = shift;
    my $className = sprintf("DB::Table::Row::%s", $self->componentName);
    if ($className->can('getByPKey'))
    {
        return $className->getByPKey($self->{'dbh'}, $self, @_);
    }
    return DB::Table::Row->getByPKey($self->{'dbh'}, $self, @_);
}
# /* getRowByPKey */ }}}

# /* getRowsByPKey */ {{{
=pod

=item my $row = $table->getRowsByPKey($id);

This is the same as L<getRowByPKey> but it provides the context of pluarlity,
so using this method indicates that you're expecting more than 1 row.

=cut
sub getRowsByPKey
{
    my $self = shift;
    return $self->getRowByPKey(@_);
}
# /* getRowsByPKey */ }}}

# /* getRowsByFKey */ {{{
=pod

=item my @rows = $table->getRowsByFKey($fkeyName);

If the specified $fkeyName is a foreign key which references a field in
another table, then the rows belonging to the referenced table are
returned where the refered to field contains the value of the specified
$fkeyName.  If there happens to be a module called DB::Table::Row::[ current table name]
then that module is used instead of the vanilla DB::Table::Row module. This
allows the table to interact with subclasses of DB::Table::Row, so that you
can customise it.

=cut
sub getRowsByFKey
{
    my $self      = shift;
    my $fKeyName  = shift;
    my $className = sprintf("DB::Table::Row::%s", $self->componentName);
    if ($className->can('getByFKey'))
    {
        return $className->getByFKey($self->{'dbh'}, $self, $fKeyName, @_);
    }
    return DB::Table::Row->getByFKey($self->{'dbh'}, $self, $fKeyName, @_);
}
# /* getRowsByFKey */ }}}

# /* searchRowsByString */ {{{ 
=pod

=item my @rows = $table->searchRowsByString($string);

All rows in the specified table which have a column which matches the specified
string are returned by this function.

  TODO: Accept some sort of structure which defines a where clause, ie:
  { columnName => { matchType => '=', value => $string } }

=cut
sub searchRowsByString
{
    my $self = shift;
    my $className = sprintf("DB::Table::Row::%s", $self->componentName);
    if ($className->can('searchByString'))
    {
        return $className->searchByString($self->{'dbh'}, $self, @_);
    }
    return DB::Table::Row->searchByString($self->{'dbh'}, $self, @_);
}
# /* searchRowsByString */ }}} 

# /* fkeyTable */ {{{
=pod

=item my $foreignTable = $table->fkeyTable($foreignKey);

A Table object which represents the table referenced by the specified
foreign key is returned.
If there happens to be a module called DB::Table::[ foreign table name]
then that module is used instead of the vanilla DB::Table module. This
allows the table to interact with subclasses of DB::Table, so that you
can customise it on a per-table basis.

=cut
sub fkeyTable
{
    my $self = shift;

    my $fkeyName = shift;
    if (exists($self->{'table'}->{'field'}->{$fkeyName}->{'fkey'}))
    {
        my $fkeyTableName = $self->{'table'}->{'field'}->{$fkeyName}->{'fkey'}->{'table'};
        my $fkeyClass = sprintf("DB::Table::%s", ucfirst(lc($fkeyTableName)));
        if ($fkeyClass->can('open'))
        {
            return $fkeyClass->open($self->{'dbh'});
        }
        return DB::Table->open($self->{'dbh'}, $fkeyTableName);
    }
    cluck(sprintf("Foreign Key %s does not exist in %s", $fkeyName, $self->{'table'}->{'tableName'}));
    return undef;
}
# /* fkeyTable */ }}}

# /* referingTables */ {{{
=pod

=item my @tables = $table->referingTables([$keyField]);

With no arguments, a list of table objects which have a foreign key which
refers to a key in $table. If a $keyField is specified, then only tables
which refer to $keyField in $table are returned.
If there happens to be a module called DB::Table::[ foreign table name]
then that module is used instead of the vanilla DB::Table module. This
allows the table to interact with subclasses of DB::Table, so that you
can customise it on a per-table basis.

=cut
sub referingTables
{
    my $self = shift;

    my $pkey = shift;
    my @tables;
    foreach my $rkey (@{$self->{'table'}->{'rkeys'}})
    {
        if ((not $pkey) or ($pkey eq $rkey->{'pkey'}))
        {
            my $tableClass = sprintf("DB::Table::%s", ucfirst(lc($rkey->{'table'})));
            if ($tableClass->can('open'))
            {
                push @tables, $tableClass->open($self->{'dbh'});
            }
            else
            {
                push @tables, DB::Table->open($self->{'dbh'}, $rkey->{'table'});
            }
        }
    }
    return @tables;
}
# /* referingTables */ }}}

# /* getRowsWhere */ {{{
=pod

=item my @rows = $table->getRowsWhere($whereClause, $bindParams, $options);

This method allows you to fetch rows from the specified table using
a custom where clause.

=back

=cut

sub getRowsWhere
{
    my $self = shift;

    my $className = sprintf("DB::Table::Row::%s", $self->componentName);
    if ($className->can('getRowsWhere'))
    {
        return $className->getRowsWhere($self->{'dbh'}, $self, @_);
    }
    return DB::Table::Row->getRowsWhere($self->{'dbh'}, $self, @_);
}
# /* getRowsWhere */ }}}

=pod

=head2 SUBCLASSING

If you wish to subclass this module, you may specify your own data-structure
in your own open() method, and pass this as a parameter to this class's open()
method. For example, consider a table which has a list of CPU's:

  CREATE TABLE processor_types
  (
    id serial NOT NULL,
    p_type varchar(255) NOT NULL UNIQUE,
    PRIMARY KEY (id),
  );
  COMMENT ON TABLE processor_types IS 'Processor Type,Processor Types';
  COMMENT ON COLUMN processor_types.id IS 'Processor Type ID';
  COMMENT ON COLUMN processor_types.p_type IS 'Processor Type';

  CREATE TABLE servers
  (
    id serial NOT NULL,
    ...
    processor_type_id int4 NOT NULL REFERENCES processor_types(id),
    PRIMARY KEY (id)
  );
  COMMENT ON TABLE servers IS 'Device,Device List';
  ...
  COMMENT ON COLUMN servers.processor_type_id IS 'Processor Type';

You could then create a perl module called DB::Table::Processor_types,
and a module called DB::Table::Servers as follows:

  package DB::Table::Processor_types;
  use DB::Table;
  our @ISA = (qw(DB::Table));

  sub open
  {
    my $ref   = shift;
    my $class = ref($ref) || $ref;

    my $dbh = shift || confess ("Usage: $class->open(\$dbh)");

    my $tableData = {
          'pkeyFields' => [
                            'id'
                          ],
          'fields' => [
                        'p_type'
                      ],
          'tableDesc' => [
                           'Processor Type',
                           'Processor Types'
                         ],
          'tableName' => 'processor_types',
          'fkeyFields' => [],
          'rkeys' => [
                       {
                         'table' => 'servers',
                         'pkey' => 'id',
                         'field' => 'processor_type_id'
                       }
                     ],
          'field' => {
                       'p_type' => {
                                        'name' => 'processor',
                                        'length' => 255,
                                        'nullable' => '0',
                                        'desc' => 'Processor Type',
                                        'read' => 1,
                                        'type' => 'character varying',
                                        'constraint' => '(p_type != \'\')',
                                        'write' => 1
                                      },
                       'id' => {
                                 'name' => 'id',
                                 'length' => 4,
                                 'nullable' => '0',
                                 'desc' => 'Processor Type ID',
                                 'read' => 1,
                                 'pkey' => 1,
                                 'type' => 'integer',
                                 'constraint' => undef,
                               }
                     }
        };
    return $class->SUPER::open($dbh, $tableData);
  }
  1;

  package DB::Table::Servers;

  use Carp qw(cluck);
  use DB::Table;
  our @ISA = (qw(DB::Table));

  sub open
  {
      my $ref   = shift;
      my $class = ref($ref) || $ref;

      my $dbh = shift || confess ("Usage: $class->open(\$dbh)");
      my $tableData = {
          'pkeyFields' => [
                            'id'
                          ],
          'fields' => [
                        ...,
                        'processor_type_id',
                        ...
                      ],
          'tableDesc' => [
                           'Device',
                           'Device List'
                         ],
          'tableName' => 'servers',
          'fkeyFields' => [
                            'processor_type_id',
                          ],
          'field' => {
                       'id' => {
                                 'name' => 'id',
                                 'length' => 4,
                                 'nullable' => '0',
                                 'desc' => 'Device ID',
                                 'read' => 1,
                                 'pkey' => 1,
                                 'type' => 'integer',
                                 'constraint' => undef,
                                 'validate' => {
                                                 'regex' => '^.*$',
                                                 'error' => ''
                                               }
                               },
                       'processor_type_id' => {
                                                'name' => 'processor_type_id',
                                                'fkey' => {
                                                            'table' => 'processor_types',
                                                            'field' => 'id'
                                                          },
                                                'length' => 4,
                                                'nullable' => '0',
                                                'desc' => 'Processor Type',
                                                'read' => 1,
                                                'type' => 'integer',
                                                'constraint' => '(processor_type_id > 0)',
                                                'write' => 1
                                              }
                     }
        };
    return $class->SUPER::open($dbh, $tableData);
  }

  1;

=head1 AUTHOR

Bradley Kite <bradley-cpan@kitefamily.co.uk>

If you wish to email me, then please remove the '-cpan' part
of my email address as anything addressed to 'bradley-cpan'
is assumed to be spam and is not read.

=head1 SEE ALSO

L<DB::Table::Row>, L<DBI>, L<perl>

=cut

1;

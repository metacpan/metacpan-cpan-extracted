#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
# This program is open source software
#
#
#----------------------------------------------------------------------------
# Original idea:   David Winters <winters@bigsnow.org>
#----------------------------------------------------------------------------

=head1 NAME

ePortal::ThePersistent::Base - Base class for storage objects

=head1 SYNOPSYS

This package is used for handy work with database objects: SELECT, UPDATE,
INSERT, DELETE.


=head1 METHODS

=cut


package ePortal::ThePersistent::Base;
    our $VERSION = '4.5';

    use strict;
    use Carp;
    use DBI;
    use Params::Validate qw/:types/;

    use ePortal::ThePersistent::DataType::Array;
    use ePortal::ThePersistent::DataType::Date;
    use ePortal::ThePersistent::DataType::DateTime;
    use ePortal::ThePersistent::DataType::Number;
    use ePortal::ThePersistent::DataType::VarChar;
    use ePortal::ThePersistent::DataType::YesNo;

    our $AUTOLOAD;


=head2 new()

Object constructor. Parameters:

=over 4

=item * Attributes

HASHREF or ARRAYREF to attributes description hashes. You can also add
attributes later with L<add_attribute()|add_attribute()>.

=item * Where

Obligatory WHERE clause for SQL statements. Added to every SQL statement.

=item * other parameters

See L<Storage related variables|Storage related variables> for details.

=back

Returns new blessed and initialized object.

=cut

my $ThePersistentParameters = {
        Table => { type => SCALAR, optional => 1 },
        DBH => {type => OBJECT, optional => 1},
        dbi_source => {type => SCALAR, optional => 1},
        dbi_username => {type => SCALAR, optional => 1},
        dbi_password => {type => SCALAR, optional => 1},
        AutoCommit => {type => BOOLEAN, optional => 1},
        SQL => {type => SCALAR, optional => 1},
        Where => {type => SCALAR | UNDEF, optional => 1 },
        Bind => { type => ARRAYREF, optional => 1},
        GroupBy => {type => SCALAR | UNDEF, optional => 1 },
        OrderBy => {type => SCALAR | UNDEF, optional => 1 },
        Attributes => {type => ARRAYREF | HASHREF, optional => 1},
        DEBUG_SQL => {type => BOOLEAN, optional => 1},
    };
############################################################################
sub new {   #09/25/02 9:27
############################################################################
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %p = Params::Validate::validate_with( params => \@_,
        spec => $ThePersistentParameters,
        allow_extra => 1 # pass extra data to subclasses. Catch this in initialize()
        );

    ### allocate a hash for the object's data ###
    my $self = {
        MetaData => {},
        Attributes => [],
        IdAttributes => [],
        TempAttributes => [],
        DEBUG_SQL => $p{DEBUG_SQL},

        dbi_source => undef,
        dbi_username => undef,
        dbi_password => undef,
    };

    bless $self, $class;

    $self->initialize( %p );
    $self->clear;

    return $self;
}##new





=head2 initialize()

Object initialization block, called from C<new()> constructor. initialize()
is used for attributes initialization. It is the place to override in
inherited modules to add its own attributes.

initialize() calls datastore() with all passed parameters.

Parameters are the same as for L<object constructor|new()>. Only Attributes
parameter is used internally.

Returns none.

=cut

########################################################################
sub initialize {
########################################################################
    my $self = shift;
    my %p = Params::Validate::validate_with( params => \@_, spec => $ThePersistentParameters );

    # initialize datastore
    $self->datastore(%p);

    # add attributes if defined
    my $attributes = $p{Attributes};
    if (ref($attributes) eq 'HASH') {
        foreach my $attr (keys %{$attributes}) {
            $self->add_attribute( $attr, $attributes->{$attr} );
        }

    } elsif (ref($attributes) eq 'ARRAY') {
        throw ePortal::Exception::Fatal(
        -text => sprintf "Package %s passed Attributes parameter as ARRAY. Deprecated!.", ref($self));

    } elsif (defined $attributes) {
        croak "Not supported Attributes parameter";
    }

    # Save some of obligatory restore_where parameters
    foreach (qw/Bind Where GroupBy OrderBy/) {
        $self->{$_} = $p{$_};
    }
}##initialize



############################################################################
sub initialize_attribute    {   #05/27/2003 2:30
############################################################################
    my ($self, $att_name, $attr) = @_;

    $attr->{dtype} ||= 'VarChar';
    $attr->{type}  ||= 'Persistent';

    if ( $attr->{dtype} =~ /^v/io) {           # VarChar defaults
        $attr->{maxlength} ||= 255;

    } elsif ( $attr->{dtype} =~ /^n/io) {           # Number defaults
        $attr->{maxlength} ||= 11;
    }

    #$attr->{fieldtype} ||= 'textfield';
    $attr->{label}     ||= $att_name;
    $attr->{header}    ||= $att_name;

    return $attr;
}##initialize_attribute

=head2 datastore()

It is the place to initialize database related things like DBH connection.
Called from L<new()|new()> constructor.

Should not be called directly.

Parameters are the same as for L<object constructor|new()>. See L<Storage
related variables|Storage related variables> for more details.

Returns newly created database handle.

=cut

############################################################################
sub datastore   {   #09/07/00 1:49
############################################################################
    my $self = shift;
    my %p = Params::Validate::validate_with( params => \@_, spec => $ThePersistentParameters );

    #Current MySQL database layer does not use transactions
    $self->{AutoCommit} = 1;

    # Connect to DBI source
    if ( ref($p{DBH}) ) {
        # Ready to use DBH passed
        $self->{DBH} = $p{DBH};
        $self->{CreatedDBH} = 0;

    } else {
        # Need to establish new connection
        $self->{dbi_source} = $p{dbi_source};
        $self->{dbi_username} = $p{dbi_username};
        $self->{dbi_password} = $p{dbi_password};

        my $dbh = DBI->connect($p{dbi_source}, $p{dbi_username}, $p{dbi_password},
                {AutoCommit => $self->{AutoCommit},
                 PrintError => 0,
                 RaiseError => 0});
        $self->{CreatedDBH} = 1;
        $self->_check_dbi_error("Can't connect to database: $p{dbi_username}\@$p{dbi_source}");
        $self->{DBH} = $dbh;
    }


    # Discover base Table name
    $self->{SQL} = $p{SQL};
    $self->{Table} = $p{Table};
    if ( ! $self->{SQL} and ! $self->{Table} ) {
        # Perform auto-discovery mechanics
        my $table = ref $self;
        $table =~ s/.*://o;      # last word in object's class name
        $self->{Table} = $table;
    }

    return $self->{DBH};
}



########################################################################
# Function:    DESTROY
# Description: Object destructor. if the object created a DBH (i.e.
#               it was not passed a DBH) then disconnect it
# Parameters:  None
# Returns:     None
########################################################################
sub DESTROY {
    my $self = shift;

    if (ref($self->{STH})) {
        $self->{STH}->finish;
        $self->{STH} = undef;
    }

    if ($self->{CreatedDBH}) {
        $self->{DBH}->disconnect();
        _check_dbi_error("Can't disconnect from database");
    }
    return;
}

############################################################################
# Returns number of rows in SELECT statement
############################################################################
sub rows    {   #08/26/2003 4:48
############################################################################
    my $self = shift;
    if (ref($self->{STH})) {
        return $self->{STH}->rows;
    } else {
        return undef;
    }
}##rows

########################################################################
# Function:    AUTOLOAD
# Description: Gets/sets the attributes of the object.
#              Uses autoloading to access any instance field.
# Parameters:  $value (optional) = value to set the attribute to
# Returns:     $value = value of the attribute
########################################################################
sub AUTOLOAD {
    my($self, @data) = @_;

    my $name = $AUTOLOAD;   ### get name of attribute ###
    $name =~ s/.*://o;       ### strip fully-qualified portion ###
    $self->value($name, @data);
}





=head2 attribute()

Returns named attribute parameters as hash. In scalar context returns
hash ref.

If attribute does not exists then undef is returned. This method is used to
check attribute existance.

=over 4

=item * attribute name

Name of attribute to return.

=back

=cut

############################################################################
sub attribute    {   #09/26/02 10:35
############################################################################
    my ($self, $attribute) = Params::Validate::validate_with(params => \@_,
        spec => [
            { type => OBJECT },
            { type => SCALAR }
        ]);
    $attribute = lc($attribute);

    if (defined $self->{MetaData}->{$attribute}) {
        $self->{MetaData}->{$attribute};
    } else {
        return undef;
    }
}##attribute



=head2 attributes()

Returns names of ALL attributes of the object as array.

=cut

############################################################################
sub attributes  {   #09/26/02 10:41
############################################################################
    my ($self) = Params::Validate::validate_with(params => \@_,
        spec => [
            { type => OBJECT },
        ]);

    return ( @{ $self->{IdAttributes}},
             @{ $self->{Attributes}},
             @{ $self->{TempAttributes}} );
}##attributes

sub attributes_i  {my $self = shift; ( @{ $self->{IdAttributes}   } )  }
sub attributes_a  {my $self = shift; ( @{ $self->{Attributes}     } )  }
sub attributes_t  {my $self = shift; ( @{ $self->{TempAttributes} } )  }
sub attributes_ia {my $self = shift; ( @{ $self->{IdAttributes}   }, @{ $self->{Attributes}     } )  }
sub attributes_at {my $self = shift; ( @{ $self->{Attributes}     }, @{ $self->{TempAttributes} } )  }
sub attributes_it {my $self = shift; ( @{ $self->{IdAttributes}   }, @{ $self->{TempAttributes} } )  }


=head2 add_attribute()

Add an attribute to the object. Attribute information is used when SQL
statement is constructed or when attribute datatype is needed to know.

=over 4

=item * name

=item * hashref

HASHREF if a hash with a description of attribute type, datatype
parameters, and visualization parameters. See L<Attribute
Parameters|ATTRIBUTE PARAMETERS> for details.

=back

Returns none.

=cut

########################################################################
sub add_attribute {
########################################################################
    my($self, $name, $parameters) = Params::Validate::validate_with(params => \@_,
        spec => [
            { type => OBJECT },                         # self
            { type => SCALAR },                         # name
            { type => HASHREF | OBJECT},               # type [id,pers,temp]
        ]);
    $name = lc($name);

    $self->initialize_attribute( $name, $parameters );

    # Create an object for datatype and initialize it to default value
    my $object;
    my $data_type = $parameters->{dtype};
    if ($data_type =~ /^v/i) {
        $object = new ePortal::ThePersistent::DataType::VarChar( %$parameters );

    } elsif ($data_type =~ /^n/i) {
        $object = new ePortal::ThePersistent::DataType::Number( %$parameters );

    } elsif ($data_type =~ /^datet/i) {
        $object = new ePortal::ThePersistent::DataType::DateTime( %$parameters );

    } elsif ($data_type =~ /^d/i) {
        $object = new ePortal::ThePersistent::DataType::Date( %$parameters );

    } elsif ($data_type =~ /^y/i) {
        $object = new ePortal::ThePersistent::DataType::YesNo( %$parameters );

    } elsif ($data_type =~ /^a/i) {
        $object = new ePortal::ThePersistent::DataType::Array( %$parameters );

    } else {
        croak "data type ($data_type) of attribute ($name) is invalid";
    }
    $self->{MetaData}->{$name} = $object;

    # Save attribute name
    my $type = $parameters->{type};
    if ($type =~ /^i/oi) {       ### ID fields ###
        push(@{$self->{IdAttributes}}, $name);

    } elsif ($type =~ /^p/oi) {  ### ThePersistent fields ###
        push(@{$self->{Attributes}}, $name);

    } elsif ($type =~ /^t/oi) {  ### transient fields ###
        push(@{$self->{TempAttributes}}, $name);

    } else {
        croak "field type ($type) is invalid";
    }

    return;
}



=head2 value()

Get or set the value of attribute.

=over 4

=item * name

Name of attribute

=item * new value

Optional value of attribute to set.

=back

Returns new or current value of attribute.

=cut

########################################################################
sub value {
########################################################################
    my($self, $attribute, @data) = Params::Validate::validate_with(params => \@_,
        spec => [
            { type => OBJECT },                         # self
            { type => SCALAR },                         # attribute
        ], allow_extra => 1);

    $attribute = lc($attribute);  ### attributes are case insensitive ###

    ### check for existence of the attribute ###
    if (my $a = $self->attribute($attribute)) {
        $a->value(@data);
    } else {
        croak "'$attribute' is not an attribute of this object:",
            join(',', keys %{$self->{MetaData}});
    }
}



=head2 clear()

Clears (undefs) the fields of the object. This method calls
L<value()|value()> directly. No overloaded value() methods will be
triggered.

Returns none.

=cut

########################################################################
sub clear {
########################################################################
    my $self = shift;

    foreach ( $self->attributes ) {
        $self->attribute($_)->clear();
    }
}




=head2 update()

Updates existing object in the datastore.

Returns True if UPDATE was successful.

=cut

############################################################################
sub update  {   #09/07/00 9:17
############################################################################
    my ($self) = shift;

    ### check validity of object ID ###
    if (! $self->check_id()) {
        warn "update() called for object without valid id: ", ref($self);
        return 0;
    }

    if ($self->{SQL}) {
        croak "This object is read-only";
        # I don't know TABLE name. Extract it from SELECT
    }

    my $dbh = $self->dbh();  ### database handle ###

    ### build the SET clause of SQL ###
    my $sql = "UPDATE $self->{Table} SET \n";
    my (@values, @binds) = ();
    foreach my $field ( $self->attributes_a) {
        push @values, "$field=?";
        push @binds, $self->attribute($field)->sql_value;
    }
    $sql   .= join(",\n", @values);

    ### build the WHERE clause of SQL ###
    @values = ();
    foreach my $field ( $self->attributes_i ) {
        push @values, "$field=?";
        push @binds, $self->attribute($field)->sql_value;
    }
    $sql .= " WHERE " . join(" AND ", @values) . "\n";

    warn "SQL = $sql BINDS(", join(',', @binds), ")\n"
        if $self->{DEBUG_SQL};

    ### execute the SQL ###
    my $result = undef;
#    eval {
        $result = $dbh->do($sql, undef, @binds);
        $self->_check_dbi_error("Can't execute SQL statement:\n".
                "$sql\n" .
                "BINDS(" . join(',', @binds));
#    };
#    if ($@) {
#        $dbh->rollback() unless $self->{AutoCommit};
#        croak $@;
#    } else {
        $dbh->commit() unless $self->{AutoCommit};
#    }

    return $result;
}


=head2 save()

Saves the object to the data store (insert or update).

Returns:

1 if the object did previously exist in the datastore

0 if the object did not previously exist

undef on error

=cut

########################################################################
sub save {
########################################################################
    my $self = shift;
    my $result = undef;

    ### determine if the object is already saved in the database ###
    if ( $self->check_id() ) {
        $result = $self->update() ? 1 : undef;
    } else {
        $result = $self->insert() ? 0 : undef;
    }
    return $result;
}




=head2 restore()

Restores the object from the data store.

=over 4

=item * @id

Unique identifier assigned to the object

=back

Returns True if the object was successfully restored and False if the
object is not found.

=cut

########################################################################
sub restore {
########################################################################
    my ($self, @id) = @_;

    ### check that the ID is valid ###
    if (not $self->check_id(@id)) {
      $self->clear;
      return undef;
    }

    ### build SQL-like WHERE clause with ID ###
    my (@exprs, @bind_values) = ();
    foreach my $idfield ( $self->attributes_i ) {
      push @exprs, "$idfield=?";
      push @bind_values, shift @id;
    }
    my $expr = join(' and ', @exprs);

    ### restore the object ###
    $self->restore_where( where => $expr, bind => \@bind_values);
    my $rc = $self->restore_next();

    # Extra check 
    # SELECT * WHERE id='2001-10' will select ID=2001 !!!
    # Double check for the same id
    if ($rc) {  # only if something found
        foreach my $idfield ( $self->attributes_i ) {
            my $id_value = shift @bind_values;
            $rc = undef if lc($self->value($idfield)) ne  lc($id_value);
        }
    }    

    if (ref ($self->{STH})) {
      $self->{STH}->finish;
      $self->{STH} = undef;
    }

    return $rc;
}


=head2 restore_all()

Restores all the objects from the data store and optionally sorted.

=over 4

=item * order_by

Optional. Sort expression for the objects in the form of an SQL ORDER BY
clause.

=back

Returns none.

=cut

########################################################################
sub restore_all {
########################################################################
  my ($self, $order_by) = @_;

  $self->restore_where(order_by => $order_by);
}


=head2 restore_next()

Restores the next object from the data store that matches the query
expression in the previous restore_where or restore_all method calls.

Returns True if an object was restored and False if an object was not
restored - no more objects to restore

=cut

########################################################################
sub restore_next {
########################################################################
    my $self = shift;

    # Clear data
    $self->clear;

    unless (ref($self->{STH})) {
        return undef;
    }

    # Fecth next row of data
    my @ary;
    unless (@ary = $self->{STH}->fetchrow_array()) {
        $self->{STH}->finish;
        $self->{STH} = undef;
        return undef;
    }

    $self->{records_fetched} ++;
    my @field_names = @{$self->{STH}->{NAME_lc}};
    for my $i (0 .. $self->{STH}->{NUM_OF_FIELDS}-1) {
        $self->attribute($field_names[$i])->value(shift @ary);
    }

    1;
}


=head2 data()

Gets/Sets all data fields of an object.

=over 4

=item * $href

A reference to a hash of object data. Hash keys are named of attributes.

=back

Returns $href - a reference to a hash of object data

=cut

########################################################################
sub data {
########################################################################
    my ($self, $href) = Params::Validate::validate_with(params => \@_,
        spec => [
            { type => OBJECT },
            { type => UNDEF | HASHREF, optional => 1}
        ]);

    ### set data fields ###
    if (defined $href) {
        foreach my $attr ( $self->attributes ) {
            # avoid inheritance
            ePortal::ThePersistent::Base::value($self, $attr, $href->{$attr});
        }
    }
    return unless defined wantarray;

    ### get data fields ###
    $href = {};
    foreach my $attr ( $self->attributes ) {
        $href->{$attr} = $self->value($attr);
    }

    return $href;
}


=head2 insert()

Inserts new object into datastore. If ID attribute is C<auto_increment>
then newly generated number for ID is stored in object via L<_id()|_id()>.

Returns True if INSERT was successful.

=cut

########################################################################
sub insert {
########################################################################
    my $self = shift;

    if ($self->{SQL}) {
        croak "This object is read-only\n";
    }

    my $dbh = $self->dbh();  ### database handle ###

    ### build the SQL ###
    my $sql = "INSERT INTO $self->{Table} (\n";
    $sql   .= join(",", $self->attributes_ia);
    $sql   .= ")\n";
    $sql   .= "VALUES (\n";
    my (@values, @binds) = ();
    foreach my $field ( $self->attributes_ia ) {
        push @values, '?';
        push @binds, $self->attribute($field)->sql_value;
    }
    $sql .= join(",\n", @values);
    $sql .= ")\n";

    warn "SQL = $sql BINDS(", join(',', @binds), ")\n"
        if $self->{DEBUG_SQL};

    ### execute the SQL ###
    my $result = undef;
#    eval {
        $result = $dbh->do($sql, undef, @binds);
        $self->_check_dbi_error("Can't execute SQL statement:\n".
                "$sql\n" .
                "BINDS(" . join(',', @binds));
#    };
#    if ($@) {
#        $dbh->rollback() unless $self->{AutoCommit};
#        croak $@;
#    } else {
        $dbh->commit() unless $self->{AutoCommit};
#    }
    return $result;
}


=head2 delete()

Delete the object.

=over 4

=item * @id

Optional. ID of the object to delete. If omitted then current object is
deleted.

=back

Returns True if DELETE was successful.

=cut

########################################################################
sub delete {
########################################################################
    my ($self) = @_;

    if (not $self->check_id()) {
        $self->clear;
        return undef;
    }

    my $dbh = $self->dbh();  ### database handle ###

    ### build the SQL ###
    my $sql = "DELETE FROM $self->{Table}\n";
    my (@values, @binds) = ();
    foreach my $field ( $self->attributes_i ) {
        push @values, "$field=?";
        push @binds, $self->attribute($field)->sql_value;
    }

    $sql .= " WHERE " . join(" AND ", @values) . "\n";

    warn "SQL = $sql BINDS(", join(',', @binds), ")\n"
        if $self->{DEBUG_SQL};

    ### execute the SQL ###
    my $result = undef;
#    eval {
        $result = $dbh->do($sql, undef, @binds);
        $self->_check_dbi_error("Can't execute SQL statement:\n".
                "$sql\n" .
                "BINDS(" . join(',', @binds));
#    };
#    if ($@) {
#        $dbh->rollback() unless $self->{AutoCommit};
#        croak $@;
#    } else {
        $dbh->commit() unless $self->{AutoCommit};
#    }

    return $result;
}



=head2 delete_where()

Conditionaly deletes objects.

Note: Obligatory WHERE clause will be added

=over 4

=item * where

WHERE clause

=item * binds

Array of values for binding.

=back

Returns True if DELETE was successful. May be return a number of deleted
rows?

=cut

############################################################################
sub delete_where    {   #07/04/00 1:04
############################################################################
    my($self, $where, @binds) = Params::Validate::validate_with(params => \@_,
        spec => [
            { type => OBJECT },                         # self
            { type => SCALAR },                         # where
        ], allow_extra => 1);

    if ($self->{SQL}) {
        croak "This object is read-only";
        # I don't know TABLE name. Extract it from SELECT
    }

    ### build the SQL ###
    my $sql = "DELETE FROM $self->{Table}\n";

    # Add obligatory where clause
    if ($self->{Where}) {
        $where .= ' AND ' if ($where);
        $where .= $self->{Where};
    }
    if (defined($where) && $where =~ /\S/) {
        $sql .= "WHERE $where\n";
    }

    #warn "SQL = $sql\n" if $sql =~ 'debug';

    ### execute the SQL ###
    my $dbh = $self->dbh();  ### database handle ###
    my $result = undef;
#    eval {
        $dbh->do($sql, undef, @binds);
        $self->_check_dbi_error("Can't execute SQL statement:\n".
                "$sql\n" .
                "BINDS(" . join(',', @binds));
#    };
#    if ($@) {
#        $dbh->rollback() unless $self->{AutoCommit};
#        croak $@;
#    } else {
        $dbh->commit() unless $self->{AutoCommit};
#    }

    return $result;
}##delete_where


=head2 restore_where()

Execute conditional SELECT statement.

=over 4

=item * where

C<WHERE> clause for SQL statement. It may be arrayref, than every array
element will be ANDed.

=item * skip_attributes

ARRAYREF. Do not SELECT these attributes.

ID attributes always included in SELECT.

Do not use both skip_attributes and only_attributes!

=item * only_attributes

ARRAYREF. Include in SELECT only these attributes.

ID attributes always included in SELECT.

Do not use both skip_attributes and only_attributes!

=item * count_rows

Just count(*) with supplied WHERE clause and return it.

=item * order_by

C<ORDER BY> clause.

=item * group_by

C<group_by> clause

=item * limit_rows

Limit a number of rows returned from server

=item * limit_offset

Limit starting row returned from server. Rows counted from 1.

=item * bind

ARRAYREF of bind values for SQL statement.

=item * other parameter

Any other parameter passed is treated as condition to C<WHERE> clause if an
attribute exists with this name. Undefined parameters are WHEREd to NULL
but empty values that eq to '' are omitted.

=back

=cut

my $restore_where_parameters = {
        bind         => { type => ARRAYREF, optional => 1},
        count_rows   => { type => BOOLEAN, optional => 1},
        group_by     => { type => UNDEF | SCALAR, optional => 1},
        limit_offset => { type => SCALAR, optional => 1},
        limit_rows   => { type => SCALAR, optional => 1},
        order_by     => { type => UNDEF | SCALAR, optional => 1},
        where        => { type => UNDEF | SCALAR | ARRAYREF, optional => 1},
        only_attributes => { type => ARRAYREF, optional => 1},
        skip_attributes => { type => ARRAYREF, optional => 1},
};
############################################################################
sub restore_where {
############################################################################
    my $self = shift;
    my %p = Params::Validate::validate_with(params => \@_,
        spec => $restore_where_parameters,
        allow_extra => 1);

    # Clear previous connection if exists
    $self->clear;
    if (ref ($self->{STH})) {
      $self->{STH}->finish;
      $self->{STH} = undef;
    }
    $self->{records_fetched} = 0;

    ### build SELECT clause SQL ###
    my $sql = undef;
    if (defined $self->{SQL}) {
        $sql = $self->{SQL};

    } elsif ( $p{count_rows} ) {
        $sql = "SELECT count(*) FROM $self->{Table}\n";

    } else {
        $sql = "SELECT \n";
        my @fields = $self->attributes_i;
        FIELD: foreach my $field ($self->attributes_a) {

            if (defined $p{only_attributes}) {
                foreach my $f ( @{$p{only_attributes}} ) {
                    if (lc($f) eq $field) {
                        push @fields, $field;
                        next FIELD;
                    }
                }
                push @fields, "NULL as $field"
            }

            if (defined $p{skip_attributes}) {
                foreach ( @{$p{skip_attributes}} ) {
                    if ($_ eq $field) {
                        push @fields, "NULL as $field";
                        next FIELD;
                    }
                }
            }

            push @fields, $field;
        }
        $sql .= join(",\n", @fields) . "\n";
        $sql .= "FROM $self->{Table} \n";
    }

    # manage obligatory BIND values
    $p{bind} = [] if ref($p{bind}) ne 'ARRAY';
    unshift @{ $p{bind} }, @{ $self->{Bind} } if ref($self->{Bind}) eq 'ARRAY';

    # where parameter may be arrayref. convert it into ANDed string
    # Use for it only non null strings
    if ( ref($p{where}) eq 'ARRAY') {
        $p{where} = join ' AND ', map { '('.$_.')' } grep {$_ ne ''} @{ $p{where} };
    }

    # Add obligatory where clause
    if ($self->{Where}) {
        if ($p{where}) {
            $p{where} = '(' . $self->{Where} . ') AND ' . $p{where};
        } else {
            $p{where} = '(' . $self->{Where} . ')';
        }
    }

    # Some parameters may be passed to restore_where. They are treated as
    # condition to restrict SQL clause
    KEY: foreach my $key (keys %p) {
        #next if ! $self->attribute($key);

        # Skip name parameters names used in %p hash
        foreach (keys %$restore_where_parameters) {
            next KEY if $key eq $_;
        }

        # Defined but empty values are ignored!!!
        next KEY if defined $p{$key} and $p{$key} eq '';

        # Add WHERE condition via bind values
        $p{where} .= ' AND ' if (defined $p{where});
        if (not defined $p{$key}) { # NULL values
            $p{where} .= "($key is NULL)";

        } elsif( $p{$key} =~ /(not\s+)?in[\s\(]/i) { # IN (...)
            $p{where} .= "($key $p{$key})";

        } else {    # easy a=b
            $p{where} .= "($key=?)";
            push @{ $p{bind} }, $p{$key};
        }
    }


    # Add WHERE to sql
    if ($p{where} ne '') {
        if ($self->{SQL}) {
            # Insert into ready SQL ...
            if (! ($sql =~ s/WHERE\s/WHERE $p{where} AND /i)) {
                $sql .= " WHERE $p{where}\n";
            }
        } else {
            $sql .= " WHERE $p{where}\n";
        }
    }

    # Add GROUP BY, ORDER BY, LIMIT
    if ( ! $p{count_rows}) {
        $p{group_by} = $self->{GroupBy} if ! $p{group_by};
        if (defined $p{group_by}) {
            $sql .= " GROUP BY $p{group_by}\n";
        }

        $p{order_by} = $self->{OrderBy} if ! $p{order_by};
        if (defined $p{order_by}) {
            $sql .= " ORDER BY $p{order_by}\n";
        }

        if (defined $p{limit_rows}) {
            $p{limit_offset} = 0 if ! $p{limit_offset};
            $sql .= " LIMIT $p{limit_offset},$p{limit_rows}";
        }
    }

    warn "SQL = $sql BINDS(", join(',', @{$p{bind}}), ")\n"
        if $self->{DEBUG_SQL};

    ### execute the SQL ###
    my $dbh = $self->dbh();  ### database handle ###
    $self->{STH} = $dbh->prepare($sql);
    $self->_check_dbi_error("Can't prepare SQL statement:\n$sql");

    if (! $self->{STH}->execute(@{$p{bind}})) {
        $self->_check_dbi_error("Can't execute SQL statement:\n".
                "$sql\n" .
                "BINDS(" . join(',', @{$p{bind}}));
        $self->{STH}->finish;
        $self->{STH} = undef;
        return undef;
    }


    # For count only queries fetch first row and return the result
    if ( $p{count_rows} ) {
        my $count = $self->{STH}->fetchrow_array();
        $self->{STH}->finish;
        $self->{STH} = undef;
        return $count;
    }

    # Add missing attributes for SQL queries
    if ($self->{SQL}) {
        my @field_names = @{$self->{STH}->{NAME_lc}};
        for my $i (0 .. $self->{STH}->{NUM_OF_FIELDS}-1) {
            if (! $self->attribute($field_names[$i])) {
                # ID or persistent
                my $type = 'Persistent';
                $type = 'ID' if $field_names[$i] eq 'id';
                $self->add_attribute($field_names[$i], { type => $type, dtype => 'VarChar' });
            }
        }
    }
    return 1;
}


=head2 add_where()

Helper function. Adds another WHERE condition possible ANDed with existing
one.

=over 4

=item * hashref

Parameters hashref. Constructed WHERE clause will be added to {where} key
of this hash.

=item * binds

Array of bind values. These values will be added to {bind} key of
parameters hash.

=back

Returns none.

=cut

############################################################################
sub add_where   {   #01/11/02 11:21
############################################################################
  my ($self, $p, $where, @binds) = @_;

  if ($where) {
    $p->{where} = [ $p->{where} ] if ref($p->{where}) ne 'ARRAY';
    push @{ $p->{where} }, $where;
    push @{$p->{bind}}, @binds;
  }
  return $p
}##add_where


=head2 where()

Get/Set obligatory WHERE clause for the object.

=over 4

=item * where

WHERE clause. Bindings are not supported.

=back

Returns ñurrent where clause

=cut

############################################################################
sub where   {   #07/04/00 12:51
############################################################################
    my $self = shift;

    $self->{Where} = shift if (@_);
    $self->{Where};
}##where



=head2 validate()

Validates internal data before insert of update. This method does nothing
and is subject to override in inherited modules.

=over 4

=item * beforeinsert

True if called from L<insert()|insert()>, False if called from
L<update()|update()>

=back

Returns undef on success or human readable error message if the object is
not valid.

=cut

############################################################################
sub validate    {   #07/06/00 1:57
############################################################################
    my $self = shift;
    my $beforeinsert = shift;
    undef;
}##validate




=head1 PRIVATE METHODS


=head2 _check_dbi_error()

Checks for errors in DBI and croaks if an error has occurred.

=over 4

=item * error string

Error string prepended to the DBI error message

=back

=cut

########################################################################
sub _check_dbi_error {
########################################################################
    my ($self, $err_str) = Params::Validate::validate_with(params => \@_,
        spec => [
            { type => OBJECT },
            { type => SCALAR }
        ]);

    if ($DBI::err) {
        croak("$err_str\n" .
            "DBI Error Code: $DBI::err\n" .
            "DBI Error Message: $DBI::errstr\n");
    }
}


=head2 dbh()

Returns the handle of the database.

=over 4

=item * new dbh

=back

=cut

########################################################################
sub dbh {
########################################################################
    my $self = shift;

    $self->{DBH} = shift if (@_);
    return $self->{DBH};
}


=head2 _id()

Gets/Sets the ID of the object. ID may be an array.

=cut

########################################################################
sub _id {
########################################################################
    my($self, @id) = @_;

    if (@id) {  ### set the ID ###
        my @new_id = @id;
        foreach my $idfield ( $self->attributes_i ) {
            # avoid inheritance
            value($self, $idfield, shift @new_id);
        }
    } else {    ### get the ID ###
        foreach my $idfield ($self->attributes_i) {
            push(@id, $self->value($idfield));
        }
    }

    return @id;
}



=head2 check_id()

Checks that the ID of the object is valid. That is every ID attribute is
defined.

=cut

############################################################################
sub check_id    {   #09/25/02 9:54
############################################################################
    my ($self, @id) = @_;

    @id = $self->_id() if !@id;
    foreach ($self->attributes_i) {
        my $i = shift @id;
        return 0 if !defined($i);
    }
    1;
}##check_id


1;

__END__


=head1 SUPPORTED DATA TYPES

=head2 VarChar

=head2 Number

=head2 DateTime

=head2 Date

=head2 YesNo




=head1 INTERNAL VARIABLES

=head2 Storage related variables

=over 4

=item * $self->{Table}

Name of database table.


=item * $self->{DBH}

DBI database handle.

=item * $self->{STH}

Initialized internally. Database statement handle. Used for active SELECT
statements.

=item * $self->{dbi_xxx}

{dbi_source}, {dbi_username}, {dbi_password} - three parameters to create new
DBH. This is opposite to {DBH} parameter.

=item * $self->{CreatedDBH}

Initialized internally. True if DBH is created by myself and we need to do
disconnect(). This happens when dbi_xxx parameters are passed to
constructor.

If ready to use DBH is passed to constructor then {CreatedDBH} is False.


=item * $self->{AutoCommit}

True if commit() is needed after every update statement.


=item * $self->{SQL}

This is opposite to {Table}. When {SQL} is passed to constructor it is used
for SELECT statement and object become read-only.


=item * $self->{Where}

Obliagtory WHERE clause added to every SQL statement

=item * $self->{Bind}

Obligatory arrayref of bind values to add to every SQL request

=item * $self->{OrderBy}

ORDER BY clause by default if not passed other to restore_where()

=item * $self->{GroupBy}

GROUP BY clause added to every SELECT statement with restore_where()

=back



=head2 Attributes

=over 4

=item * $self->{MetaData}{attr}

Attribute object. Every attribute object is persent here. Attributes names
are in lower case.

=item * $self->{IdAttributes}->[]

Array of names of ID attributes.

=item * $self->{Attributes}->[]

Array of names of Persistent attributes.

=item * $self->{TempAttributes}->[]

Array of names of Temporary attributes. Temporary attributes are not stored
in database.

=back




=head2 Other variables

=over 4

=item * $self->{Where}

Obligatory WHERE clause. These conditions are added to WHERE clause for
every restore_xxx().


=item * $self->{CountRows}

When {CountRows} is True then all SELECT fields are replaced to count(*)
field and consctucted WHERE clause is added. This feature is used in
L<restore_where()|restore_where()>

=back



=head1 ATTRIBUTE PARAMETERS

A lot of attribute parameters are used for description, detalization and
visualization.

=over 4

=item * type

[ ID | Persistent | Transient(Temporary) ]

This is field persistent state. Only first 1 character is significant.
Default is I<Persistent>.

=item * dtype

Data type. Must correlate with any of L<supported datatypes|SUPPORTED DATA
TYPES>. Default is I<Varchar>.

=item * label

This label is used to make labels is dialogs.

=item * header

This is used for header of column in a table.

=item * maxlength

Maximum length of the field. Default is I<9> for Number, I<255> for Varchar.

=item * scale

Scale of a number. Number of digits after point.

=item * fieldtype

[textfield | popup_menu | textarea | YesNo | date | datetime]

Type of dialog item used for this field. Default is I<textfield>.

=item * size

Size of field in dialog boxes in characters.

=item * labels,values

Used for popup_menu field type. B<values> may be a coderef declared as sub
{}. The object ($self) passed to this sub as first parameter.

=item * auto_increment

This Number attribute is auto incremented by database during INSERT
operation.

=item * popup_menu

sub{ my $self=shift; ... return (\@val,\%lab);}

Coderef used to fill up popup_menu parameters.

=item * columns,rows

Used for textarea field type

=item * description

Not used

=back

=cut

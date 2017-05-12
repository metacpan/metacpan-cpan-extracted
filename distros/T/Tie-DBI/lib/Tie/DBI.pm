package Tie::DBI;

use strict;
use vars qw($VERSION);
use Carp;
use DBI;
$VERSION = '1.06';

BEGIN {
    eval {
        require Encode::compat if $] < 5.007001;
        require Encode;
    };
}

# Default options for the module
my %DefaultOptions = (
    'user'         => '',
    'password'     => '',
    'AUTOCOMMIT'   => 1,
    'WARN'         => 0,
    'DEBUG'        => 0,
    'CLOBBER'      => 0,
    'CASESENSITIV' => 0,
);

# DBD drivers that work correctly with bound variables
my %CAN_BIND = (
    'ODBC'     => 1,
    'AnyData'  => 1,
    'mysql'    => 1,
    'mSQL'     => 1,
    'Oracle'   => 1,
    'CSV'      => 1,
    'DBM'      => 1,
    'Sys'      => 1,
    'Pg'       => 1,
    'PO'       => 1,
    'Informix' => 1,
    'Solid'    => 1,
);
my %CANNOT_LISTFIELDS = (
    'SQLite'  => 1,
    'Oracle'  => 1,
    'CSV'     => 1,
    'DBM'     => 1,
    'PO'      => 1,
    'AnyData' => 1,
    'mysqlPP' => 1,
);
my %CAN_BINDSELECT = (
    'mysql'    => 1,
    'mSQL'     => 1,
    'CSV'      => 1,
    'Pg'       => 1,
    'Sys'      => 1,
    'DBM'      => 1,
    'AnyData'  => 1,
    'PO'       => 1,
    'Informix' => 1,
    'Solid'    => 1,
    'ODBC'     => 1,
);
my %BROKEN_INSERT = (
    'mSQL' => 1,
    'CSV'  => 1,
);
my %NO_QUOTE = (
    'Sybase' => { map { $_ => 1 } ( 2, 6 .. 17, 20, 24 ) },
);
my %DOES_IN = (
    'mysql'   => 1,
    'Oracle'  => 1,
    'Sybase'  => 1,
    'CSV'     => 1,
    'DBM'     => 1,    # at least with SQL::Statement
    'AnyData' => 1,
    'Sys'     => 1,
    'PO'      => 1,
);

# TIEHASH interface
# tie %h,Tie::DBI,[dsn|dbh,table,key],\%options
sub TIEHASH {
    my $class = shift;
    my ( $dsn, $table, $key, $opt );
    if ( ref( $_[0] ) eq 'HASH' ) {
        $opt = shift;
        ( $dsn, $table, $key ) = @{$opt}{ 'db', 'table', 'key' };
    }
    else {
        ( $dsn, $table, $key, $opt ) = @_;
    }

    croak "Usage tie(%h,Tie::DBI,dsn,table,key,\\%options)\n   or tie(%h,Tie::DBI,{db=>\$db,table=>\$table,key=>\$key})"
      unless $dsn && $table && $key;
    my $self = {
        %DefaultOptions,
        defined($opt) ? %$opt : ()
    };
    bless $self, $class;
    my ( $dbh, $driver );

    if ( UNIVERSAL::isa( $dsn, 'DBI::db' ) ) {
        $dbh         = $dsn;
        $driver      = $dsn->{Driver}{Name};
        $dbh->{Warn} = $self->{WARN};
    }
    else {
        $dsn = "dbi:$dsn" unless $dsn =~ /^dbi/;
        ($driver) = $dsn =~ /\w+:(\w+)/;

        # Try to establish connection with data source.
        delete $ENV{NLS_LANG};    # this gives us 8 bit characters ??

        $dbh = $class->connect(
            $dsn,
            $self->{user},
            $self->{password},
            {
                AutoCommit => $self->{AUTOCOMMIT},

                #ChopBlanks=>1, # Removed per RT 19833 This may break legacy code.
                PrintError => 0,
                Warn       => $self->{WARN},
            }
        );
        $self->{needs_disconnect}++;
        croak "TIEHASH: Can't open $dsn, ", $class->errstr unless $dbh;
    }

    if ( $driver eq 'Oracle' ) {

        #set date format
        my $sth = $dbh->prepare("ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS'");
        $sth->execute();
    }

    # set up more instance variables
    @{$self}{ 'dbh', 'table', 'key', 'driver' } = ( $dbh, $table, $key, $driver );
    $self->{BrokenInsert}     = $BROKEN_INSERT{$driver};
    $self->{CanBind}          = $CAN_BIND{$driver};
    $self->{CanBindSelect}    = $self->{CanBind} && $CAN_BINDSELECT{$driver};
    $self->{NoQuote}          = $NO_QUOTE{$driver};
    $self->{DoesIN}           = $DOES_IN{$driver};
    $self->{CannotListfields} = $CANNOT_LISTFIELDS{$driver};

    return $self;
}

sub DESTROY {
    $_[0]->{'dbh'}->disconnect
      if defined $_[0]->{'dbh'}
      && $_[0]->{needs_disconnect};
}

sub FETCH {
    my ( $s, $key ) = @_;

    # user could refer to $h{a,b,c}: handle this case
    my (@keys) = split( $;, $key );
    my ( $tag, $query );
    if ( @keys > 1 ) {    # need an IN clause
        my ($count) = scalar(@keys);
        $tag = "fetch$count";
        if ( !$s->{CanBindSelect} ) {
            foreach (@keys) { $_ = $s->_quote( $s->{key}, $_ ); }
        }
        if ( $s->{DoesIN} ) {
            $query = "SELECT $s->{key} FROM $s->{table} WHERE $s->{key} IN (" . join( ",", ('?') x $count ) . ')';
        }
        else {
            $query = "SELECT $s->{key} FROM $s->{table} WHERE " . join( ' OR ', ("$s->{key}=?") x $count );
        }
    }
    else {
        $tag   = "fetch1";
        @keys  = $s->_quote( $s->{key}, $key ) unless $s->{CanBindSelect};
        $query = "SELECT $s->{key} FROM $s->{table} WHERE $s->{key} = ?";
    }
    my $st = $s->_run_query( $tag, $query, @keys ) || croak "FETCH: ", $s->errstr;

    # slightly more efficient for one key
    if ( @keys == 1 ) {
        my $r = $st->fetch;
        $st->finish;
        return undef unless $r;
        my $h = {};
        tie %$h, 'Tie::DBI::Record', $s, $r->[0];
        return $h;
    }

    # general case -- multiple keys
    my ( $r, %got );
    while ( $r = $st->fetch ) {
        my $h = {};
        tie %$h, 'Tie::DBI::Record', $s, $r->[0];
        $got{ $r->[0] } = $h;
    }
    $st->finish;
    @keys = split( $;, $key );
    return ( @keys > 1 ) ? [ @got{@keys} ] : $got{ $keys[0] };
}

sub FIRSTKEY {
    my $s = shift;
    my $st = $s->_prepare( 'fetchkeys', "SELECT $s->{key} FROM $s->{table}" )
      || croak "FIRSTKEY: ", $s->errstr;
    $st->execute()
      || croak "FIRSTKEY: ", $s->errstr;
    my $ref = $st->fetch;
    unless ( defined($ref) ) {
        $st->finish;
        delete $s->{'fetchkeys'};    #freakin' sybase bug
        return undef;
    }
    return $ref->[0];
}

sub NEXTKEY {
    my $s = shift;
    my $st = $s->_prepare( 'fetchkeys', '' );

    # no statement handler defined, so nothing to iterate over
    return wantarray ? () : undef unless $st;
    my $r = $st->fetch;
    if ( !$r ) {
        $st->finish;
        delete $s->{'fetchkeys'};    #freakin' sybase bug
        return wantarray ? () : undef;
    }

    # Should we do a tie here?
    my ( $key, $value ) = ( $r->[0], {} );
    return wantarray ? ( $key, $value ) : $key;
}

# Unlike fetch, this never goes to the cache
sub EXISTS {
    my ( $s, $key ) = @_;
    $key = $s->_quote( $s->{key}, $key ) unless $s->{CanBindSelect};
    my $st = $s->_run_query( 'fetch1', "SELECT $s->{key} FROM $s->{table} WHERE $s->{key} = ?", $key );
    croak $DBI::errstr unless $st;
    $st->fetch;
    my $rows = $st->rows;
    $st->finish;
    $rows != 0;
}

sub CLEAR {
    my $s = shift;
    croak "CLEAR: read-only database"
      unless $s->{CLOBBER} > 2;

    my $st = $s->_prepare( 'clear', "delete from $s->{table}" );
    $st->execute()
      || croak "CLEAR: delete statement failed, ", $s->errstr;
    $st->finish;
}

sub DELETE {
    my ( $s, $key ) = @_;
    croak "DELETE: read-only database"
      unless $s->{CLOBBER} > 1;
    $key = $s->_quote( $s->{key}, $key ) unless $s->{CanBindSelect};
    my $st = $s->_run_query( 'delete', "delete from $s->{table} where $s->{key} = ?", $key )
      || croak "DELETE: delete statement failed, ", $s->errstr;
    $st->finish;

}

sub STORE {
    my ( $s, $key, $value ) = @_;

    # There are two cases where this can be called.  In the first case, we are
    # passed a hash reference to field names and their values.  In the second
    # case, we are passed a Tie::DBI::Record, for the purposes of a cloning
    # operation.
    croak "STORE: attempt to store non-hash value into record"
      unless ref($value) eq 'HASH';

    croak "STORE: read-only database"
      unless $s->{CLOBBER} > 0;

    my (@fields);
    my $ok = $s->_fields();
    foreach ( sort keys %$value ) {
        if ( $_ eq $s->{key} ) {
            carp qq/Ignored attempt to change value of key field "$s->{key}"/ if $s->{WARN};
            next;
        }
        if ( !$ok->{$_} ) {
            carp qq/Ignored attempt to set unknown field "$_"/ if $s->{WARN};
            next;
        }
        push( @fields, $_ );
    }
    return undef unless @fields;
    my (@values) = map { $value->{$_} } @fields;

    # Attempt an insert.  If that fails (usually because the key already exists),
    # perform an update. For this to work correctly, the key field MUST be marked unique
    my $result;
    if ( $s->{BrokenInsert} ) {    # check for broken drivers
        $result =
            $s->EXISTS($key)
          ? $s->_update( $key, \@fields, \@values )
          : $s->_insert( $key, \@fields, \@values );
    }
    else {
        eval {
            local ( $s->{'dbh'}->{PrintError} ) = 0;    # suppress warnings
            $result = $s->_insert( $key, \@fields, \@values );
        };
        $result or $result = $s->_update( $key, \@fields, \@values );
    }
    croak "STORE: ", $s->errstr if $s->error;

    # Neat special case: If we are passed an empty anonymous hash, then
    # we must tie it to Tie::DBI::Record so that the correct field updating
    # behavior springs into existence.
    tie %$value, 'Tie::DBI::Record', $s, $key
      unless %$value;
}

sub fields {
    my $s = shift;
    return keys %{ $s->_fields() };
}

sub dbh {
    $_[0]->{'dbh'};
}

sub commit {
    $_[0]->{'dbh'}->commit();
}

sub rollback {
    $_[0]->{'dbh'}->rollback();
}

# The connect() method is responsible for the low-level connect to
# the database.  It should return a database handle or return undef.
# You may want to override this to connect via a subclass of DBI, such
# as Apache::DBI.
sub connect {
    my ( $class, $dsn, $user, $password, $options ) = @_;
    return DBI->connect( $dsn, $user, $password, $options );
}

# Return a low-level error.  You might want to override this
# if you use a subclass of DBI
sub errstr {
    return $DBI::errstr;
}

sub error {
    return $DBI::err;
}

sub select_where {
    my ( $s, $query ) = @_;

    # get rid of everything but the where clause
    $query =~ s/^\s*(select .+)?where\s+//i;
    my $st = $s->{'dbh'}->prepare("select $s->{key} from $s->{table} where $query")
      || croak "select_where: ", $s->errstr;
    $st->execute()
      || croak "select_where: ", $s->errstr;
    my ( $key, @results );
    $st->bind_columns( undef, \$key );
    while ( $st->fetch ) {
        push( @results, $key );
    }
    $st->finish;
    return @results;
}

# ---------------- everything below this line is private --------------------------
sub _run_query {
    my $self = shift;
    my ( $tag, $query, @bind_variables ) = @_;
    if ( $self->{CanBind} ) {
        unless ( !$self->{CanBindSelect} && $query =~ /\bwhere\b/i ) {
            my $sth = $self->_prepare( $tag, $query );
            return unless $sth->execute(@bind_variables);
            return $sth;
        }
    }
    local ($^W) = 0;    # kill uninitialized variable warning
                        # if we get here, then we can't bind, so we replace ? with escaped parameters
    while ( ( my $pos = index( $query, '?' ) ) >= 0 ) {
        my $value = shift(@bind_variables);
        substr( $query, $pos, 1 ) = ( defined($value) ? ( $self->{CanBind} ? $self->{'dbh'}->quote($value) : $value ) : 'null' );
    }
    my $sth = $self->{'dbh'}->prepare($query);
    return unless $sth && $sth->execute;
    return $sth;
}

sub _fields {
    my $self = shift;
    unless ( $self->{'fields'} ) {

        my ( $dbh, $table ) = @{$self}{ 'dbh', 'table' };

        local ($^W) = 0;    # kill uninitialized variable warning
        my $sth = $dbh->prepare("LISTFIELDS $table") unless ( $self->{CannotListfields} );

        # doesn't support LISTFIELDS, so try SELECT *
        unless ( !$self->{CannotListfields} && defined($sth) && $sth->execute ) {
            $sth = $dbh->prepare("SELECT * FROM $table WHERE 0=1")
              || croak "_fields() failed during prepare(SELECT) statement: ", $self->errstr;
            $sth->execute()
              || croak "_fields() failed during execute(SELECT) statement: ", $self->errstr;
        }

        # if we get here, we can fetch the names of the fields
        my %fields;
        if ( $self->{'CASESENSITIV'} ) {
            %fields = map { $_ => 1 } @{ $sth->{NAME} };
        }
        else {
            %fields = map { lc($_) => 1 } @{ $sth->{NAME} };
        }

        $sth->finish;
        $self->{'fields'} = \%fields;
    }
    return $self->{'fields'};
}

sub _types {
    my $self = shift;
    return $self->{'types'} if $self->{'types'};
    my ( $sth, %types );

    if ( $self->{'driver'} eq 'Oracle' ) {
        $sth = $self->{'dbh'}->prepare( "SELECT column_name,data_type FROM ALL_TAB_COLUMNS WHERE TABLE_NAME = " . $self->{'dbh'}->quote("$self->{table}") );
        $sth->execute()
          || croak "_types() failed during execute(SELECT) statement: $DBI::errstr";

        while ( my ( $col_name, $col_type ) = $sth->fetchrow() ) {
            $types{$col_name} = $col_type;
        }
    }

    else {
        $sth = $self->{'dbh'}->prepare("SELECT * FROM $self->{table} WHERE 0=1")
          || croak "_types() failed during prepare(SELECT) statement: $DBI::errstr";
        $sth->execute()
          || croak "_types() failed during execute(SELECT) statement: $DBI::errstr";
        my $types = $sth->{TYPE};
        my $names = $sth->{NAME};
        %types = map { shift(@$names) => $_ } @$types;
    }
    return $self->{'types'} = \%types;
}

sub _fetch_field ($$) {
    my ( $s, $key, $fields ) = @_;
    $key = $s->_quote( $s->{key}, $key ) unless $s->{CanBindSelect};
    my $valid = $s->_fields();
    my @valid_fields = grep( $valid->{$_}, @$fields );
    return undef unless @valid_fields;

    my $f = join( ',', @valid_fields );
    my $st = $s->_run_query( "fetch$f", "SELECT $f FROM $s->{table} WHERE $s->{key}=?", $key )
      || croak "_fetch_field: ", $s->errstr;

    my ( @r, @results );
    while ( @r = $st->fetchrow_array ) {
        my @i = map { $valid->{$_} ? shift @r : undef } @$fields;
        if ( $s->{ENCODING} ) {
            @i = map { _decode( $s->{ENCODING}, $_ ) } @i;
        }
        push( @results, ( @$fields == 1 ) ? $i[0] : [@i] );
    }

    $st->finish;
    return ( @results > 1 ) ? \@results : $results[0];
}

sub _insert {
    my ( $s, $key, $fields, $values ) = @_;
    push( @$fields, $s->{key} );
    push( @$values, $key );
    my @values = $s->_quote_many( $fields, $values );
    my (@Qs) = ('?') x @$values;
    local ($") = ',';
    my $st = $s->_run_query( "insert@$fields", "insert into $s->{table} (@$fields) values (@Qs)", @values );
    pop(@$fields);
    pop(@$values);
    return $st ? $st->rows : 0;
}

sub _update {
    my ( $s, $key, $fields, $values ) = @_;
    my (@set) = map { "$_=?" } @$fields;
    my @values = $s->_quote_many( $fields, $values );
    $key = $s->_quote( $s->{key}, $key ) unless $s->{CanBindSelect};
    local ($") = ',';
    my $st = $s->_run_query(
        "update@$fields",
        "update $s->{table} set @set where $s->{key}=?", @values, $key
    );
    return unless $st;
    return $st->rows;
}

sub _quote_many {
    my ( $s, $fields, $values ) = @_;

    if ( $s->{CanBind} ) {
        if ( $s->{ENCODING} ) {
            return map { _encode( $s->{ENCODING}, $_ ) } @$values;
        }
        else {
            return @$values;
        }
    }

    my $noquote = $s->{NoQuote};
    unless ($noquote) {
        if ( $s->{ENCODING} ) {
            return map { $s->{'dbh'}->quote( _encode( $s->{ENCODING}, $_ ) ) } @$values;
        }
        else {
            return map { $s->{'dbh'}->quote($_) } @$values;
        }
    }
    my @values = @$values;
    my $types  = $s->_types;
    for ( my $i = 0; $i < @values; $i++ ) {
        next if $noquote->{ $types->{ $fields->[$i] } };
        if ( $s->{'driver'} eq 'Oracle' && $types->{ $fields->[$i] } eq 'DATE' ) {
            my $epoch_date = str2time( $values[$i] );
            my $temp       = time2iso($epoch_date);
            $temp = $s->{'dbh'}->quote($temp);
            $values[$i] = $temp;
        }
        else {
            $values[$i] = $s->{'dbh'}->quote( $values[$i] );
        }
    }
    return @values;
}

sub _quote {
    my ( $s, $field, $value ) = @_;
    my $types = $s->_types;
    if ( my $noquote = $s->{NoQuote} ) {
        return $noquote->{ $types->{$field} } ? $value : $s->{'dbh'}->quote($value);
    }

    if ( $s->{'driver'} eq 'Oracle' && $types->{$field} eq 'DATE' ) {
        my $epoch_date = str2time($value);
        my $temp       = time2iso($epoch_date);
        $temp = $s->{'dbh'}->quote($temp);

        #my $temp = $s->{'dbh'}->quote($value);
        $temp = "to_date($temp,'YYYY-MM-DD HH24:MI:SS')";
        return $temp;
    }
    else {
        $value = _encode( $s->{ENCODING}, $value ) if $s->{ENCODING};
        $value = $s->{'dbh'}->quote($value);
        return $value;
    }
}

sub _prepare ($$$) {
    my ( $self, $tag, $q ) = @_;
    unless ( exists( $self->{$tag} ) ) {
        return undef unless $q;
        warn $q, "\n" if $self->{DEBUG};
        my $sth = $self->{'dbh'}->prepare($q);
        $self->{$tag} = $sth;
    }
    else {
        $self->{$tag}->finish if $q;    # in case we forget
    }
    $self->{$tag};
}

sub _encode {
    eval { return Encode::encode( $_[0], $_[1] ); };
}

sub _decode {
    eval { return Encode::decode( $_[0], $_[1] ); };
}

package Tie::DBI::Record;
use strict;
use vars qw($VERSION);
use Carp;
use DBI;
$VERSION = '0.50';

# TIEHASH interface
# tie %h,Tie::DBI::Record,dbh,table,record
sub TIEHASH {
    my $class = shift;
    my ( $table, $record ) = @_;
    return bless {
        'table'  => $table,     # table object
        'record' => $record,    # the record we're keyed to
    }, $class;
}

sub FETCH {
    my ( $s, $field ) = @_;
    return undef unless $s->{'table'};
    my (@fields) = split( $;, $field );
    return $s->{'table'}->_fetch_field( $s->{'record'}, \@fields );
}

sub DELETE {
    my ( $s, $field ) = @_;
    $s->STORE( $field, undef );
}

sub STORE {
    my ( $s, $field, $value ) = @_;
    $s->{'table'}->STORE( $s->{'record'}, { $field => $value } );
}

# Can't delete the record in this way, but we can
# clear out all the fields by setting them to undef.
sub CLEAR {
    my ($s) = @_;
    croak "CLEAR: read-only database"
      unless $s->{'table'}->{CLOBBER} > 1;
    my %h = map { $_ => undef } keys %{ $s->{'table'}->_fields() };
    delete $h{ $s->{'record'} };    # can't remove key field
    $s->{'table'}->STORE( $s->{'record'}, \%h );
}

sub FIRSTKEY {
    my $s = shift;
    my $a = scalar keys %{ $s->{'table'}->_fields() };
    each %{ $s->{'table'}->_fields() };
}

sub NEXTKEY {
    my $s = shift;
    each %{ $s->{'table'}->_fields() };
}

sub EXISTS {
    my $s = shift;
    return $s->{'table'}->_fields()->{ $_[0] };
}

sub DESTROY {
    my $s = shift;
    warn "$s->{table}:$s->{value} has been destroyed" if $s->{'table'}->{DEBUG};
}

=head1 NAME

Tie::DBI - Tie hashes to DBI relational databases

=head1 SYNOPSIS

  use Tie::DBI;
  tie %h,'Tie::DBI','mysql:test','test','id',{CLOBBER=>1};

  tie %h,'Tie::DBI',{db       => 'mysql:test',
		   table    => 'test',
                   key      => 'id',
                   user     => 'nobody',
                   password => 'ghost',
                   CLOBBER  => 1};

  # fetching keys and values
  @keys = keys %h;
  @fields = keys %{$h{$keys[0]}};
  print $h{'id1'}->{'field1'};
  while (($key,$value) = each %h) {
    print "Key = $key:\n";
    foreach (sort keys %$value) {
	print "\t$_ => $value->{$_}\n";
    }
  }

  # changing data
  $h{'id1'}->{'field1'} = 'new value';
  $h{'id1'} = { field1 => 'newer value',
                field2 => 'even newer value',
                field3 => "so new it's squeaky clean" };

  # other functions
  tied(%h)->commit;
  tied(%h)->rollback;
  tied(%h)->select_where('price > 1.20');
  @fieldnames = tied(%h)->fields;
  $dbh = tied(%h)->dbh;

=head1 DESCRIPTION

This module allows you to tie Perl associative arrays (hashes) to SQL
databases using the DBI interface.  The tied hash is associated with a
table in a local or networked database.  One column becomes the hash
key.  Each row of the table becomes an associative array, from which
individual fields can be set or retrieved.

=head1 USING THE MODULE

To use this module, you must have the DBI interface and at least one
DBD (database driver) installed.  Make sure that your database is up
and running, and that you can connect to it and execute queries using
DBI.

=head2 Creating the tie

   tie %var,'Tie::DBI',[database,table,keycolumn] [,\%options]

Tie a variable to a database by providing the variable name, the tie
interface (always "Tie::DBI"), the data source name, the table to tie
to, and the column to use as the hash key.  You may also pass various
flags to the interface in an associative array.

=over 4

=item database

The database may either be a valid DBI-style data source string of the
form "dbi:driver:database_name[:other information]", or a database
handle that has previously been opened.  See the documentation for DBI
and your DBD driver for details.  Because the initial "dbi" is always
present in the data source, Tie::DBI will add it for you if necessary.

Note that some drivers (Oracle in particular) have an irritating habit
of appending blanks to the end of fixed-length fields.  This will
screw up Tie::DBI's routines for getting key names.  To avoid this you
should create the database handle with a B<ChopBlanks> option of TRUE.
You should also use a B<PrintError> option of true to avoid complaints
during STORE and LISTFIELD calls.  


=item table

The table in the database to bind to.  The table must previously have
been created with a SQL CREATE statement.  This module will not create
tables for you or modify the schema of the database.

=item key

The column to use as the hash key.  This column must prevoiusly have
been defined when the table was created.  In order for this module to
work correctly, the key column I<must> be declared unique and not
nullable.  For best performance, the column should be also be declared
a key.  These three requirements are automatically satisfied for
primary keys.

=back

It is possible to omit the database, table and keycolumn arguments, in
which case the module tries to retrieve the values from the options
array.  The options array contains a set of option/value pairs.  If
not provided, defaults are assumed.  The options are:

=over 4

=item user

Account name to use for database authentication, if necessary.
Default is an empty string (no authentication necessary).

=item password

Password to use for database authentication, if necessary.  Default is
an empty string (no authentication necessary).

=item db

The database to bind to the hash, if not provided in the argument
list.  It may be a DBI-style data source string, or a
previously-opened database handle.

=item table

The name of the table to bind to the hash, if not provided in the
argument list.

=item key

The name of the column to use as the hash key, if not provided in the
argument list.

=item CLOBBER (default 0)

This controls whether the database is writable via the bound hash.  A
zero value (the default) makes the database essentially read only.  An
attempt to store to the hash will result in a fatal error.  A CLOBBER
value of 1 will allow you to change individual fields in the database,
and to insert new records, but not to delete entire records.  A
CLOBBER value of 2 allows you to delete records, but not to erase the
entire table.  A CLOBBER value of 3 or higher will allow you to erase
the entire table.

    Operation                       Clobber      Comment

    $i = $h{strawberries}->{price}     0       All read operations
    $h{strawberries}->{price} += 5     1       Update fields
    $h{bananas}={price=>23,quant=>3}   1       Add records
    delete $h{strawberries}            2       Delete records
    %h = ()                            3       Clear entire table
    undef %h                           3       Another clear operation

All database operations are contingent upon your access privileges.
If your account does not have write permission to the database, hash
store operations will fail despite the setting of CLOBBER.

=item AUTOCOMMIT (default 1)

If set to a true value, the "autocommit" option causes the database
driver to commit after every store statement.  If set to a false
value, this option will not commit to the database until you
explicitly call the Tie::DBI commit() method.

The autocommit option defaults to true.

=item DEBUG (default 0)

When the DEBUG option is set to a non-zero value the module will echo
the contents of SQL statements and other debugging information to
standard error.  Higher values of DEBUG result in more verbose (and
annoying) output.

=item WARN (default 1)

If set to a non-zero value, warns of illegal operations, such as
attempting to delete the value of the key column.  If set to a zero
value, these errors will be ignored silently.

=item CASESENSITIV (default 0)

If set to a non-zero value, all Fieldnames are casesensitiv. Keep
in mind, that your database has to support casesensitiv Fields if
you want to use it.

=back

=head1 USING THE TIED ARRAY

The tied array represents the database table.  Each entry in the hash
is a record, keyed on the column chosen in the tie() statement.
Ordinarily this will be the table's primary key, although any unique
column will do.

Fetching an individual record returns a reference to a hash of field
names and values.  This hash reference is itself a tied object, so
that operations on it directly affect the database.

=head2 Fetching information

In the following examples, we will assume a database table structured
like this one:

                    -produce-
    produce_id    price   quantity   description

    strawberries  1.20    8          Fresh Maine strawberries
    apricots      0.85    2          Ripe Norwegian apricots
    bananas       1.30    28         Sweet Alaskan bananas
    kiwis         1.50    9          Juicy New York kiwi fruits
    eggs          1.00   12          Farm-fresh Atlantic eggs

We tie the variable %produce to the table in this way:

    tie %produce,'Tie::DBI',{db    => 'mysql:stock',
                           table => 'produce',
                           key   => 'produce_id',
                           CLOBBER => 2 # allow most updates
                           };

We can get the list of keys this way:

    print join(",",keys %produce);
       => strawberries,apricots,bananas,kiwis

Or get the price of eggs thusly:

    $price = $produce{eggs}->{price};
    print "The price of eggs = $price";
        => The price of eggs = 1.2

String interpolation works as you would expect:

    print "The price of eggs is still $produce{eggs}->{price}"
        => The price of eggs is still 1.2

Various types of syntactic sugar are allowed.  For example, you can
refer to $produce{eggs}{price} rather than $produce{eggs}->{price}.
Array slices are fully supported as well:

    ($apricots,$kiwis) = @produce{apricots,kiwis};
    print "Kiwis are $kiwis->{description};
        => Kiwis are Juicy New York kiwi fruits

    ($price,$description) = @{$produce{eggs}}{price,description};
        => (2.4,'Farm-fresh Atlantic eggs')

If you provide the tied hash with a comma-delimited set of record
names, and you are B<not> requesting an array slice, then the module
does something interesting.  It generates a single SQL statement that
fetches the records from the database in a single pass (rather than
the multiple passes required for an array slice) and returns the
result as a reference to an array.  For many records, this can be much
faster.  For example:

     $result = $produce{apricots,bananas};
         => ARRAY(0x828a8ac)

     ($apricots,$bananas) = @$result;
     print "The price of apricots is $apricots->{price}";
         => The price of apricots is 0.85

Field names work in much the same way:

     ($price,$quantity) = @{$produce{apricots}{price,quantity}};
     print "There are $quantity apricots at $price each";
         => There are 2 apricots at 0.85 each";

Note that this takes advantage of a bit of Perl syntactic sugar which
automagically treats $h{'a','b','c'} as if the keys were packed
together with the $; pack character.  Be careful not to fall into this
trap:


     $result = $h{join( ',', 'apricots', 'bananas' )};
         => undefined

What you really want is this:

     $result = $h{join( $;, 'apricots', 'bananas' )};
         => ARRAY(0x828a8ac)

=head2 Updating information

If CLOBBER is set to a non-zero value (and the underlying database
privileges allow it), you can update the database with new values.
You can operate on entire records at once or on individual fields
within a record.

To insert a new record or update an existing one, assign a hash
reference to the record.  For example, you can create a new record in
%produce with the key "avocados" in this manner:

   $produce{avocados} = { price       => 2.00,
                          quantity    => 8,
                          description => 'Choice Irish avocados' };

This will work with any type of hash reference, including records
extracted from another table or database.

Only keys that correspond to valid fields in the table will be
accepted.  You will be warned if you attempt to set a field that
doesn't exist, but the other fields will be correctly set.  Likewise,
you will be warned if you attempt to set the key field.  These
warnings can be turned off by setting the WARN option to a zero value.
It is not currently possible to add new columns to the table.  You
must do this manually with the appropriate SQL commands.

The same syntax can be used to update an existing record.  The fields
given in the hash reference replace those in the record.  Fields that
aren't explicitly listed in the hash retain their previous values.  In
the following example, the price and quantity of the "kiwis" record
are updated, but the description remains the same:

    $produce{kiwis} = { price=>1.25,quantity=>20 };

You may update existing records on a field-by-field manner in the
natural way:

    $produce{eggs}{price} = 1.30;
    $produce{eggs}{price} *= 2;
    print "The price of eggs is now $produce{eggs}{price}";
        => The price of eggs is now 2.6.

Obligingly enough, you can use this syntax to insert new records too,
as in $produce{mangoes}{description}="Sun-ripened Idaho mangoes".
However, this type of update is inefficient because a separate SQL
statement is generated for each field.  If you need to update more
than one field at a time, use the record-oriented syntax shown
earlier.  It's much more efficient because it gets the work done with
a single SQL command.

Insertions and updates may fail for any of a number of reasons, most
commonly:

=over 4

=item 1. You do not have sufficient privileges to update the database

=item 2. The update would violate an integrity constraint, such as
making a non-nullable field null, overflowing a numeric field, storing
a string value in a numeric field, or violating a uniqueness
constraint.

=back

The module dies with an error message when it encounters an error
during an update.  To trap these erorrs and continue processing, wrap
the update an eval().

=head2 Other functions

The tie object supports several useful methods.  In order to call
these methods, you must either save the function result from the tie()
call (which returns the object), or call tied() on the tie variable to
recover the object.

=over 4

=item connect(), error(), errstr()

These are low-level class methods.  Connect() is responsible for
establishing the connection with the DBI database.  Errstr() and
error() return $DBI::errstr and $DBI::error respectively.  You may
may override these methods in subclasses if you wish.  For example,
replace connect() with this code in order to use persistent database
connections in Apache modules:
  
 use Apache::DBI;  # somewhere in the declarations
 sub connect {
 my ($class,$dsn,$user,$password,$options) = @_;
    return Apache::DBI->connect($dsn,$user,
                                $password,$options);
 }
  
=item commit()

   (tied %produce)->commit();

When using a database with the autocommit option turned off, values
that are stored into the hash will not become permanent until commit()
is called.  Otherwise they are lost when the application terminates or
the hash is untied.

Some SQL databases don't support transactions, in which case you will
see a warning message if you attempt to use this function.

=item rollback()

   (tied %produce)->rollback();

When using a database with the autocommit option turned off, this
function will roll back changes to the database to the state they were
in at the last commit().  This function has no effect on database that
don't support transactions.

=item select_where()
 
   @keys=(tied %produce)->select_where('price > 1.00 and quantity < 10');

This executes a limited form of select statement on the tied table and
returns a list of records that satisfy the conditions.  The argument
you provide should be the contents of a SQL WHERE clause, minus the
keyword "WHERE" and everything that ordinarily precedes it.  Anything
that is legal in the WHERE clause is allowed, including function
calls, ordering specifications, and sub-selects.  The keys to those
records that meet the specified conditions are returned as an array,
in the order in which the select statement returned them.
 
Don't expect too much from this function.  If you want to execute a
complex query, you're better off using the database handle (see below)
to make the SQL query yourself with the DBI interface.

=item dbh()

   $dbh = (tied %produce)->dbh();
   
This returns the tied hash's underlying database handle.  You can use
this handle to create and execute your own SQL queries.

=item CLOBBER, DEBUG, WARN
   
You can get and set the values of CLOBBER, DEBUG and WARN by directly
accessing the object's hash:

    (tied %produce)->{DEBUG}++;

This lets you change the behavior of the tied hash on the fly, such as
temporarily granting your program write permission.  

There are other variables there too, such as the name of the key
column and database table.  Change them at your own risk!

=back

=head1 PERFORMANCE

What is the performance hit when you use this module rather than the
direct DBI interface?  It can be significant.  To measure the
overhead, I used a simple benchmark in which Perl parsed a 6180 word
text file into individual words and stored them into a database,
incrementing the word count with each store.  The benchmark then read
out the words and their counts in an each() loop.  The database driver
was mySQL, running on a 133 MHz Pentium laptop with Linux 2.0.30.  I
compared Tie::RDBM, to DB_File, and to the same task using vanilla DBI
SQL statements.  The results are shown below:

              UPDATE         FETCH
  Tie::DBI      70 s        6.1  s
  Vanilla DBI   14 s        2.0  s
  DB_File        3 s        1.06 s

There is about a five-fold penalty for updates, and a three-fold
penalty for fetches when using this interface.  Some of the penalty is
due to the overhead for creating sub-objects to handle individual
fields, and some of it is due to the inefficient way the store and
fetch operations are implemented.  For example, using the tie
interface, a statement like $h{record}{field}++ requires as much as
four trips to the database: one to verify that the record exists, one
to fetch the field, and one to store the incremented field back.  If
the record doesn't already exist, an additional statement is required
to perform the insertion.  I have experimented with cacheing schemes
to reduce the number of trips to the database, but the overhead of
maintaining the cache is nearly equal to the performance improvement,
and cacheing raises a number of potential concurrency problems.

Clearly you would not want to use this interface for applications that
require a large number of updates to be processed rapidly.

=head1 BUGS

=head1 BUGS

The each() call produces a fatal error when used with the Sybase
driver to access Microsoft SQL server. This is because this server
only allows one query to be active at a given time.  A workaround is
to use keys() to fetch all the keys yourself.  It is not known whether
real Sybase databases suffer from the same problem.

The delete() operator will not work correctly for setting field values
to null with DBD::CSV or with DBD::Pg.  CSV files do not have a good
conception of database nulls.  Instead you will set the field to an
empty string.  DBD::Pg just seems to be broken in this regard.

=head1 AUTHOR

Lincoln Stein, lstein@cshl.org

=head1 COPYRIGHT

  Copyright (c) 1998, Lincoln D. Stein

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AVAILABILITY

The latest version can be obtained from:
   
   http://www.genome.wi.mit.edu/~lstein/Tie-DBI/
   
=head1 SEE ALSO

perl(1), DBI(3), Tie::RDBM(3)

=cut

1;

#	@(#)TABLEop.pm	1.1	11/14/96

package TABLEop; 
use Sybase::DBlib;

=head1 NAME 

    TABLEOp - Module for Table level operations

=head1 SYNOPSIS

    use TABLEop;

    $titles = new TABLEop ( $dbh, "titles" );

    $titles->insert ( \%data );
    $titles->update ( \%data, \%where );
    $titles->delete ( \%where );
    @all_rows = $titles->select (" where title_id < 10 ");
    %one_row = $titles->select ( " where title_id = 4 ");

=head1 DESCRIPTION

    These routines allow you to treat your data as hashes. They generate
    insert, delete, update statments and actually run them against
    the server. It does the work of generating sql for you. It puts
    the necessary quotes if the datatype is char, datetime etc.

    Additionally you could also do select and get all rows as 
    an array of hash-references or get just one row as a single 
    hash-reference.

    Specification of table follows the usual Sybase conventions,
    i.e. if you did not specify absolute name, it looks if the user
    has a table by the same name.

    The module remembers the full path name of the table and uses it
    for all operations. This avoids the  risk of inadvertant
    changes to your application's database context. 

=over 4

=item Creating a handle 


    use TABLEop;

    $titles = new TABLEop ( $dbh, "titles" );


=item  Inserting 

    %data = ('title_id' => 50, 
             'title' => 'Perl Book', 
             'price' => 50.24, 
             'pub_date' => 'Jan 1 1900' );


    $titles->insert ( \%data );

=item  Deleting 


    %where = ( 'title_id' => 50 );

    $titles->delete ( \%where );

=item  Updating 

    %data = ('title' => 'Perl New Book', 
             'price' => 150.24, 
             'pub_date' => 'Jan 1 2100' );

    %where = ('title_id' = 50 );

    $titles->update ( \%data, \%where );

=item Selecting

    The select behaves defferently depending on whether you are 
    expecting one row OR many rows.
    If you wantarray, you get an Array of hash-references, 
    else you get just a single hash-reference.

    @all_rows = $titles->select ("where title_id < 50");
    OR 
    @all_rows = $titles->select (""); #Select all the rows !

    foreach $row ( @all_rows) {
        printf "title is %s\n", $row->{'title'};
    }

    OR you could,

    $arow = $title->select ( "where title_id = 30");
    printf "The title is %s.\n", $arow->{'title');

=item Features wanted, unwanted 

    Currently does not handle NULL in update/delete/insert.
    This will cause an error. All error handling is left to the caller.

    It would be nice to automatically generate single row updates
    by figuring out unique key columns. 


    Manish I Shah
    mshah@bfm.com

=back1

=cut 

BEGIN {
    #This holds info about all different table 
    #data types by column.
    # $hashref = $all_tables { "table_name" };
    # where
    #   $type = $hashref { "column_name" } 
    #
    $all_tables = {};
}

sub new {
    my $type = shift;
    my $dbh  = shift;
    my $table = shift;
    
    if ($type ne "TABLEop") {
        die "Incorrect usage. Should be new TABLEop (\$dbh, \"table\")\n";
    }

    my $self = {};
    my ($old_db, $db, $user, $coltype, $full_table_name, $obj_id );
    
    $self->{'table'}  = $table;
    ($table, $user, $db) = reverse split ( '\.', $table );
    if (length($db) == 0) {
        @results = $dbh->sql ( "select db_name()" );
        $row = $results[0];
        $db =  $$row[0];
    }

    if (length($user) == 0) {
        @results = $dbh->sql ( "select db_name()" );
        $row = $results[0];
        $old_db =  $$row[0];

        #Change to give db
        $dbh->sql ( "use $db" );

        @results = $dbh->sql ( "select user_name(uid) from sysobjects where id = object_id(\"$table\")" );
        $row = $results[0];
        $user =  $$row[0];

        $dbh->sql ("use $old_db");
    }

        
        
        
    $full_table_name = "$db.$user.$table";
    $self->{'db'} = $db;
    $self->{'user'} = $user;
    $self->{'full_table_name'} = $full_table_name;
    $self->{'dbh'} = $dbh;


    #don t do it again. Indexed by full_table_name
    if ( $all_tables->{ $full_table_name } ) {
        return bless $self;
    } 

    if (!$dbh) { die "Need parameter 'dbh' for initialisation\n"; }

    @results = $dbh->sql ( "select db_name()" );
    $row = $results[0];
    $old_db =  $$row[0];
    
    $dbh->sql ( "use $db" );
    @results = $dbh->sql ( 
                          "select Column_name = c.name,
                        Type = t.name,
                        Length = c.length
                        from syscolumns c, systypes t, sysobjects s
                        where s.name = \"$table\" and 
                              s.type = \"U\" and
                              s.uid = user_id (\"$user\") and 
                              s.id = c.id and 
                              c.usertype *= t.usertype" );

    die "Table $full_table_name not found.\n" if ((scalar @results) == 0);

    foreach $row ( @results )  {
        $column = $$row[0];
        $coltype  = $$row[1];
        
        $col_types->{ $column } = $coltype;
    }

    #Return to where you were.
    $dbh->sql ( "use $old_db" );

    $all_tables->{ $full_table_name } =  $col_types;

    bless $self;
}

#returns a row as a hash ref OR
#multiple rows as an array of hashes
sub select {
    my ( $self ) = shift;
    my ( $where ) = @_;
    my ( $table, $cmd, $dbh, @res  );
    
    $table = $self->{ 'full_table_name' };
    $dbh = $self->{'dbh'};
    
    $cmd = "select * from $table $where";
    $dbh->dbcmd ( $cmd );
    $dbh->dbsqlexec ();
    
    while($dbh->dbresults != NO_MORE_RESULTS) {  # copy all results
        while ( %data = $dbh->dbnextrow(1)) {
            push(@res, {%data} );
        }
    }
    
    return wantarray ? @res : $res[0];
}

sub insert {
    my ( $self ) = shift;
    my ( $col_values ) = @_;
    my ( $key, $cmd, $cmd_cols, $cmd_vals, $col_type );
    
    $table = $self->{ 'full_table_name' };
    my ( $col_types ) = $all_tables->{ $table };

    $cmd_cols = "";
    $cmd_vals = "";

    $separator = "";
    foreach $key ( keys %{$col_values} )  {
        $col_type = $col_types->{ $key };

        if (!$col_type) {
            die "For table '$table', there is no column by name '$key'.\n";
        }

        if ( $col_type =~ /char/ || $col_type =~ /date/ ) {
            $cmd_vals .= sprintf ( "%s \"%s\"", 
                                  $separator,
                                  $col_values->{ $key }); 
        } else {
            $cmd_vals .= sprintf ( "%s %s", 
                                  $separator , 
                                  $col_values->{ $key } );
        }               
        $cmd_cols .= sprintf ( "%s %s", $separator, $key, );
        $separator = ",";
    }

    if (length($cmd_vals) == 0) {
        return;
    }

    $cmd =  sprintf ( "insert into $table\n ( %s )\n values ( %s )",
                     $cmd_cols, 
                     $cmd_vals );
    
    #printf STDERR "$cmd\n";
    $self->{'dbh'}->sql ( $cmd );       
    return 1; 
}

sub update {
    my ( $self ) = shift;
    #these have to be hash_references;
    my ( $set_values, $where_values ) = @_;
    my ( $table ) = $self->{ 'table' };
    my ( $key, $cmd, $cmd_where, $col_type );
    
    $table = $self->{ 'full_table_name' };
    my ( $col_types ) = $all_tables->{ $table };

    $cmd = "update  $table\nset ";
    $separator = "";

    foreach $key ( keys %{$set_values} )  {
        $col_type = $col_types->{ $key };

        if (!$col_type) {
            die "For table '$table', there is no column by name '$key'.\n";
        }

        if ( $col_type =~ /char/ || $col_type =~ /date/ ) {
            $cmd .= sprintf ( "%s\n %s = \"%s\"", 
                             $separator,
                             $key, 
                             $set_values->{ $key }); 
        } else {
            $cmd .= sprintf ( "%s\n %s = %s", 
                             $separator , 
                             $key, 
                             $set_values->{ $key } );
        }               
        $separator = ",";
    }

    $cmd_where = "";
    $separator = "";
    foreach $key ( keys %{$where_values} )  {

        $col_type = $col_types->{ $key };
        if (!$col_type) {
            die "For table '$table', there is no column by name '$key'.\n";
        }
        if ( $col_type =~ /char/ || $col_type =~ /date/ ) {
            $cmd_where .= sprintf ( "%s\n %s = \"%s\"", 
                                   $separator,
                                   $key, 
                                   $where_values->{ $key }); 
        } else {
            $cmd_where .= sprintf ( "%s\n %s = %s", 
                                   $separator , 
                                   $key, 
                                   $where_values->{ $key } );
        }               
        $separator = " and ";
    }
    
    if (length($cmd_where) > 0) {
        $cmd .= "\nwhere " . $cmd_where;
    }

    #printf STDERR "$cmd\n";
    $self->{'dbh'}->sql ( $cmd );       
    return 1; 

}


sub delete {
    my ( $self ) = shift;
    #this has to be hash %x = { 'column' } =  value;
    my ( $col_values ) = @_;

    my ( $table ) = $self->{ 'table' };
    my ( $key, $cmd, );
    
    $table = $self->{ 'full_table_name' };
    my ( $col_types ) = $all_tables->{ $table };

    $separator = "";
    $cmd = "delete $table \nwhere ";
    foreach $key ( keys %{$col_values} )  {
        $col_type = $col_types->{ $key };

        if (!$col_type) {
            die "For table '$table', there is no column by name '$key'.\n";
        }

        if ( $col_type =~ /char/ || $col_type =~ /date/ ) {
            $cmd .= sprintf ( " %s\n %s =  \"%s\"", 
                             $separator,
                             $key, 
                             $col_values->{ $key }); 
        } else {
            $cmd .= sprintf ( " %s\n %s = %s", 
                             $separator , 
                             $key,
                             $col_values->{ $key } );
        }               
        $separator = "and";
    }

    #printf STDERR "$cmd\n";
    $self->{'dbh'}->sql ( $cmd );       

    return 1; 

}

sub get_max_key { 
    my ( $self ) = shift;
    my ( $key_field ) = @_;

    my ( $cmd );

    $cmd = "select max($key_field) from " . $self->{'full_table_name'};
    @results = $self->{'dbh'}->sql ( $cmd );

    $row = $results[0];
    return $$row[0];
}


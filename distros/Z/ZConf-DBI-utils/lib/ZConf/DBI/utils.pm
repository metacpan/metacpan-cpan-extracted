package ZConf::DBI::utils;

use warnings;
use strict;
use DBIx::Admin::TableInfo;
use DBIx::Admin::CreateTable;

=head1 NAME

ZConf::DBI::utils - Assorted utilities for ZConf::DBI.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

This is primarily meant for quick small things. If you are going to calling a lot
of stuff here repeatively/heavily, you are probally going to be better off making use of what
ever is being called by the function directly.

=head1 METHODS

=head2 new

This initiates the object.

One arguement is required and it is the 'ZConf::DBI' object.

    my $foo=ZConf::DBI::util->new($zcdbi);
    if($foo->error){
        warn('error code:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub new{
	my $zcdbi=$_[1];
	my $function='new';
	
	my $self={error=>undef,
			  perror=>undef,
			  errorString=>undef,
			  module=>'ZConf-DBI-util',
			  zcdbi=>$zcdbi,
			  };
	bless $self;

	#make sure a object was not passed
	if (!defined( $self->{zcdbi} )) {
		$self->{perror}=1;
		$self->{error}=1;
		$self->{errorString}='No ZConf::DBI object passed';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}

	#make sure it is the correct type of object
	if (ref($self->{zcdbi}) ne 'ZConf::DBI') {
		$self->{perror}=1;
		$self->{error}=2;
		$self->{errorString}='No ZConf::DBI object passed';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return $self;	
	}

	return $self;
}

=head2 create_table

This creates a new table using DBIx::Admin::CreateTable->create_table.

Three arguements are required. The first is the data source name. The second is
the table name. The third is a SQL string describing the columns.

    $foo->create_table('whatever', 'sometable', 'id char(32) primary key, data varchar(255) not null');
    if($foo->error){
        warn('error code:'.$error.': '.$foo->errorString);
    }

=cut

sub create_table{
	my $self=$_[0];
	my $dsName=$_[1];
	my $table=$_[2];
	my $sql=$_[3];
	my $function='create_table';

	#makes sure we have a data source
	if (!defined($dsName)) {
		$self->{error}=3;
		$self->{errorString}='No data source name specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#makes sure we have a table
	if (!defined($table)) {
		$self->{error}=5;
		$self->{errorString}='No table name specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#makes sure we have a table
	if (!defined($sql)) {
		$self->{error}=7;
		$self->{errorString}='No SQL defined';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#connect
	my $dbh=$self->{zcdbi}->connect($dsName);
	if ($self->{zcdbi}->error) {
		$self->{error}=6;
		$self->{errorString}='Connect errored';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;		
	}

	#create the dbix object
	my($admin) = DBIx::Admin::CreateTable->new(
											 dbh=>$dbh,
											 );
	if (!defined($admin)) {
		$self->{error}=4;
		$self->{errorString}='DBIx::Admin::CreateTable->new returned undef';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#create it
	my $returned=$admin->create_table('create table '.$table.' ( '.$sql.' )');
	
	#if the returned value is empty, but defined, it worked
	if ($returned eq '') {
		return 1;
	}

	#it did not work as the returned value is not equal to ''
	$self->{error}=8;
	$self->{errorString}='DBIx::Admin::CreateTable->create_table errored. error="'.$returned.'"';
	warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
	return undef;
}

=head2 do

This executes the do statement on a DBH created from the data source.

Two arguements are required. The first is the data source. The second
is the SQL.

    $foo->create_table('whatever', 'drop sequence fubar;');
    if($foo->error){
        warn('error code:'.$error.': '.$foo->errorString);
    }

=cut

sub do{
	my $self=$_[0];
	my $dsName=$_[1];
	my $sql=$_[2];
	my $function='do';

	#makes sure we have a data source
	if (!defined($dsName)) {
		$self->{error}=3;
		$self->{errorString}='No data source name specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#makes sure we have a table
	if (!defined($sql)) {
		$self->{error}=7;
		$self->{errorString}='No SQL defined';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#connect
	my $dbh=$self->{zcdbi}->connect($dsName);
	if ($self->{zcdbi}->error) {
		$self->{error}=6;
		$self->{errorString}='Connect errored';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;		
	}

	return $dbh->do($sql);
}

=head2 drop_table

This drops a table using DBIx::Admin::CreateTable->drop_table.

Two arguements are required. The first is the data source name. The second is
the table name.

    $foo->create_table('whatever', 'sometable');
    if($foo->error){
        warn('error code:'.$error.': '.$foo->errorString);
    }

=cut

sub drop_table{
	my $self=$_[0];
	my $dsName=$_[1];
	my $table=$_[2];
	my $function='drop_table';

	#makes sure we have a data source
	if (!defined($dsName)) {
		$self->{error}=3;
		$self->{errorString}='No data source name specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#makes sure we have a table
	if (!defined($table)) {
		$self->{error}=5;
		$self->{errorString}='No table name specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#connect
	my $dbh=$self->{zcdbi}->connect($dsName);
	if ($self->{zcdbi}->error) {
		$self->{error}=6;
		$self->{errorString}='Connect errored';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;		
	}

	#create the dbix object
	my($admin) = DBIx::Admin::CreateTable->new(
											 dbh=>$dbh,
											 );
	if (!defined($admin)) {
		$self->{error}=4;
		$self->{errorString}='DBIx::Admin::CreateTable->new returned undef';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#create it
	my $returned=$admin->drop_table($table);
	
	#if the returned value is empty, but defined, it worked
	if ($returned eq '') {
		return 1;
	}

	#it did not work as the returned value is not equal to ''
	$self->{error}=8;
	$self->{errorString}='DBIx::Admin::CreateTable->drop_table errored. error="'.$returned.'"';
	warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
	return undef;	
}

=head2 error

Returns the current error code and true if there is an error.

If there is no error, undef is returned.

    my $error=$foo->error;
    if($error){
        warn('error code:'.$error.': '.$foo->errorString);
    }

=cut

sub error{
    return $_[0]->{error};
}

=head2 errorString

Returns the error string if there is one. If there is not,
it will return undef.

    my $error=$foo->error;
    if($error){
        warn('error code:'.$error.': '.$foo->errorString);
    }

=cut

sub errorString{
    return $_[0]->{errorString};
}

=head2 table_columns

This returns a array reference of table column names found by
DBIx::Admin::TableInfo->columns.

There are three arguements taken. The first, and required, is the data source name.
The second, and optional, is the schema name. The third, and optional, is the schema.

    my $tables=$foo->table_columns('tigerline', 'geometry_columns');
    if($foo->error){
        warn('error code:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub table_columns{
	my $self=$_[0];
	my $dsName=$_[1];
	my $table=$_[2];
	my $schema=$_[3];
	my $function='table_columns';

	if (!defined($dsName)) {
		$self->{error}=3;
		$self->{errorString}='No data source name specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	if (!defined($table)) {
		$self->{error}=5;
		$self->{errorString}='No table name specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	my $dbh=$self->{zcdbi}->connect($dsName);

	my($admin) = DBIx::Admin::TableInfo->new(
											 dbh=>$dbh,
											 schema=>$schema,
											 );

	if (!defined($admin)) {
		$self->{error}=4;
		$self->{errorString}='DBIx::Admin::TableInfo->new returned undef';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	return $admin->columns($table);
}

=head2 table_info

This returns a hash reference of table column names found by
DBIx::Admin::TableInfo->info.

There are two arguements taken. The first, and required, is the data source name.
The second, and optional, is the schema name.

    my $tables=$foo->table_info('tigerline', 'geometry_columns');
    if($foo->error){
        warn('error "'.$foo->error.'"');
    }

=cut

sub table_info{
	my $self=$_[0];
	my $dsName=$_[1];
	my $schema=$_[2];
	my $function='table_info';

	if (!defined($dsName)) {
		$self->{error}=3;
		$self->{errorString}='No data source name specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	my $dbh=$self->{zcdbi}->connect($dsName);

	my($admin) = DBIx::Admin::TableInfo->new(
											 dbh=>$dbh,
											 schema=>$schema,
											 );

	if (!defined($admin)) {
		$self->{error}=4;
		$self->{errorString}='DBIx::Admin::TableInfo->new returned undef';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	return $admin->info;
}

=head2 tables

This returns a array refernce of table names found by
DBIx::Admin::TableInfo->tables.

There are two arguements taken. The first, and required, is the data source name.
The second, and optional, is the schema name.

    my $tables=$foo->tables('tigerline');
    if($foo->error){
        warn('error "'.$foo->error.'"');
    }

=cut

sub tables{
	my $self=$_[0];
	my $dsName=$_[1];
	my $schema=$_[2];
	my $function='tables';

	if (!defined($dsName)) {
		$self->{error}=3;
		$self->{errorString}='No data source name specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	my $dbh=$self->{zcdbi}->connect($dsName);

	my($admin) = DBIx::Admin::TableInfo->new(
											 dbh=>$dbh,
											 schema=>$schema,
											 );

	if (!defined($admin)) {
		$self->{error}=4;
		$self->{errorString}='DBIx::Admin::TableInfo->new returned undef';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	return $admin->tables;
}

=head2 errorblank

This blanks the error storage and is only meant for internal usage.

It does the following.

    $self->{error}=undef;
    $self->{errorString}=undef;

=cut

#blanks the error flags
sub errorblank{
        my $self=$_[0];

        if ($self->{perror}) {
                warn('ZConf-DevTemplate errorblank: A permanent error is set');
                return undef;
        }

        $self->{error}=undef;
        $self->{errorString}=undef;

        return 1;
}

=head1 ERROR CODES

=head2 1

No ZConf::DBI object passed.

=head2 2

The passed object is not a ZConf::DBI object.

=head2 3

No data source name specified.

=head2 4

DBIx::Admin::TableInfo->new returned undef.

=head2 5

No table specified.

=head2 6

Connect errored.

=head2 7

No SQL defined.

=head2 8

Creating the table frailed.

=head2 9

Dropping the table failed.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zconf-dbi-utils at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ZConf-DBI-utils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ZConf::DBI::utils


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ZConf-DBI-utils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ZConf-DBI-utils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ZConf-DBI-utils>

=item * Search CPAN

L<http://search.cpan.org/dist/ZConf-DBI-utils/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of ZConf::DBI::utils

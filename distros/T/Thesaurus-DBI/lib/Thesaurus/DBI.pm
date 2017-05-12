package Thesaurus::DBI;

use strict;

use vars qw[$VERSION];

$VERSION = '0.01';

use base 'Thesaurus';
use DBI;

use Params::Validate qw( validate SCALAR BOOLEAN OBJECT );

# database structure (only needed to create db)
my $DB_TABLES = << "END" ;
CREATE TABLE assignments (
  word1 bigint(20) unsigned NOT NULL default '0',
  word2 bigint(20) unsigned NOT NULL default '0',
  UNIQUE KEY word1 (word1,word2),
  UNIQUE KEY word2 (word2,word1)
);

CREATE TABLE word (
  ID bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  word varchar(150) NOT NULL default '',
  wordindex varchar(150) default NULL,
  PRIMARY KEY  (ID),
  UNIQUE KEY word (word),
  KEY wordindex (wordindex)
) AUTO_INCREMENT=1 ;

END

#########################
# initialize dbconnection
# overwritten
# param: db-connection or db-access data
# return:
# added: jseibert, 30.05.2006
#########################
sub _init {
    my $self = shift;
    # check parameters
    my %p = validate( @_,
                      { dbhandle => { type => OBJECT, optional => 1, isa => [ qw( DBI ) ] },
                      	dbtype =>	{type=>SCALAR, optional => 1, default=>'dbi:mysql'},
                        dbname =>	{type=>SCALAR},
                        dbhost  => { type => SCALAR, optional => 1, default => 'localhost' },
                        dbuser     => { type => SCALAR, optional => 1, default=>'' },
                        dbpassword     => { type => SCALAR, optional => 1, default=>'' },
                        
                      },
                    );
                    
  	# use existing database connection
	if ($p{dbhandle}) {
		$self->{db} = $p{dbhandle};

	# open database connection
	} else {
		my $dsn = "$p{dbtype}:host=$p{dbhost};database=$p{dbname}";
		my $dbh = DBI->connect($dsn, $p{dbuser}, $p{dbpassword}, {'PrintError' => '1',	'RaiseError' => '0'} );
	 	if (!$dbh) {
	 		die "db_connect:" . DBI::errstr();
			return undef;
	 	}
	 	$self->{db}   = $dbh;
	}
	
	$self->{params} = \%p;
	return 1;
}


#########################
# save synonyms
# param: list_of_synonyms: ARRAYREF_OF_String
# return: Boolean
# added: jseibert, 01.06.2006
#########################
sub _add_list {
    my $self = shift;
    my $list = shift;

	# create / get id's for every string
	my @ids = map {$self->_save_word($_)} @$list;
	
	# save assignments
	$self->_save_assignment_list(\@ids);
}

#########################
# Search entries in Thesaurus
# in mysql: everything ist case-insensitive
# param: list_of_synonyms: ARRAY_OF_String
# return: HASHREF
# added: jseibert, 01.06.2006
#########################
sub _find {
    my $self = shift;
	
	# hash for results
    my %lists;
    
    # process all parameter and query database
    foreach my $key (@_) {
        my $search_key = $self->{params}{ignore_case} ? lc $key : $key;
        # ignore duplicates
        next if $lists{$key};
		
		my $words = $self->_find_in_db($key);
		
		foreach my $w (@$words) {
			push( @{ $lists{$key} }, $w ) ;
		}
    }
    return \%lists;
}

#########################
# delete synonym
# delete word and all corresponding assignments
# param: word: ARRAY_OF_String
# return: Boolean
# added: jseibert, 30.05.2006
#########################
sub delete {
    my $self = shift;
	my @list = @_;
	
	# map words to (existing) id's
	my @ids = map {$self->_find_word($_)} @list;
	
	# delete all words
	for (my $i=0; $i<@ids; $i++) {
		my $id = $ids[$i];
		next if (!$id);
		$self->_delete_word($id);
	}
}

#########################
# Create database-tables for a new thesaurus
# param: 
# return: Boolean
# added: jseibert, 30.05.2006
#########################
sub create_tables {
	my $self = shift;
	my @queries = split(';', $DB_TABLES);
	for (@queries) {
		# ingore empty lines / queries
		next if ($_ =~ /^\s*$/);
		$self->_db_do($_);
	}
	return;
}


######################### Internal helper methods #######################

#########################
# search for an existing keyword in database. Create new one if none found.
# param: word: String
# return: ID: INT
# added: jseibert, 30.05.2006
#########################
sub _save_word {
	my $self = shift;
	my $word = shift;
	my $id = $self->_find_word($word);
	# existing word?
	if ($id) {
		return $id;

	# create new
	} else {
		# create index value: (additional information in brackets will be removed)
		my $key = $word;
		$key =~ s/\s*\(.*?\)//gi;
		$key =~ s/\s*$//gi;
		$key =~ s/^\s*//gi;
		
		$self->_db_do("INSERT INTO word SET word = ?, wordindex = ? ", $word, $key);
		my $id = $self->_db_singlevalue("SELECT LAST_INSERT_ID() FROM word LIMIT 1");
		return $id;
	}
}

#########################
# Save assignments between words
# param: ids: ARRAYREF_OF_INT
# return: Boolean
# added: jseibert, 30.05.2006
#########################
sub _save_assignment_list {
	my $self = shift;
	my $ids = shift;
	# assign every word(id) with all others
	for (my $i=0; $i<@$ids; $i++) {
		my $id1 = $ids->[$i];
		for (my $j=$i+1; $j < @$ids; $j++) {
			my $id2 = $ids->[$j];
			$self->_save_assignment($id1, $id2);
		}
	}
	return 1;
}

#########################
# helper method: save a single word assignment
# param: id1: INT, id2: INT
# return: Boolean
# added: jseibert, 30.05.2006
#########################
sub _save_assignment {
	my $self = shift;
	my $id1 = shift;
	my $id2 = shift;
	return if (!$id1 || !$id2);
	
	if (!$self->_find_assignment($id1, $id2)) {
		$self->_db_do('INSERT INTO assignments SET word1 = ?, word2 = ?', $id1, $id2);
	}
	
	return 1;
}

#########################
# helper-method: serach for an existing assignment
# param: id1: INT, id2: INT
# return: Boolean
# added: jseibert, 30.05.2006
#########################
sub _find_assignment {
	my $self = shift;
	my $id1 = shift;
	my $id2 = shift;
	
	my $sql = 'SELECT 1 FROM assignments WHERE (word1 = ? AND word2 = ?) OR (word1 = ? AND word2 = ?) LIMIT 1';
	my $found = $self->_db_singlevalue($sql, $id1, $id2, $id2, $id1);
	return $found || 0;
}

#########################
# delete a word and all assignments to others
# param: word_id: INT
# return: Boolean
# added: jseibert, 30.05.2006
#########################
sub _delete_word {
	my $self = shift;
	my $id = shift;
	
	my $sql = 'DELETE FROM word WHERE ID = ?';
	$self->_db_do($sql, $id);
	$sql = 'DELETE FROM assignments WHERE (word1 = ? OR word2 = ?)';
	return $self->_db_do($sql, $id, $id);
}



#########################
# helper-method: search all synonyms of a given word
# param: word: String
# return: ARRAYREF_OF_string
# added: jseibert, 30.05.2006
#########################
sub _find_in_db {
	my $self = shift;
	my $key = shift;
	
	# find list of all aliases for the given word
	my $sql = "SELECT IF (word.ID = w1.ID, w2.word, w1.word) AS alias, word.word AS word FROM word 
INNER JOIN `assignments` ON ( assignments.word1 = word.ID
OR assignments.word2 = word.ID )
INNER JOIN word AS w1 ON assignments.word1 = w1.ID
INNER JOIN word AS w2 ON assignments.word2 = w2.ID
WHERE word.wordindex = ?";
	
	my $sth = $self->_db_query($sql, $key);
	
	my @words = ();
	# fetch every single alias
	while (my ($word) = $sth->fetchrow_array()) {
		push(@words, $word);
	}
	# synonyms found? add the given word in the result list
	if (@words) {
		unshift(@words, $key);
	}
	return \@words;
}

#########################
# search for the given word in the database and return it's ID
# param: word: String
# return: ID: INT
# added: jseibert, 01.06.2006
#########################
sub _find_word {
	my $self = shift;
	my $word = shift;
	return $self->_db_singlevalue('SELECT ID FROM word WHERE word = ?', $word);
}

#########################
# execute db-query, with error detection
# param: query: String, [params: ARRAY_OF_String]
# return: statement: DBI::st
# added: jseibert, 30.05.2006
#########################
sub _db_query {
	my $self = shift;
	my $sql = shift;
	my @data = @_;
	
	# prepare sql query
	my $sth = $self->{'db'}->prepare($sql);
	if (!$sth) {
		my $error = $self->{'db'}->errstr();
		die "db_prepare: $error . on query: $sql";
	}
	
	# execute query
	my $result = $sth->execute(@data);
	if (not defined $result) {
		my $error = $self->{'db'}->errstr();
		die "db_execute: $error . on query: $sql";
	}
	# return statement handler
	return $sth;
}

#########################
# get a single value (one row) from db
# param: sql: String, data: ARRAY_OF_String
# return: String | ARRAY_OF_String
# added: jseibert, 30.05.2006
#########################
sub _db_singlevalue {
	my $self = shift;
	my $sql = shift;
	my $sth = $self->_db_query($sql, @_);
	
	my @values = $sth->fetchrow_array();
	# return eather one value or the whole row
	return (wantarray) ? @values : $values[0]; 
}

#########################
# send insert/update/delete (no result data)
# param: sql: String
# return: Boolean
# added: jseibert, 30.05.2006
#########################
sub _db_do {
	my $self = shift;
	my $sql = shift;
	my $sth = $self->_db_query($sql, @_);
	return 1;
}

1;
__END__

=head1 NAME

Thesaurus::DBI - Store and query synonyms (Thesaurus) in an SQL database.

=head1 SYNOPSIS

	use Thesaurus::DBI;
	
	# create new database connection
	my $th = new Thesaurus::DBI(dbhost=> 'localhost', dbname=>'thesaurus',dbuser=>'user',dbpassword=>'pass');
	
	# use existing database connection
	my $th = new Thesaurus::DBI(dbhandle => $dbi, dbname=>'thesaurus',dbuser=>'user',dbpassword=>'pass');
	
	# initialize database
	$th->create_tables();
	
	# query thesaurus
	my @synonyms = $th->find('synonym');
	
	# add synonyms
	$th->add(['word', 'synonym']);
	
	# delete word
	$th->delete('word');


=head1 DESCRIPTION

This subclass of C<Thesaurus> implements persistence by using an SQL database.

This module requires the C<DBI> module from CPAN. To use it with certain database servers, 
the corresponding database drivers are needed, too.
(Mysql -> DBD::mysql)

Please note, that database servers like MySQL doesn't take care of case-sensitivity.
So the queries to the thesaurus-database wil all bei case-insensitive.

=head1 METHODS

=over 4

=item * new

This subclass's C<new> method takes the following parameters, in
addition to those accepted by its parent class:

=over 8

=item * dbhost => 'localhost'

Host of the database server. Default value: localhost

=item * dbname => 'thesaurus'

Name of the database to connect to.

=item * dbuser => 'user'

Username for the database connection

=item * dbpassword => 'pass'

Password for the database connection

=item * dbhandle => $dbi

If you already have an existing connection to the database where the thesaurus tables are found in (word, assignment),
you can pass it in by using this parameter.

=back

=item * create_tables

Method to initialize the database to store synonyms in. Creates two new database tables to store all words 
and the corresponding assignments.

=back

=head1 SEE ALSO

Thesaurus, DBI, DBD::mysql

=head1 SYNONYM SOURCES

Listed below are some links for synonym databases, that can be used with this module

=item * English

http://www.thesaurus.com/
http://wordnet.princeton.edu/perl/webwn/

=item * Deutsch

http://www.openthesaurus.de

=item * Polish

http://synonimy.ux.pl/

=item * Espanol

http://openoffice-es.sourceforge.net/thesaurus/

=item * Slovenska

http://www.openthesaurus.tk/

=head1 AUTHOR

Jo Seibert, jseibert (at) seibert-media (dot) net

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jo Seibert

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut

package Xtract::Scan;

use 5.008005;
use strict;
use warnings;
use Carp         ();
use Params::Util ();

our $VERSION = '0.16';





######################################################################
# Class Methods

# Scanner factory
sub create {
	my $class  = shift;
	my $dbh    = shift;
	my $name   = $dbh->{Driver}->{Name};
	my $driver = Params::Util::_DRIVER("Xtract::Scan::$name", 'Xtract::Scan')
		or Carp::croak('No driver for the database handle');
	$driver->new( dbh => $dbh );
}





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check params
	unless ( Params::Util::_INSTANCE($self->dbh, 'DBI::db') ) {
		Carp::croak("Param 'dbh' is not a 'DBI::db' object");
	}

	return $self;
}

sub dbh {
	$_[0]->{dbh};
}





######################################################################
# Database Introspection

sub tables {
	$_[0]->dbh->tables;
}

sub columns {
	$_[0]->dbh->column_info
}




######################################################################
# Generators

# Generic ANSI add table fallback
sub add_table {
	my $self  = shift;
	my $table = shift;
	my $from  = shift || $table->name;
	return $self->add_select(
		$table,
		"SELECT * FROM $from",
	);
}

# Generic ANSI add select
sub add_select {
	my $self   = shift;
	my $tname  = shift;
	my $select = shift;
	my @params = @_;

	# Make an initial scan pass over the query and do a content-based
	# classification of the data in each column.
	my @names = ();
	my @type  = ();
	my @bind  = ();
	SCOPE: {
		my $sth = $self->dbh->prepare($select);
		unless ( $sth ) {
			croak($DBI::errstr);
		}
		$sth->execute( @params );
		@names = map { lc($_) } @{$sth->{NAME}};
		foreach ( @names ) {
			push @type, {
				NULL    => 0,
				NOTNULL => 0,
				NUMBER  => 0,
				INTEGER => 0,
				INTMIN  => undef,
				INTMAX  => undef,
				TEXT    => 0,
				UNIQUE  => {},
			};
		}
		my $rows = 0;
		while ( my $row = $sth->fetchrow_arrayref ) {
			$rows++;
			foreach my $i ( 0 .. $#names ) {
				my $value = $row->[$i];
				my $hash  = $type[$i];
				if ( defined $value ) {
					$hash->{NOTNULL}++;
					if ( $i == 0 and $hash->{UNIQUE} ) {
						$hash->{UNIQUE}->{$value}++;
					}
				} else {
					$hash->{NULL}++;
					delete $hash->{UNIQUE};
					next;
				}
				if ( Params::Util::_NONNEGINT($value) ) {
					$hash->{INTEGER}++;
					if ( not defined $hash->{INTMIN} or $value < $hash->{INTMIN} ) {
						$hash->{INTMIN} = $value;
					}
					if ( not defined $hash->{INTMAX} or $value > $hash->{INTMAX} ) {
						$hash->{INTMAX} = $value;
					}
				}
				if ( defined Params::Util::_NUMBER($value) ) {
					$hash->{NUMBER}++;
				}
				if ( length($value) <= 255 ) {
					$hash->{TEXT}++;
				}
			}
		}
		$sth->finish;

		my $col = 0;
		foreach my $i ( 0 .. $#names ) {
			# Initially, assume this isn't a blob
			push @bind, 0;
			my $hash    = $type[$i];
			my $notnull = $hash->{NULL} ? 'NULL' : 'NOT NULL';
			if ( $hash->{NOTNULL} == 0 ) {
				# The column is completely null, no affinity
				$type[$i] = "$names[$i] NONE NULL";
			} elsif ( $hash->{INTEGER} == $hash->{NOTNULL} ) {
				$type[$i] = "$names[$i] INTEGER $notnull";
				if ( $i == 0 and $hash->{UNIQUE} ) {
					my $d = scalar keys %{$hash->{UNIQUE}};
					if ( $d == $hash->{NOTNULL} ) {
						$type[$i] .= ' PRIMARY KEY';
					}
				}
			} elsif ( $hash->{NUMBER} == $hash->{NOTNULL} ) {
				# This isn't entirely accurate but should be close enough
				$type[$i] = "$names[$i] REAL $notnull";
			} elsif ( $hash->{TEXT} == $hash->{NOTNULL} ) {
				$type[$i] = "$names[$i] TEXT $notnull";
			} else {
				# For now lets assume this is a blob
				$type[$i] = "$names[$i] BLOB $notnull";

				# This is a blob after all
				$bind[-1] = 1;
			}
		}
	}

	return (
		create => [
			"CREATE TABLE $tname (\n"
			. join(",\n", map { "\t$_" } @type)
			. "\n)"
		],
		select => [
			$select,
			@params,
		],
		insert => (
			"INSERT INTO $tname VALUES ( "
			. join( ", ",
				map { '?' } @names
			)
			. " )",
		),
		blobs => scalar( grep { $_ } @bind ) ? \@bind : undef,
	);
}

1;

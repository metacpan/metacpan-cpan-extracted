package Xtract;

=pod

=head1 NAME

Xtract - Take any data source and deliver it to the world

=head1 DESCRIPTION

B<THIS APPLICATION IS HIGHLY EXPERIMENTAL>

Xtract is an command line application for extracting data out of
many different types of databases (or other things that are able
to look like a database via L<DBI>).

More information to follow...

=cut

use 5.008005;
use strict;
use warnings;
use bytes                       ();
use Carp                        'croak';
use File::Which            0.05 ();
use File::Remove           1.42 ();
use Getopt::Long           2.37 ();
use Params::Util           0.35 ();
use IPC::Run3             0.042 ();
use Time::HiRes          1.9709 ();
use Time::Elapsed          0.24 ();
use DBI                    1.57 ':sql_types';
use DBD::SQLite            1.25 ();
use Xtract::Scan                ();
use Xtract::Scan::SQLite        ();
use Xtract::Scan::mysql         ();
use Xtract::Publish             ();
use Xtract::Column              ();
use Xtract::Table               ();

our $VERSION = '0.16';

use Mouse 0.93;

has from         => ( is => 'ro', isa => 'Str'  );
has user         => ( is => 'ro', isa => 'Str'  );
has pass         => ( is => 'ro', isa => 'Str'  );
has to           => ( is => 'ro', isa => 'Str'  );
has index        => ( is => 'ro', isa => 'Bool' );
has trace        => ( is => 'ro', isa => 'Bool' );
has sqlite_cache => ( is => 'ro', isa => 'Int'  );
has argv         => ( is => 'ro', isa => 'ArrayRef[Str]' );
has publish      => ( is => 'rw', isa => 'Xtract::Publish' );

no Mouse;





#####################################################################
# Main Function

sub main {
	my $class = shift || __PACKAGE__;

	# Parse the command line options
	my $FROM  = '';
	my $USER  = '';
	my $PASS  = '';
	my $TO    = '';
	my $INDEX = '';
	my $QUIET = '';
	my $CACHE = '';
	Getopt::Long::GetOptions(
		"from=s"         => \$FROM,
		"user=s"         => \$USER,
		"pass=s"         => \$PASS,
		"to=s"           => \$TO,
		"index"          => \$INDEX,
		"quiet"          => \$QUIET,
		"sqlite_cache=i" => \$CACHE,
	) or die("Failed to parse options");

	# Prepend DBI: to the --from as a convenience if needed
	if ( defined $FROM and $FROM !~ /^DBI:/ ) {
		$FROM = "DBI:$FROM";
	}

	# Create the program instance
	my $self = $class->new(
		from  => $FROM,
		user  => $USER,
		pass  => $PASS,
		to    => $TO,
		index => $INDEX,
		trace => ! $QUIET,
		$CACHE ? ( sqlite_cache => $CACHE ) : (),
		argv  => [ @ARGV ],
	);

	# Clear the existing output sqlite file
	if ( defined $self->to and -e $self->to ) {
		$self->say("Deleting '" . $self->to . "'");
		File::Remove::remove($self->to);
	}

	# Run the object
	$self->run;
}






#####################################################################
# Main Execution

sub run {
	my $self  = shift;
	my $start = Time::HiRes::time();

	# Create the target database
	$self->say("Creating SQLite database " . $self->to);
	$self->to_prepare;

	# Fill the database
	$self->add;

	# Generate any required indexes
	if ( $self->index ) {
		foreach my $table ( $self->to_tables ) {
			my $name = $table->name;
			$self->say("Indexing table $name");
			$self->index_table($table);
		}
	}

	# Finish up the population phase
	$self->say("Cleaning up");
	$self->to_finish;
	$self->disconnect;

	# Pause, briefly, to allow any disk caching stuff to cach up.
	# This is a just a speculative attempt to fix a compression problem.

	# Spawn the publisher to prepare the files for the public
	$self->publish(
		Xtract::Publish->new(
			sqlite => $self->to,
			trace  => $self->trace,
			gz     => 1,
			bz2    => 1,
			lz     => Xtract::LZMA->available,
		)
	);
	$self->publish->run;

	# Summarise the run
	my $elapsed = int(Time::HiRes::time() - $start);
	my $human   = Time::Elapsed::elapsed($elapsed);
	$self->say( "Extraction completed in $elapsed" );
	if ( -f $self->publish->sqlite ) {
		$self->say( "Created " . $self->publish->sqlite );
	}
	if ( -f $self->publish->sqlite_gz ) {
		$self->say( "Created " . $self->publish->sqlite_gz );
	}
	if ( -f $self->publish->sqlite_bz2 ) {
		$self->say( "Created " . $self->publish->sqlite_bz2 );
	}
	if ( -f $self->publish->sqlite_lz ) {
		$self->say( "Created " . $self->publish->sqlite_lz );
	}

	return 1;
}

sub add {
	my $self = shift;

	# Check the command
	my $command = shift(@{$self->{argv}}) || 'all';
	if ( $command eq 'all' ) {
		# Shortcut if there's no tables
		unless ( $self->from_tables ) {
			print "No tables to export\n";
			exit(255);
		}
	} elsif ( $command eq 'null' ) {
		# Do nothing else special
	} else {
		die("Unsupported command '$command'");
	}

	# Push all source tables into the target database
	foreach my $table ( $self->from_tables ) {
		my $name = $table->name;
		$self->say("Publishing table $name");
		my $tstart = Time::HiRes::time();
		my $rows   = $self->add_table($table);
		my $rate   = int($rows / (Time::HiRes::time() - $tstart));
		$self->say("Completed  table $name ($rows rows @ $rate/sec)");
	}

	return 1;
}

sub add_table {
	my $self = shift;
	$self->create_table(
		$self->from_scan->add_table(@_)
	);
}

sub add_select {
	my $self = shift;
	$self->create_table(
		$self->from_scan->add_select(@_)
	);
}

sub create_table {
	my $self   = shift;
	my %params = @_;
	my $create = $params{create};
	my $select = $params{select};
	my $insert = $params{insert};
	my $bind   = $params{bind};

	# Create the table
	$self->to_dbh->do(@$create);

	# Launch the select query
	my $from = $self->from_dbh->prepare(shift(@$select));
	unless ( $from ) {
		croak($DBI::errstr);
	}
	$from->execute(@$select);

	# Stream the data into the target table
	my $dbh = $self->to_dbh;
	$dbh->begin_work;
	$dbh->{AutoCommit} = 0;
	my $rows = 0;
	my $to   = $dbh->prepare($insert) or croak($DBI::errstr);
	while ( my $row = $from->fetchrow_arrayref ) {
		if ( $bind ) {
			# When inserting blobs, we need to use the bind_param method
			foreach ( 0 .. $#$row ) {
				if ( defined $bind->[$_] ) {
					$to->bind_param( $_ + 1, $row->[$_], $bind->[$_] );
				} else {
					$to->bind_param( $_ + 1, $row->[$_] );
				}
			}
			$to->execute;
		} else {
			$to->execute( @$row );
		}
		next if ++$rows % 10000;
		$dbh->commit;
	}
	$dbh->commit;
	$dbh->{AutoCommit} = 1;

	# Clean up
	$to->finish;
	$from->finish;

	return $rows;
}

sub index_table {
	my $self  = shift;
	my $table = shift;
	my $tname = $table->name;
	my $info  = $self->to_dbh->selectall_arrayref("PRAGMA table_info($tname)");
	foreach my $column ( map { $_->[1] } @$info ) {
		$self->index_column($tname, $column);
	}
	return 1;
}

sub index_column {
	my $self    = shift;
	my ($t, $c) = _COLUMN(@_);
	my $unique  = _UNIQUE($self->to_dbh, $t, $c) ? 'UNIQUE' : '';
	$self->to_dbh->do("CREATE $unique INDEX IF NOT EXISTS idx__${t}__${c} ON ${t} ( ${c} )");
	return 1;
}





#####################################################################
# Source Methods

sub from_dbh {
	my $self = shift;
	unless ( $self->{from_dbh} ) {
		$self->say("Connecting to " . $self->from);
		$self->{from_dbh} = DBI->connect(
			$self->from,
			$self->user,
			$self->pass,
			{
				PrintError => 1,
				RaiseError => 1,
			}
		);
		unless ( $self->{from_dbh} ) {
			die("Failed to connect to " . $self->from);
		}
	}
	return $self->{from_dbh};
}

sub from_scan {
	my $self = shift;
	unless ( $self->{from_scan} ) {
		$self->{from_scan} = Xtract::Scan->create( $self->from_dbh );
	}
	return $self->{from_scan};
}

sub from_tables {
	my $self = shift;
	unless ( $self->{from_tables} ) {
		my $scan = $self->from_scan;
		$self->{from_tables} = {
			map {
				$_ => Xtract::Table->new(
					name => $_,
					scan => $scan,
				)
			} $scan->tables
		};
	}
	return map {
		$self->{from_tables}->{$_}
	} sort keys %{$self->{from_tables}};
}

sub from_table {
	my $self = shift;
	my $name = shift;
	unless ( $self->{from_tables} ) {
		$self->from_tables;
	}
	unless ( exists $self->{from_tables}->{$name} ) {
		 die "No such table '$name'";
	}
	return $self->{from_tables}->{$name}
}





#####################################################################
# Destination Methods

sub to_dsn {
	"DBI:SQLite:" . $_[0]->to
}

sub to_dbh {
	my $self = shift;
	unless ( $self->{to_dbh} ) {
		$self->{to_dbh} = DBI->connect( $self->to_dsn, '', '', {
			PrintError => 1,
			RaiseError => 1,
		} );
		unless ( $self->{to_dbh} ) {
			die("Failed to connect to " . $self->to_dsn);
		}
	}
	return $self->{to_dbh};
}

sub to_scan {
	Xtract::Scan->create( shift->to_dbh );
}

sub to_tables {
	my $self   = shift;
	my $scan   = $self->to_scan;
	my $tables = {
		map {
			$_ => Xtract::Table->new(
				name => $_,
				scan => $scan,
			)
		} $scan->tables
	};
	return map {
		$tables->{$_}
	} sort keys %$tables;
}

# Prepare the target database
sub to_prepare {
	my $self = shift;
	my $dbh  = $self->to_dbh;

	# Maximise compatibility
	$dbh->do('PRAGMA legacy_file_format = 1');

	# Turn on all the go-faster pragmas
	$dbh->do('PRAGMA synchronous  = 0');
	$dbh->do('PRAGMA temp_store   = 2');
	$dbh->do('PRAGMA journal_mode = OFF');
	$dbh->do('PRAGMA locking_mode = EXCLUSIVE');

	# Disable auto-vacuuming because we'll only fill this once.
	# Do a one-time vacuum so we start with a clean empty database.
	$dbh->do('PRAGMA auto_vacuum = 0');
	$dbh->do('VACUUM');

	# Set the page cache if needed
	if ( $self->sqlite_cache ) {
		my $page_size = $dbh->selectrow_arrayref('PRAGMA page_size')->[0];
		if ( $page_size ) {
			my $cache_size = $self->sqlite_cache * 1024 * 1024 / $page_size;
			$dbh->do("PRAGMA cache_size = $cache_size");
		}
	}

	return 1;
}

# Finalise the target database
sub to_finish {
	my $self = shift;
	my $dbh  = $self->to_dbh;

	# Tidy up the database settings
	$dbh->do('PRAGMA synchronous  = NORMAL');
	$dbh->do('PRAGMA temp_store   = 0');
	$dbh->do('PRAGMA locking_mode = NORMAL');

	# Precache index optimisation hints
	if ( $self->index ) {
		$dbh->do('ANALYZE');
	}

	return 1;
}





#####################################################################
# Support Methods

sub disconnect {
	my $self = shift;
	if ( $self->{from_scan} ) {
		delete($self->{from_scan});
	}
	if ( $self->{from_dbh} ) {
		delete($self->{from_dbh})->disconnect;
	}
	if ( $self->{to_dbh} ) {
		delete($self->{to_dbh})->disconnect;
	}
	return 1;
}

sub say {
	if ( Params::Util::_CODE($_[0]->trace) ) {
		$_[0]->say( @_[1..$#_] );
	} elsif ( $_[0]->trace ) {
		my $t = scalar localtime time;
		print map { "[$t] $_\n" } @_[1..$#_];
	}
}

sub _UNIQUE {
	my $dbh     = shift;
	my ($t, $c) = _COLUMN(@_);
	my $count   = $dbh->selectrow_arrayref(
		"SELECT COUNT(*), COUNT(DISTINCT $c) FROM $t"
	);
	return !! ( $count->[0] eq $count->[1] );
}

sub _COLUMN {
	(@_ == 1) ? (split /\./, $_[0]) : @_;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Xtract>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<DBI>

=head1 COPYRIGHT

Copyright 2009 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

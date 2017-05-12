package Xtract::Publish;

use 5.008005;
use strict;
use Carp                      ();
use File::Copy              0 ();
use File::Remove         1.42 ();
use Params::Util         0.35 ();
use IO::Compress::Gzip  2.008 ();
use IO::Compress::Bzip2 2.008 ();
use Xtract::LZMA              ();

our $VERSION = '0.16';

use Mouse 0.93;

has 'sqlite' => (
	is        => 'ro',
	isa       => 'Str',
	required  => 1,
);

has 'from' => (
	is        => 'ro',
	isa       => 'Str',
	required  => 0,
	predicate => 'has_from',
);

sub flag ($$) {
	has $_[0] => (
		is       => 'rw',
		isa      => 'Bool',
		required => 1,
		default  => $_[1],
	);
}

flag 'raw'    => 1;
flag 'gz'     => 1;
flag 'bz2'    => 0;
flag 'lz'     => 0;
flag 'atomic' => 0;
flag 'trace'  => 0;

no Mouse;





######################################################################
# Constructor and Accessors

sub new {
	my $self = shift->SUPER::new(@_);

	# Check params
	if ( $self->has_from and not -f $self->from ) {
		Carp::croak("Source file '" . $self->from . "' does not exist");
	}

	return $self;
}

sub sqlite_gz {
	$_[0]->sqlite . '.gz';
}

sub sqlite_bz2 {
	$_[0]->sqlite . '.bz2';
}

sub sqlite_lz {
	$_[0]->sqlite . '.lz';
}






######################################################################
# Main Methods

sub run {
	my $self = shift;

	# Copy the source SQLite database
	my $sqlite = $self->write_sqlite;
	if ( defined $sqlite ) {
		$self->remove($sqlite);
		$self->copy( $self->from => $sqlite );
	}

	# Where to we create the archives from?
	$sqlite = defined($sqlite) ? $sqlite : $self->sqlite;

	# Create the GZip archive
	my $gz = $self->write_gz;
	if ( defined $gz ) {
		$self->remove($gz);
		$self->say("Compressing '$sqlite' into '$gz'");
		my $rv = IO::Compress::Gzip::gzip(
			$sqlite   => $gz,
			AutoClose => 1,
			BinModeIn => 1,
		);
		unless ( $rv ) {
			Carp::croak("Failed to create gzip archive '$gz'");
		}
	}

	# Create the BZip2 archive
	my $bz2 = $self->write_bz2;
	if ( defined $bz2 ) {
		$self->remove($bz2);
		$self->say("Compressing '$sqlite' into '$bz2'");
		my $rv = IO::Compress::Bzip2::bzip2(
			$sqlite   => $bz2,
			AutoClose => 1,
			BinModeIn => 1,
		);
		unless ( $rv ) {
			Carp::croak("Failed to create bzip2 archive '$bz2'");
		}
	}

	# Create the LZMA archive
	my $lz = $self->write_lz;
	if ( defined $lz ) {
		$self->remove($lz);
		$self->say("Compressing '$sqlite' into '$lz'");
		Xtract::LZMA->compress( $sqlite => $lz );
	}

	# Atomically overwrite the original archives
	if ( $self->atomic ) {
		if ( $sqlite ne $self->sqlite ) {
			$self->move( $sqlite => $self->sqlite );
		}
		if ( defined $gz ) {
			$self->move( $gz => $self->sqlite_gz );
		}
		if ( defined $bz2 ) {
			$self->move( $bz2 => $self->sqlite_bz2 );
		}
		if ( defined $lz ) {
			$self->move( $lz => $self->sqlite_lz );
		}
	}

	# Remove any archives we may have had previously that we don't any more
	unless ( defined $gz ) {
		$self->remove( $self->sqlite_gz );
	}
	unless ( defined $bz2 ) {
		$self->remove( $self->sqlite_bz2 );
	}
	unless ( defined $lz ) {
		$self->remove( $self->sqlite_lz );
	}
	if ( $self->from and not $self->raw ) {
		$self->remove( $self->sqlite );
	}

	return 1;
}

sub write_sqlite {
	my $self = shift;
	if ( defined $self->from and $self->sqlite ne $self->from ) {
		if ( $self->atomic ) {
			return $self->sqlite . '.tmp';
		} else {
			return $self->sqlite;
		}
	}
	return undef;
}

sub write_gz {
	my $self = shift;
	if ( $self->gz ) {
		if ( $self->atomic ) {
			return $self->sqlite . '.tmp.gz';
		} else {
			return $self->sqlite_gz;
		}
	}
	return undef;
}

sub write_bz2 {
	my $self = shift;
	if ( $self->bz2 ) {
		if ( $self->atomic ) {
			return $self->sqlite . '.tmp.bz2';
		} else {
			return $self->sqlite_bz2;
		}
	}
	return undef;
}

sub write_lz {
	my $self = shift;
	if ( $self->lz ) {
		if ( $self->atomic ) {
			return $self->sqlite . '.tmp.lz';
		} else {
			return $self->sqlite_lz;
		}
	}
	return undef;
}





######################################################################
# Support Methods

sub say {
	if ( Params::Util::_CODE($_[0]->trace) ) {
		$_[0]->say( @_[1..$#_] );
	} elsif ( $_[0]->trace ) {
		my $t = scalar localtime time;
		print map { "[$t] $_\n" } @_[1..$#_];
	}
}

sub copy {
	my $self = shift;
	$self->say("Copying '$_[0]' to '$_[1]'");
	unless ( File::Copy::copy(@_) ) {
		Carp::croak("Failed to copy '$_[0]' to '$_[1]'");
	}
	return 1;
}

sub move {
	my $self = shift;
	if ( -f $_[1] ) {
		$self->say("Moving '$_[0]' over existing '$_[1]'");
	} else {
		$self->say("Moving '$_[0]' to '$_[1]'");
	}
	$self->say("Copying '$_[0]' to '$_[1]'");
	unless ( File::Copy::move(@_) ) {
		Carp::croak("Failed to move '$_[0]' to '$_[1]'");
	}
	return 1;
}

sub remove {
	my $self = shift;
	my $file = shift;
	
	# Flush any existing file
	if ( -f $file ) {
		$self->say("Removing '$file'");
		unless ( File::Remove::remove( $file ) ) {
			Carp::croak("Failed to remove existing '$file'");
		}
	}

	return 1;
}

1;

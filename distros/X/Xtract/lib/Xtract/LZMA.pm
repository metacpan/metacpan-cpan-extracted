package Xtract::LZMA;

# Abstracts LZMA support across multiple implementations

use 5.008005;
use strict;
use warnings;
use Carp        ();
use File::Which ();
use IPC::Run3   ();

our $VERSION = '0.16';

my $LZMA  = '';
my @WHICH = ();
if ( $^O eq 'MSWin32' ) {
	require Alien::Win32::LZMA;
	$LZMA = 'win32';
} elsif ( @WHICH = File::Which::which('lzma') ) {
	$LZMA = 'unix';
}





#####################################################################
# API Methods

sub available {
	return !! $LZMA;
}

sub compress {
	my $class = shift;
	if ( $LZMA eq 'win32' ) {
		return $class->_win32(@_);
	} elsif ( $LZMA eq 'unix' ) {
		return $class->_unix(@_);
	}
	Carp::croak('LZMA support is not available');
}

sub _win32 {
	my $class = shift;
	unless ( Alien::Win32::LZMA::lzma_compress(@_) ) {
		die "Failed to compress '$_[0]'";
	}
	return 1;
}

sub _unix {
	my $class  = shift;
	my $from   = shift;
	my $to     = shift;
	my $stdout = '';
	my $stderr = '';
	my $result = IPC::Run3::run3(
		[
			$WHICH[0],
			'--compress',
			'--keep',
			'--suffix', '.lz',
			$from,
		], \undef, \$stdout, \$stderr,
	);
	unless ( $result and -f $to ) {
		die 'Failed to lzma SQLite file';
	}
	return 1;
}

1;


use strict;
use warnings;

package Tie::FlatFile::Array;
use base 'Class::Accessor';
use Carp qw(croak);
use Fcntl;
use POSIX qw(:stdio_h ceil);
use FileHandle;
use English qw(-no_match_vars);
use File::Spec::Functions qw(catfile splitpath);

my @fields;

BEGIN {
	our $VERSION = 0.05;
	$VERSION = eval $VERSION;
	@fields = qw(filename flags mode packformat handle
	reclen nulls nulla);
	__PACKAGE__->mk_accessors(@fields);
	*fh = \&handle;
	# require Tie::FlatFile::ArrayHelper;
}

sub TIEARRAY {
	my $class = shift;
	my $self = bless({}, $class);
	my ($filename, $flags, $mode, $opts) = @_;
	my ($packformat);
	local $Carp::CarpLevel = 1;	# Set the stack frame for croak().

	if ('HASH' ne ref($opts)) {
		croak('Options hash missing');
	} else {
		$packformat = $opts->{packformat};
	}

	# Check for missing parameters.
	foreach my $nm (qw(filename flags mode packformat)) {
		my $value = eval "\$$nm";
		unless (defined ($value)) {
			croak("Missing $nm");
		}
		$self->$nm($value);
	}

	# Open the file and save the file handle.
	my $fh = new FileHandle $filename, $flags;
	$self->handle($fh);

	# Store the record length;
	my $len = $self->reclen(length(pack $packformat, (1) x 30));

	{
	no warnings 'uninitialized';
	$self->nulls(pack $packformat, (undef) x 30);
	$self->nulla([(undef) x 30]);
	}

	$self;
}

sub UNTIE {
	my $self = shift;
	return unless $self->handle;
	close($self->handle);
}

sub FETCH {
	my ($self, $index) = @_;
	return undef if $index < 0;

	my $len = $self->reclen;
	my $fh = $self->fh;
	local $Carp::CarpLevel = 1;	# Set the stack frame for croak().

	local $RS = \$len;		# Set the record length.
	seek($fh, $index * $len, SEEK_SET);
	my $data = <$fh>;  # Get a record.
	return undef unless $data;

	# Unpack and return the data as an array reference.
	[ unpack $self->packformat, $data ];
}

sub STORE {
	my ($self, $index, $value) = @_;
	my $len = $self->reclen;
	my $fh = $self->fh;

	seek($fh, $index * $len, SEEK_SET);
	print $fh (pack $self->packformat, @$value);
}

sub FETCHSIZE {
	my $self = shift;
	my $pos = tell($self->fh);

	# Go to the end of the file and find out the
	# size in bytes [using tell()] and divide that
	# by the size of a record.
	seek($self->fh, 0, SEEK_END);
	my $size = tell($self->fh) / $self->reclen;
	$size = ceil($size);

	# Go back to the original position in the file.
	seek($self->fh, $pos, SEEK_SET);
	$size;
}


sub EXTEND {
}


sub EXISTS {
	my ($self, $index) = @_;
	$index >= 0 && $index < $self->FETCHSIZE;
}

sub DELETE {
	my ($self, $index) = @_;
	$self->STORE($index, $self->nulla);
}

sub CLEAR {
	my $self = shift;
	truncate($self->fh, 0);
}

sub PUSH {
	my $self = shift;
	my $size = $self->FETCHSIZE;
	$self->STORE($size++, +shift) while (@_);
}

sub POP {
	my $self = shift;
	my $size = $self->FETCHSIZE;
	my $data = $self->FETCH($size-1);
	truncate($self->fh, ($size-1) * $self->reclen);
	$data;
}

sub SHIFT {
	my $self = shift;
	my $size = $self->FETCHSIZE;
	return undef unless $size;

	my $data = $self->FETCH(0);
	my $reclen = $self->reclen;
	my $fh = $self->fh;
	local $RS = \$reclen;

	foreach my $n (0..$size-2) {
		seek($fh, ($n+1) * $reclen, SEEK_SET);
		my $temp = <$fh>;
		seek($fh, -2*$reclen, SEEK_CUR);
		print $fh $temp;
	}

	truncate($fh, ($size-1)*$reclen );
	$data;
}

sub UNSHIFT {
	my $self = shift;

	for (my $n = $self->FETCHSIZE-1; $n >= 0; --$n) {
		my $ele = $self->FETCH($n);
		$self->STORE($n + @_, $ele);
	}

	foreach my $n (0..$#_) {
		$self->STORE($n, $_[$n]);
	}
	$self->FETCHSIZE;
}


1;


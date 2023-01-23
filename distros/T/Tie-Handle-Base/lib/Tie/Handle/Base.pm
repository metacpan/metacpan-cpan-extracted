#!perl
package Tie::Handle::Base;
use warnings;
use strict;
use Carp;
use warnings::register;
use Scalar::Util qw/blessed/;

# For AUTHOR, COPYRIGHT, AND LICENSE see Base.pod

our $VERSION = '0.18';

## no critic (RequireFinalReturn, RequireArgUnpacking)

our @IO_METHODS = qw/ BINMODE CLOSE EOF FILENO GETC OPEN PRINT PRINTF
	READ READLINE SEEK TELL WRITE /;
our @ALL_METHODS = (qw/ TIEHANDLE UNTIE DESTROY /, @IO_METHODS);

sub new {
	my $class = shift;
	my $fh = \do{local*HANDLE;*HANDLE};  ## no critic (RequireInitializationForLocalVars)
	tie *$fh, $class, @_;
	return $fh;
}

sub TIEHANDLE {
	my $class = shift;
	my $innerhandle = shift;
	$innerhandle = \do{local*HANDLE;*HANDLE}  ## no critic (RequireInitializationForLocalVars)
		unless defined $innerhandle;
	@_ and warnings::warnif("too many arguments to $class->TIEHANDLE");
	return bless { __innerhandle=>$innerhandle }, $class;
}
sub UNTIE    { delete shift->{__innerhandle}; return }
sub DESTROY  { delete shift->{__innerhandle}; return }

sub innerhandle { shift->{__innerhandle} }
sub set_inner_handle { $_[0]->{__innerhandle} = $_[1] }

sub BINMODE  {
	my $fh = shift->{__innerhandle};
	# note binmode is prototyped, so the conditional is needed here:
	if (@_) { return binmode($fh,$_[0]) }
	else    { return binmode($fh)       }
}
sub READ     { read($_[0]->{__innerhandle}, $_[1], $_[2], defined $_[3] ? $_[3] : 0 ) }
# The following would work in Perl >=5.16, when CORE:: was added
#sub BINMODE  { &CORE::binmode (shift->{__innerhandle}, @_) }
#sub READ     { &CORE::read    (shift->{__innerhandle}, \shift, @_) }

sub CLOSE    {    close  shift->{__innerhandle} }
sub EOF      {      eof  shift->{__innerhandle} }
sub FILENO   {   fileno  shift->{__innerhandle} }
sub GETC     {     getc  shift->{__innerhandle} }
sub READLINE { readline  shift->{__innerhandle} }
sub SEEK     {     seek  shift->{__innerhandle}, $_[0], $_[1] }
sub TELL     {     tell  shift->{__innerhandle} }

sub OPEN {
	my $self = shift;
	$self->CLOSE if defined $self->FILENO;
	# note open is prototyped, so the conditional is needed here:
	if (@_) { return open $self->{__innerhandle}, shift, @_ }
	else    { return open $self->{__innerhandle} }
}

# The following work too, but I chose to implement them in terms of
# WRITE so that overriding output behavior is easier.
#sub PRINT    {    print {shift->{__innerhandle}} @_ }
#sub PRINTF   {   printf {shift->{__innerhandle}} shift, @_ }

# tests show that print, printf, and syswrite always return undef on fail,
# even in list context, so we'll do an explicit "return undef"

sub PRINT {
	my $self = shift;
	my $str = join defined $, ? $, : '', @_;
	$str .= $\ if defined $\;
	return defined( $self->WRITE($str) ) ? 1 : undef;
}
sub PRINTF {
	my $self = shift;
	return defined( $self->WRITE(sprintf shift, @_) ) ? 1 : undef;
}
sub WRITE { inner_write(shift->{__innerhandle}, @_) }

# the docs tell us not to intermix syswrite with other calls like print,
# and since our tied sysread uses read internally, we should avoid the
# sysread/-write functions in general,
# so we emulate syswrite similarly to Tie::StdHandle, with substr+print
sub inner_write { # can be called as function or method
	shift if blessed($_[0]) && $_[0]->isa(__PACKAGE__);
	# WRITE this, scalar, length, offset
	# substr EXPR, OFFSET, LENGTH
	my $len = defined $_[2] ? $_[2] : length($_[1]);
	my $off = defined $_[3] ? $_[3] : 0;
	my $data = substr($_[1], $off, $len);
	local $\=undef;
	print {$_[0]} $data and return length($data);
	return undef;  ## no critic (ProhibitExplicitReturnUndef)
}

sub open_parse {
	croak "not enough arguments to open_parse" unless @_;
	my $fnwm = shift;
	carp "too many arguments to open_parse" if @_>1;
	return ($fnwm, shift) if @_;  # passthru
	if ( $fnwm =~ s{^\s* ( \| | \+? (?: < | >>? ) (?:&=?)? ) | ( \| ) \s*$}{}x ) {
		my ($x,$y) = ($1,$2);  $fnwm =~ s/^\s+|\s+$//g;
		if ( defined $y )      { return ('-|', $fnwm) }
		elsif ( $x eq '|' )    { return ('|-', $fnwm) }
		else                   { return ($x,   $fnwm) }
	} else
		{ $fnwm=~s/^\s+|\s+$//g; return ('<',  $fnwm) }
}

1;

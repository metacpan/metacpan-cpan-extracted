package VCS::StarTeam;

#require 5.005_62;
use strict;
use warnings;

use Carp;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use VCS::StarTeam ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
hist history list log checkout get co diff vdiff checkin ci put
);

our $VERSION = '0.08';


# Preloaded methods go here.

#
# constructor
#
sub new {
	my( $class, $optionRef ) = @_;

	$class = ref($class) || $class;

	my( $self ) = ( ref( $optionRef ) eq 'HASH' ) ? $optionRef : {};

	my( $username ) = $^O eq 'MSWin32' ? $ENV{'USERNAME'}
	    : $^O eq 'os2' ? $ENV{'USER'} || $ENV{'LOGNAME'}
	    : $^O eq 'MacOS' ? $ENV{'USER'}
	    : eval { getpwuid($<) };	# May be missing

	my( %default ) = (
		'batchmode'		=> 0,
		'compress'		=> 0,
		'host'			=> 'localhost',
		'endpoint'		=> '1024',
		'project'		=> '',
		'password'		=> '',
		'path'			=> '',
		'recurse'		=> 0,
		'stoponerror'	=> 0,
		'username'		=> $username,
		'verbose'		=> 0,
		'view'			=> '',
	);

	for my $option ( keys( %default ) ) {
		$self -> {$option} = $default{$option} if ( ! defined( $self -> {$option} ) );
		print "$option = $self->{$option}\n";
	}
	
	croak("Failure: No project name specified")	if ( ! $self->{'project'} );

	return bless $self, $class;
}

#
# private routine for creating project string for stcmd commands
#
sub _getpparam {
	my( $self ) = shift;
	my( $pparam ) = join( '', $self->{'username'}, ":", 
		$self->{'password'}, "\@", $self->{'host'}, ":",
		$self->{'endpoint'}, "/", $self->{'project'}, "/", 
		$self->{'view'}, "/", $self->{'path'} );   
	return $pparam;
}

#
# hist methods
#
sub history {
	# convenience method for calling _hist
	my( $self ) = shift;
	$self->_hist( @_ );	
}

sub hist {
	# convenience method for calling _hist
	my( $self ) = shift;
	$self->_hist( @_ );	
}

sub log {
	# convenience method for calling _hist
	my( $self ) = shift;
	$self->_hist( @_ );	
}

sub _hist {
	# run 'stcmd hist...'
	my( $self ) = shift;
	my( @args ) = ( 'stcmd' );
	push( @args, 'hist' );
	push( @args, '-nologo' );
	push( @args, join( '', '-p ', "\"", $self->_getpparam( ), "\"" ) );
	push( @args, '-cmp' ) unless $self->{'compress'} == 0;
	push( @args, '-is' ) unless $self->{'recurse'} == 0;
	push( @args, '-x' ) unless $self->{'batchmode'} == 0;
	push( @args, '-stop' ) unless $self->{'stoponerror'} == 0;
	push( @args, @_ );
	$self->_runOrCroak( @args );
}

#
# list methods
#
sub list {
	# run 'stcmd list...'
	my( $self ) = shift;
	my( @args ) = ( 'stcmd' );
	push( @args, 'list' );
	push( @args, '-nologo' );
	push( @args, join( '', '-p ', "\"", $self->_getpparam( ), "\"" ) );
	push( @args, '-cmp' ) unless $self->{'compress'} == 0;
	push( @args, '-x' ) unless $self->{'batchmode'} == 0;
	push( @args, '-stop' ) unless $self->{'stoponerror'} == 0;
	push( @args, @_ );
	$self->_runOrCroak( @args );
}

#
# checkout methods
#
sub checkout {
	# convenience method for calling _co
	my( $self ) = shift;
	$self->_co( @_ );	
}

sub co {
	# convenience method for calling _co
	my( $self ) = shift;
	$self->_co( @_ );	
}

sub get {
	# convenience method for calling _co
	my( $self ) = shift;
	$self->_co( @_ );	
}

sub _co {
	# run 'stcmd co...'
	my( $self ) = shift;
	my( @args ) = ( 'stcmd' );
	push( @args, 'co' );
	push( @args, '-nologo' );
	push( @args, join( '', '-p ', "\"", $self->_getpparam( ), "\"" ) );
	push( @args, '-q' ) unless $self->{'verbose'} == 0;
	push( @args, '-cmp' ) unless $self->{'compress'} == 0;
	push( @args, '-is' ) unless $self->{'recurse'} == 0;
	push( @args, '-x' ) unless $self->{'batchmode'} == 0;
	push( @args, '-stop' ) unless $self->{'stoponerror'} == 0;
	push( @args, @_ );
	$self->_runOrCroak( @args );
}

#
# checkin methods
#
sub checkin {
	# convenience method for calling _ci
	my( $self ) = shift;
	$self->_ci( @_ );	
}

sub ci {
	# convenience method for calling _ci
	my( $self ) = shift;
	$self->_ci( @_ );	
}

sub put {
	# convenience method for calling _ci
	my( $self ) = shift;
	$self->_ci( @_ );	
}

sub _ci {
	# run 'stcmd ci...'
	my( $self ) = shift;
	my( @args ) = ( 'stcmd' );
	push( @args, 'ci' );
	push( @args, '-nologo' );
	push( @args, join( '', '-p ', "\"", $self->_getpparam( ), "\"" ) );
	push( @args, '-q' ) unless $self->{'verbose'} == 0;
	push( @args, '-cmp' ) unless $self->{'compress'} == 0;
	push( @args, '-is' ) unless $self->{'recurse'} == 0;
	push( @args, '-x' ) unless $self->{'batchmode'} == 0;
	push( @args, '-stop' ) unless $self->{'stoponerror'} == 0;
	push( @args, @_ );
	$self->_runOrCroak( @args );
}

#
# diff methods
#
sub diff {
	# convenience method for calling _diff
	my( $self ) = shift;
	$self->_diff( @_ );	
}

sub vdiff {
	# convenience method for calling _diff
	my( $self ) = shift;
	$self->_diff( @_ );	
}

sub _diff {
	# run 'stcmd diff...'
	my( $self ) = shift;
	my( @args ) = ( 'stcmd' );
	push( @args, 'diff' );
	push( @args, '-nologo' );
	push( @args, join( '', '-p ', "\"", $self->_getpparam( ), "\"" ) );
	push( @args, '-q' ) unless $self->{'verbose'} == 0;
	push( @args, '-cmp' ) unless $self->{'compress'} == 0;
	push( @args, '-is' ) unless $self->{'recurse'} == 0;
	push( @args, '-x' ) unless $self->{'batchmode'} == 0;
	push( @args, '-stop' ) unless $self->{'stoponerror'} == 0;
	push( @args, @_ );
	$self->_runOrCroak( @args );
}

# --------------------------------------------------------------------------
# The standard way to run a system command and report on the result.
#
# I "borrowed" and modified this routine from Ron Savage's VCS::CVS module. 
#
sub _runOrCroak {
	my( $self, @args ) = @_;

	my( $verbose ) = $self->{'verbose'};
	
	my( $result ) = 0xffff & system( @args );

	print "Command: @args\n" unless $verbose == 0;

	if ( $result == 0 ) {
		print 'Success. ' unless $verbose == 0;
	} elsif ( $result == 0xff00 ) {
		warn "Failure: $!. ";
	} elsif ( $result > 0x80 ) {
		$result >>= 8;
		print "Exit status: $result. " unless $verbose == 0;
	} else {
		if ( $result & 0x80 ) {
			$result &= ~0x80;
			print 'Coredump from ';
		}

		print "Signal $result. ";
	}

	printf( "Result: %#04x\n", $result ) unless $verbose == 0;
	croak( "Failure: Can't run '@args'" ) if ( $result );

}	# End of runOrCroak.

1;
__END__

=head1 NAME

C<VCS::StarTeam> - Provide a simple interface to StarBase's StarTeam.

=head1 SYNOPSIS

	#!perl -w

	use strict;
  
	use VCS::StarTeam;
  
	$obj = VCS::StarTeam->new( { 
		batchmode		=> 0,
		compress		=> 0,
		host			=> 'localhost',
		endpoint		=> '1024',
		project			=> 'BigNewIdea',
		password		=> 'MyPassword',
		path			=> 'Source/MyIdea',
		recurse			=> 0,
		stoponerror		=> 0,
		username		=> 'StarTeamUser',
		verbose			=> 1,
		view			=> 'MyMainView',
	} );

	#
	# view the history of helloworld.c
	#
	$obj->hist( 'helloworld.c' );
	
	# OR
	
	$obj->history( 'helloworld.c' );
	
	# OR 
	
	$obj->log( 'helloworld.c' );
		
	#
	# list all the C source files in the current folder
	#
	$obj->list( '*.c' );	

	#
	# force the checkout of helloworld.c and lock it
	#
	$obj->checkout( '-o', '-l', 'helloworld.c' );

	# OR

	$obj->co( '-o', '-l', 'helloworld.c' );

	# OR

	$obj->get( '-o', '-l', 'helloworld.c' );

	#
	# checkin and unlock helloworld.c
	#
	$obj->checkin( '-u', "-r \"Cool changes\"", 'helloworld.c' );

	# OR

	$obj->ci( '-u', "-r \"Cool changes\"", 'helloworld.c' );

	# OR

	$obj->put( '-u', "-r \"Cool changes\"", 'helloworld.c' );

	#
	# compare revision 1 & 2 of helloworld.c
	#
	$obj->diff( '-vn 2', '-vn 1', 'helloworld.c'  );
	
	# OR
	
	$obj->vdiff( '-vn 2', '-vn 1', 'helloworld.c'  );
	
	#
	# N.B. the arguments may all be in one string, 
	# or separated by quotes.
	#
	$obj->co( '-o', '-l', 'helloworld.c' );
	
	# OR
	$obj->co( '-o -l helloworld.c' );				
	
	#
	# clean up
	#
	undef $obj;
	

=head1 DESCRIPTION

The C<VCS::StarTeam> module provides an OO interface to StarTeam.

=head1 INTERFACE

=head2 PUBLIC METHODS

=over 4

=item B<C<history>>

Convenience routine calls private method B<C<_hist>>

=item B<C<hist>>

Convenience routine calls private method B<C<_hist>>

=item B<C<log>>

Convenience routine calls private method B<C<_hist>>

=item B<C<list>>

Equivalent to issuing the command C<stcmd list...>. Pass options and file names as parameters.

=item B<C<checkout>>

Convenience routine calls private method B<C<_co>>

=item B<C<co>>

Convenience routine calls private method B<C<_co>>

=item B<C<get>>

Convenience routine calls private method B<C<_co>>

=item B<C<checkin>>

Convenience routine calls private method B<C<_ci>>

=item B<C<ci>>

Convenience routine calls private method B<C<_ci>>

=item B<C<put>>

Convenience routine calls private method B<C<_ci>>

=item B<C<diff>>

Convenience routine calls private method B<C<_diff>>

=item B<C<vdiff>>

Convenience routine calls private method B<C<_diff>>

=back

=head2 PRIVATE METHODS

=over 4

=item B<C<_hist>>

Equivalent to issuing the command C<stcmd hist I<[hist options]> I<files>>. Pass options and file names as parameters.

=item B<C<_ci>>

Equivalent to issuing the command C<stcmd ci I<[ci options]> I<files>>. Pass options and file names as parameters.

=item B<C<_co>>

Equivalent to issuing the command C<stcmd co I<[co options]> I<files>>. Pass options and file names as parameters.

=item B<C<_diff>>

Equivalent to issuing the command C<stcmd diff I<[diff options]> I<files>>. Pass options and file names as parameters.

=item B<C<_runOrCroak>>

The standard way to run a system command and report on the result.
I "borrowed" and modified this routine from Ron Savage's I<E<lt>rpsavage@ozemail.com.auE<gt>> C<VCS::CVS> module. It will honor the
'verbose' parameter.

=item B<C<_getpparam>>

Builds the '-p' argument string used in C<stcmd> commands.

=back

=head2 PROPERTIES

=over 4

=item B<C<batchmode>>

Boolean used to toggle between interactive and batch modes. If you do not set this parameter
to non-zero (TRUE) you must confirm error messages interactively. Default to B<0> (interactive mode).

=item B<C<compress>>

Compresses all the data sent between the workstation and StarTeam server and decompresses
it when it arrives. Useful for slow connections. Defaults to B<0> (off).

=item B<C<host>>

StarTeam server hostname. If omitted, B<C<host>> defaults to "localhost".

=item B<C<endpoint>>

StarTeam server endpoint (for example a port number or named pipe). 
If omitted, B<C<endpoint>> defaults to "1024". 

=item B<C<project>>

The StarTeam project name. You must always supply a project name.

=item B<C<password>>

StarTeam user's password. If omitted, the user will be prompted to enter the password.

=item B<C<path>>

Folder hierarchy. This can be omitted if the file is in the view's root folder.
The folder hierarchy should B<never> include the root folder. For example, if the
root folder of the view is C<BigNewIdea> and the hierarchy to your files is
C<BigNewIdea/SourceCode/Client>, use only C<SourceCode/Client> as the folder hierarchy.

=item B<C<recurse>>

If non-zero (TRUE), applies the command to child folders. Defaults to B<0> (off).

=item B<C<stoponerror>>

Often used in batch mode (see property B<C<batchmode>> above). If non-zero (TRUE)
will halt execution of the command when the first error is encountered. Defaults to B<0> (off).

=item B<C<username>>

The StarTeam user name. If omitted, the current user's logon name is used.

=item B<C<verbose>>

Boolean used to instruct the module to display or suppress progress reporting.
B<C<verbose>> defaults to B<0> (suppress progress reporting).

=item B<C<view>>

The StarTeam project view. If omitted, the root, or default, view is used.


=back

=head1 INSTALLATION

You install C<VCS::StarTeam>, as you would install any perl module library,
by running these commands:

	perl Makefile.PL
	make
	make test
	make install


=head1 AUTHOR

C<VCS::StarTeam> was written by Joe P. Hayes I<E<lt>jhayes@juicesoftware.comE<gt>> in 2001.

=head1 LICENSE

The C<VCS::StarTeam> module is Copyright (c) 2001 Joe P. Hayes.
All Rights Reserved.

You may distribute under the terms of either the GNU General Public License or the
Artistic License, as specified in the Perl README file.

=head1 SUPPORT / WARRANTY

The C<VCS::StarTeam> module is free software.

B<IT COMES WITHOUT WARRANTY OF ANY KIND.>

Commercial support for Perl can be arranged via The Perl Clinic.
For more details visit:

  http://www.perlclinic.com

=cut

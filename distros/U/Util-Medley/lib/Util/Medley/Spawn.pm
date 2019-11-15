package Util::Medley::Spawn;
$Util::Medley::Spawn::VERSION = '0.008';
###############################################################################

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Data::Printer alias => 'pdump';
use Carp;
use IPC::Run3 'run3';
use Kavorka '-all';

with 'Util::Medley::Roles::Attributes::Logger';

=head1 NAME

Util::Medley::Spawn - utility methods for system commands

=head1 VERSION

version 0.008

=head1 SYNOPSIS

...

=cut

###############################################################################

=head1 ATTRIBUTES

=head2 confessOnError (optional)

Toggle for to enable/disable confess on error.  Default is 1.

=cut

has confessOnError => (
	is      => 'rw',
	isa     => 'Bool',
	default => 1,
);

###############################################################################

=head1 METHODS

=head2 capture

Executes system command and returns the stdout, stderr, and exit values.  Will
write to log if enabled.

=over

=item usage:

 ($stdout, $stderr, $exit) = $util->capture($cmd, [$stdin])
 
 ($stdout, $stderr, $exit) = $util->capture(cmd   => $cmd, 
                                           [stdin => $stdin])
 
=item args:

=over

=item cmd [ArrayRef|Str]

System command to invoke.  Can be an arrayref or a string.

=item stdin [ArrayRef|Str] (optional)

Stdin to pass to the command.

=back

=back

=cut

multi method capture (ArrayRef|Str :$cmd!,
					  ArrayRef|Str :$stdin) {

	my $msg;
	if (ref($cmd) eq 'ARRAY') {
		$msg = join(' ', @$cmd);
	}
	else {
		$msg = $cmd;	
	}
	
	$self->Logger->verbose($msg);

	my ( $stdout, $stderr, $exit );
					 		
	my $rc = run3 $cmd, \$stdin, \$stdout, \$stderr;
	
	$exit = $? >> 8;
	if ( !$rc or $exit ) {
		if ( $self->confessOnError ) {
			my $msg =
			  sprintf
			  "run3 failed for cmd: exit=%s cmd='%s' stdout='%s' stderr='%s'",
			  $exit,
			  join( ' ', @$cmd ), $stdout, $stderr;
			  
			confess $msg;
		}
	}

	chomp $stdout;
	chomp $stderr;
		
	return ( $stdout, $stderr, $exit );
}

multi method capture (ArrayRef|Str $cmd,
					  ArrayRef|Str $stdin?) {
	
	my %a;
	$a{cmd} = $cmd;
	$a{stdin} = $stdin if $stdin;
	
	return $self->capture(%a);
}

					  					  	
=head2 spawn

Executes system command and returns the exit value.  Will write to log 
if enabled.

=over

=item usage:

 $exit = $util->spawn($cmd);

 $exit = $util->spawn(cmd => $cmd);
  
=item args:

=over

=item cmd [ArrayRef|Str]

System command to invoke.  Can be an arrayref or a string.

=back

=back

=cut

multi method spawn (ArrayRef|Str :$cmd!) {

	if ( ref($cmd) eq 'ARRAY' ) {
		$self->Logger->verbose( join( ' ', @$cmd ) );
		system(@$cmd);
	}
	else {
		$self->Logger->verbose($cmd);
		system($cmd);
	}

	my $exit = $? >> 8;
	if ($exit) {
		if ( $self->confessOnError ) {
			confess "last command failed with exit code $exit";
		}
	}

	return $exit;
}

multi method spawn (ArrayRef|Str $cmd) {

	return $self->spawn(cmd => $cmd);	
}

##############################################

1;

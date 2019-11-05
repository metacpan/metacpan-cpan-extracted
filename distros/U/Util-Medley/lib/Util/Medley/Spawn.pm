package Util::Medley::Spawn;
$Util::Medley::Spawn::VERSION = '0.007';
###############################################################################

use Modern::Perl;
use Moose;
use Method::Signatures;
use namespace::autoclean;

use Data::Printer alias => 'pdump';
use Carp;
use IPC::Run3 'run3';

with 'Util::Medley::Roles::Attributes::Logger';

=head1 NAME

Util::Medley::Spawn - utility methods for system commands

=head1 VERSION

version 0.007

=cut

###############################################################################

has confessOnError => (
	is      => 'rw',
	isa     => 'Bool',
	default => 1,
);

###############################################################################

method capture (Str|ArrayRef :$cmd!,
				Str          :$stdinAsString) {

	my @cmd;
	if ( ref($cmd) eq 'ARRAY' ) {
		@cmd = @$cmd;
	}
	else {
		@cmd = split( /\s+/, $cmd );
	}

	my ( $stdout, $stdin, $stderr, $exit );
	$stdin = $stdinAsString if $stdinAsString;
	
	$self->Logger->verbose( join( ' ', @cmd ) );
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

	return ( $stdout, $stderr, $exit );
}

method spawn (Str|ArrayRef :$cmd!) {

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

##############################################


1;

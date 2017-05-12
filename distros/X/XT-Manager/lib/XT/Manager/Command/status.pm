package XT::Manager::Command::status;

use 5.008003;
use strict;

BEGIN {
	$XT::Manager::Command::status::AUTHORITY = 'cpan:TOBYINK';
	$XT::Manager::Command::status::VERSION   = '0.006';
}

use base qw/XT::Manager::Command/;

sub abstract
{
	"compare local tests with the central collection"
}

sub command_names
{
	qw/status stat st/
}

sub description
{
	<<'DESCRIPTION'
The status symbols for each test case should be interpreted as:

	+  New file available to be pulled from repository
	U  Updated version available to be pulled from repository
	?  Local test case that is not in repository
	M  Local test case modified, and is different from repository

Whether test cases are identical, and which test case is newer, is judged
entirely by file modification time.
DESCRIPTION
}

sub execute
{
	my ($self, $opts, $args) = @_;
	my $repo  = $self->get_repository($opts);
	my $xtdir = $self->get_xtdir($opts);
	
	print $repo->compare($xtdir)->show($opts->{verbose});
}

sub opt_spec
{
	my $self = shift;
	return (
		[
			"verbose|v",
			"increase verbosity",
		],
		$self->SUPER::opt_spec(@_),
	);
}

__PACKAGE__
__END__

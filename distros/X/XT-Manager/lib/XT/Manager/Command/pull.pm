package XT::Manager::Command::pull;

use 5.008003;
use strict;

BEGIN {
	$XT::Manager::Command::pull::AUTHORITY = 'cpan:TOBYINK';
	$XT::Manager::Command::pull::VERSION   = '0.006';
}

use base qw/XT::Manager::Command/;

sub abstract
{
	"pull tests from the central collection (repository)"
}

sub execute
{
	my ($self, $opts, $args) = @_;
	my $repo  = $self->get_repository($opts);
	my $xtdir = $self->get_xtdir($opts);
	
	if ($opts->{all})
	{
		$args = [ $repo->compare($xtdir)->should_pull ];
	}
	
	foreach my $t ( @$args )
	{
		printf STDERR "pulling %s\n", $t;
		$xtdir->add_test( $repo->test($t) );
	}
}

sub opt_spec
{
	my $self = shift;
	return (
		[ "verbose|v",    "increase verbosity" ],
		[ "all|a",        "pull all changes from repository" ],
		$self->SUPER::opt_spec(@_),
	);
}

sub validate_args
{
	my ($self, $opts, $args) = @_;
	$self->usage_error("No arguments provided, and '--all' option not specified!") unless $opts->{all} || @$args;
}

__PACKAGE__
__END__

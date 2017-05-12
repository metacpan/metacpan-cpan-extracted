package XT::Manager::Command::push;

use 5.008003;
use strict;

BEGIN {
	$XT::Manager::Command::push::AUTHORITY = 'cpan:TOBYINK';
	$XT::Manager::Command::push::VERSION   = '0.006';
}

use base qw/XT::Manager::Command/;

sub abstract
{
	"push tests to the central collection"
}

sub execute
{
	my ($self, $opts, $args) = @_;
	my $repo  = $self->get_repository($opts);
	my $xtdir = $self->get_xtdir($opts);
	
	foreach my $t ( @$args )
	{
		printf STDERR "pushing %s\n", $t;
		$repo->add_test( $xtdir->test($t) );
	}
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

sub validate_args
{
	my ($self, $opts, $args) = @_;
	$self->usage_error("No arguments provided!") unless @$args;
}

__PACKAGE__
__END__

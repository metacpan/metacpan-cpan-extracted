package XUL::Node::Model::Value;

use strict;
use warnings;
use Carp;
use Aspect;

aspect Listenable =>
	(Change => call __PACKAGE__. '::STORE', value => 'FETCH');

sub new {
	my $class = shift;

	# when using attribute interface, 1st param is ref to undef
	shift if ref $_[0] and !defined ${$_[0]};
	my %params = defined $_[0]? @_: ();

	my $self = bless {}, $class;
	$self->value($params{value}) if exists $params{value};
	return $self;
}

sub value { @_ == 1? shift->FETCH: shift->STORE(pop) }

# scalar tie protocol ---------------------------------------------------------

sub TIESCALAR { shift->new(@_)       }
sub FETCH     { shift->{value}       }
sub STORE     { shift->{value} = pop }

1;

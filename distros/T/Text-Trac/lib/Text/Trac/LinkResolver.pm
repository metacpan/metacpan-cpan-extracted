package Text::Trac::LinkResolver;

use strict;
use warnings;
use List::MoreUtils qw( any );

our $VERSION = '0.18';

our @handlers = qw( changeset wiki report log ticket milestone source attachment comment );

sub new {
	my $class = shift;
	my $self = { context => shift };
	bless $self, $class;
	$self->init;
	return $self;
}

sub _is_disabled {
	my ( $self, $resolver ) = @_;
	( my $formatter = ref $self ) =~ s/.*:://;

	if ( @{ $self->{context}->{enable_links} } ) {
		return !any { lcfirst($formatter) eq $_ } @{ $self->{context}->{enable_links} };
	}

	return any { lcfirst($formatter) eq $_ } @{ $self->{context}->{disable_links} };
}
1;

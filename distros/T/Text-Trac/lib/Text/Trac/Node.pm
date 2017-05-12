package Text::Trac::Node;
use strict;
use warnings;
use base qw( Class::Accessor::Fast );

our $VERSION = '0.18';

sub init {
	my $self = shift;
	$self->{pattern} = '';
}

sub parse { die; }

sub html    { $_[0]->{html}; }
sub pattern { $_[0]->{pattern}; }

sub context {
	my $self = shift;
	$self->{context} = $_[0] if $_[0];
	$self->{context};
}

1;

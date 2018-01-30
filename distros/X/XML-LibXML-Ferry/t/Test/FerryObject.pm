use 5.006;
use strict;
use warnings;

package Test::FerryObject;

sub new {
	my ($class, $el) = @_;
	my $self = {
		_url   => undef,
		_email => undef,
		_nest  => undef,
	};
	return bless $self, $class;
};

sub email {
	my ($self, $val) = @_;
	$self->{_email} = $val;
};

sub url {
	my ($self, $val) = @_;
	$self->{_url} = $val;
};

sub nest {
	my ($self, $val) = @_;
	$self->{_nest} = $val;
};

1;

use 5.006;
use strict;
use warnings;

package Test::FerryObject2;

sub new {
	my ($class, $el) = @_;
	my $self = {
		_text  => undef,
	};
	bless $self, $class;

	if (defined $el) {
		$el->ferry($self, {
			__meta_name => 'kind',
			'foo' => {
				SubTwo => 'text',
			},
		});
		return undef unless defined $self->{_text};
	};
	return $self;
};

sub text {
	my ($self, $val) = @_;
	$self->{_text} = $val;
};

1;

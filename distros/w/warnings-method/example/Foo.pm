package
	Foo;

use Moose;

# requires BEGIN blocks for run-time definitions
BEGIN{
	has bar => (is => 'rw');
}

sub bar :method;

sub new :method{
	my $class = shift;
	$class->SUPER::new(@_);
}

1;

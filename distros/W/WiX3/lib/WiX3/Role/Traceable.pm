package WiX3::Role::Traceable;

use 5.008003;
use Moose::Role 2;
use WiX3::Trace::Object 0.011;

our $VERSION = '0.011';

sub get_tracelevel {
	my $self = shift;
	return WiX3::Trace::Object->instance()->get_tracelevel(@_);
}

sub set_tracelevel {
	my $self = shift;
	return WiX3::Trace::Object->instance()->set_tracelevel(@_);
}

sub get_testing {
	my $self = shift;
	return WiX3::Trace::Object->instance()->get_testing(@_);
}

sub trace_line {
	my $self = shift;
	return WiX3::Trace::Object->instance()->trace_line(@_);
}

sub push_tracelevel {
	my $self      = shift;
	my $new_level = shift;

	my $object = \do { WiX3::Trace::Object->instance()->get_tracelevel(); };
	bless $object, 'WiX3::Role::Traceable::Saver';

	WiX3::Trace::Object->instance()->set_tracelevel($new_level);

	return $object;
}

no Moose::Role;

sub WiX3::Role::Traceable::Saver::DESTROY {
	my $self = shift;
	WiX3::Trace::Object->instance()->set_tracelevel( ${$self} );
	return;
}

1;                                     # Magic true value required at end of module

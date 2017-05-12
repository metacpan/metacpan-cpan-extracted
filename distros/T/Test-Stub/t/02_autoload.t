use strict;
use warnings;
use Test::More tests => 8;

use Test::Stub qw(stub);

{
	package Tracker;

	use strict;
	use warnings;

	sub new {
		my ($class, @args) = @_;
		return bless [{args => [@args], method => 'new'}], $class;
	}
}

{
	package Tracker::WithAutoload;
	use strict;
	use warnings;
	our @ISA = qw(Tracker);

	sub AUTOLOAD {
		my ($self, @args) = @_;
		return if our $AUTOLOAD =~ /DESTROY/;
		my ($method) = $AUTOLOAD =~  m{.*:(.*)};
		push @$self, {args => [@args], method => $method};
		return $self;
	}
}

sub lame_try (&) {
	my $code = shift;
	local $@;
	eval { $code->() };
	return $@;
}

# If the class you're stubbing out can't perform the requested method, the resulting stubbed-out object can't either.
{
	my $tracker = Tracker->new;
	my $stub_tracker = stub($tracker);

	my $random_method = 'random_method_that_doesnt_exist';

	ok( ! UNIVERSAL::can($tracker, $random_method), "->$random_method is not available to \$tracker" );
	ok( ! UNIVERSAL::can($stub_tracker, $random_method), "->$random_method is not available to stub(\$tracker), either" );

	my $default_error = lame_try { $tracker->$random_method };
  my $expected = qr/Can't locate object method "$random_method" via package "Tracker"/;
	like( $default_error, $expected, 'calling an unimplemented method on $tracker results in an expected error' );

	my $got_error = lame_try { $stub_tracker->$random_method };
	like( $got_error, $expected, 'calling an unimplemented method on stub($tracker) results in an expected error' );
}

# Similar test block as above, but this time we're stubbing out a class that has an AUTOLOAD, so errors are different
{
	my $tracker = Tracker::WithAutoload->new;
	my $stub_tracker = stub($tracker);

	my $random_method = 'some_other_random_method_that_doesnt_exist';

	ok( ! UNIVERSAL::can($tracker, $random_method), "->$random_method is not available to \$tracker" );
	ok( ! UNIVERSAL::can($stub_tracker, $random_method), "->$random_method is not available to stub(\$tracker), either" );

	my $expected_error = lame_try { $tracker->$random_method };
	is( $expected_error, '', "no errors calling \$tracker->$random_method (handled by AUTOLOAD)" );

	my $got_error = lame_try { $stub_tracker->$random_method };
	is( $got_error, '', "no errors calling stub(\$tracker)->$random_method (handled by AUTOLOAD)" );
}

# This code crashed with version 2.0002 in perl 5.20.3.

use constant::lexical mech => 0;

sub send{
	my $error;
	sub {
		mech,
		$error
	};
}

# We would not even reach run time if there was a crash.
print "1..1\nok 1\n";

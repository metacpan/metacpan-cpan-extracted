use Test::More 'no_plan';

print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";
# use class
use_ok( 'perfSONAR_PS::Error' );

# you MUST import this, otherwise the try/catch block will fail
use Error qw( :try );

# try
try {
  throw perfSONAR_PS::Error "some error message";
}
# catch any error (perfSONAR_PS::Error subclasses it)
catch Error with {
	my $ex = shift;
	my $eventType = $ex->eventType();
#	print "EVENT: $eventType\n\n";
	ok( $ex->isa( 'perfSONAR_PS::Error' ), 'exception object' );
	ok( $eventType eq 'error', 'event type name' );
};


print "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";

1;
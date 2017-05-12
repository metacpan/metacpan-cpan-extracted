# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use VCS::StarTeam;
$loaded = 1;
print "ok 1\n\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test_num = 2;

eval {
	
 	$obj = VCS::StarTeam->new( {verbose => 1, project => 'Acropole', view => 'BETA1_MAINT_BRANCH', password => 'joeacro05', host => 'orange', endpoint => '49203'} );
 	$obj->hist( '*' );
 	undef $obj;
 	print "ok ", $test_num++, "\n\n";
 	
 	$obj = VCS::StarTeam->new( {verbose => 1, project => 'Acropole', view => 'BETA1_MAINT_BRANCH', password => 'joeacro05', host => 'orange', endpoint => '49203'} );
 	$obj->list( '*' );
 	undef $obj;
 	print "ok ", $test_num++, "\n\n";

 	$obj = VCS::StarTeam->new( {verbose => 1, project => 'Acropole', view => 'BETA1_MAINT_BRANCH', password => 'joeacro05', host => 'orange', endpoint => '49203'} );
 	$obj->co( '-l', '*' );
 	undef $obj;
 	print "ok ", $test_num++, "\n\n";

 	$obj = VCS::StarTeam->new( {verbose => 1, project => 'Acropole', view => 'BETA1_MAINT_BRANCH', password => 'joeacro05', host => 'orange', endpoint => '49203'} );
 	$obj->diff( '-vn 2', '-vn 1', '*'  );
 	undef $obj;
 	print "ok ", $test_num++, "\n\n";

};

if ( $@ ) {
	print "... error: $@\n\n";
}

BEGIN { $SIG{__WARN__} = sub {}; $| = 1; print "Tests 1..6 begining\n"; }
END {print "not ok 1\n" unless $loaded;}

# To avoid seeing/dying from this not
# being called with -T. Taint.pm will
# normally throw a warning.
eval 'use Untaint ';

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

sub report_result {
	my $ok = shift;
	$TEST_NUM ||= 2;
	print "not " unless ($ok || ($TEST_NUM==2 || $TEST_NUM==3));
	print "ok $TEST_NUM\n";
	print "@_\n" if (not $ok and $ENV{TEST_VERBOSE});
	$TEST_NUM++;
}

{
	
	# 2: Simple tainted array test
	&report_result(system('./untaint_array_t.pl', 'kevin kyla'), $! );

	# 3: Simple tainted scalar test
	&report_result(system('./untaint_scalar_t.pl kevin') , $! );

	# 4: If the array fails to untaint, this is good. 
	print qq(** This test will return error if it passes **\n);
	&report_result(system('./untaint_array_t.pl kevin kyla larry') , $! );
	
	# 5: If this fails, this is also good
	print qq(** This test will return error if it passes **\n);
	&report_result(system('./untaint_scalar_t.pl foobar'), $! );
	
	# 6: Testing a hash
	&report_result(system('./untaint_hash_t.pl kevin 27 m'), $!);
	
}

print "Test complete.\n";

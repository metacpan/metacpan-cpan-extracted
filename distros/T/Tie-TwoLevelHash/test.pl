
BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tie::TwoLevelHash;

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

sub report_result {
	my $ok = shift;
	$TEST_NUM ||= 2;
	print "not " unless $ok;
	print "ok $TEST_NUM\n";
	print "@_\n" if (not $ok and $ENV{TEST_VERBOSE});
	$TEST_NUM++;
}

my $file = "test.tlh";

#tie(%hash, 'Tie::TwoLevelHash', "$file, PEOPLE", 'rw');

{
	
	# 2: open a database
	&report_result(tie(%hash, 'Tie::TwoLevelHash', $file, 'rw'), $! );

	# 3: store a value
	&report_result($hash{TEST} = {TEST3 => "ok"} , $! );

	# 4: store a new hash 
	&report_result($hash{TEST2} = {TEST4 => "ok", TEST => "OK"} , $! );
	
	# Get ready for next section
	$hash{PEOPLE} = {TOTEST => "oK"};

	untie %hash;
	
	# 5: retie the hash
	&report_result(tie(%hash, 'Tie::TwoLevelHash', "$file, PEOPLE", 'rw'), $! );

	# 6: check the stored value
	&report_result($hash{TEST5} = "ok" , $!);

	# 7: check whether the empty key exists()
	&report_result(exists $hash{'TEST5'});

	# 8: set it to nothing
	&report_result(($hash{'TEST8'} = "") ne 1, $!);
	
	# 9: check whether the key exists()
	&report_result(exists $hash{'TEST5'});
	
	# 10: reset it
	$hash{'TEST5'} = "test";
	&report_result($hash{'TEST5'} = "test", $!);
	
	untie %hash;

	
}

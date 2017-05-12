# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..12\n"; }
END {print "not ok 1\n" unless $loaded;}
use XML::GXML;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my $testNum = 2; # first test ran above

use Cwd;
chdir('test');

# List of known sums. To add a test, add it to test/runalltests.pl to
# get the sum, and also update the '1..12' line above.
my %tests = ('addlattrs.pl'         => 12901,
			 'addltemplates.pl'     => 22533,
			 'callbacks.pl'         => 16170,
			 'callbacks2.pl'        => 10670,
			 'collector.pl'         => 17340,
			 'commands.pl'          => 105342,
			 'dashconvert.pl'       => 19502,
			 'htmlmode.pl'          => 53788,
			 'remapping.pl'         => 12054,
			 'variables.pl'         => 122899,
			 'varprocessors.pl'     => 14094,
			 );

foreach my $test (sort keys %tests)
{
	# Dump results to temp file
	system("perl $test > test.out") and die "Can't run test $test: $!";

	open(FILE, 'test.out');

	# Read the file line-by-line and chomp line endings to make sure
	# different platform endings don't interfere with the sum.
	my $file;
	while (my $line = <FILE>)
	{
		chomp($line);
		$file .= $line;
	}

	close(FILE);

	# Simple and stupid summing routine
	my $length = length($file);
	my $sum    = 0;
	for (my $i = 0; $i < $length; $i++)
	{
		$sum += ord(substr($file, i, 1));
	}

	# Compare sum to known value
	if ($sum == $tests{$test})
	{
		print "ok $testNum\n";
	}
	else
	{
		print "not ok $testNum\n";
	}
	$testNum++;
}


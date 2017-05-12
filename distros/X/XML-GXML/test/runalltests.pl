#!/usr/bin/perl

use Cwd;

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

	my $length = length($file);
	my $sum    = 0;
	for (my $i = 0; $i < $length; $i++)
	{
		$sum += ord(substr($file, i, 1));
	}

	if ($sum == $tests{$test})
	{
		print "Test $test passed (sum: $sum)\n";
	}
	else
	{
		print "XXX test $test failed (I saw $sum, should be " .
			$tests{$test} . ")\n";
	}
}

exit;


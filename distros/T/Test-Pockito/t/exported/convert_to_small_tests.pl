use warnings;
use strict;

my $x = -1;
my $fh = undef;

my $line;
my $header = undef;
my $header_complete = 0;
my $test = undef;

while( defined( my $_= <>) )
{
	if( $_=~/^{\s+$/ .. /^}\s+$/ )
        {
		if( !$header_complete )
		{
			$header =~s/tests => \d+//;
			$header_complete = 1;
		}
		$test .= $_;
        }
	elsif( !$header_complete ) {
		$header .= $_;
	}
	elsif( defined $test )
        {
		$x++;
		my $file = "test_$x.t";
                open($fh, "> $file");
                print $fh $header;
 		print $fh "\n";
		print $fh $test;
                print $fh "done_testing()\n";
		close($fh);
		undef $test;
        }
}

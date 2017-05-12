package Internal;

use 5.008;
use strict;
use warnings;

sub getCmdLine() {
	use Cwd 'abs_path';
	
	my @path = split '/', $0;
	pop @path; ## extract filename
	my $myPath = join '/', @path;
	$myPath = abs_path($myPath);
	
        my $run = ($^O eq 'MSWin32') ? 'run.bat' : 'run.sh';
	return "$myPath/../samples/$run echo";
}

1;
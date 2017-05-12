use inc::Module::Install 0.77;

all_from  'lib/Test/NeedsDisplay.pm';
requires  'File::Spec' => '0.80';
requires  'Test::More' => '0.47';

unless ( $^O eq 'MSWin32' or $ENV{DISPLAY} or $^X =~ /wxPerl/ ) { 
	if ( $^O eq 'darwin') {
		print STDERR 'Consider running as "wxPerl Makefile.PL" or "wxPerl -MCPAN -e shell"';
	} else {
		requires_external_bin 'xvfb-run';
	}
}

WriteAll;

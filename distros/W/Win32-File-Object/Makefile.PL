use inc::Module::Install 0.85;

foreach ( sort keys %ENV ) {
	print "\$ENV{$_} = '$ENV{$_}';\n";
}

# Abort unless we are on Win32 or in ADAMK's release automation
unless ( $^O eq 'MSWin32' or $^O eq 'cygwin' or $ENV{ADAMK_RELEASE} ) {
	print "Win32::File::Object is only applicable to Win32 and cygwin\n";
	exit(0);
}

all_from      'lib/Win32/File/Object.pm';
requires      'Win32::File'  => '0.05';
requires      'File::Spec'   => '0.80';
requires      'File::Remove' => '0.38';
test_requires 'Test::More'   => '0.42';

WriteAll;

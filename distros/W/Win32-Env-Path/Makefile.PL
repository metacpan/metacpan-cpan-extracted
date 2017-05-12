# Abort unless we are on Win32 or in ADAMK's release automation
unless ( $^O eq 'MSWin32' or $^O eq 'cygwin' or $ENV{ADAMK_RELEASE} ) {
	print "Win32::File::Object is only applicable to Win32 and cygwin\n";
	exit(0);
}

use inc::Module::Install::DSL 0.85;

all_from       lib/Win32/Env/Path.pm
requires       File::Spec         0.80
requires       Params::Util       0.10
requires       Win32::TieRegistry 0.03
test_requires  Test::More         0.47
test_requires  Test::Script       1.03
install_script win32envpath

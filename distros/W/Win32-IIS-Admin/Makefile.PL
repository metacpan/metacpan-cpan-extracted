
# $Id: Makefile.PL,v 1.7 2008/11/07 00:48:27 Martin Exp $

use inc::Module::Install;

all_from('lib/Win32/IIS/Admin.pm');

requires('Data::Dumper');
requires('File::Spec');
test_requires('IO::Capture::Stderr');
requires('IO::String');
test_requires('Test::Simple' => 0.44);
test_requires('Test::More');
recommends('Win32API::File');

WriteAll();

print STDERR <<WARNING;

Note: If environment variable RUN_DESTRUCTIVE_TESTS is set,
we will run some tests that actually change a few configuration values
in the IIS installation on the local machine.  The changes will be
undone after the tests are complete, but if anything goes wrong during
the test, your IIS configuration might be left in a corrupted state.

WARNING

__END__

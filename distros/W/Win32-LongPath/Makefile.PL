use Config;
use inc::Module::Install;
use Win32;

# determine build environment
my @vers = Win32::GetOSVersion ();
my $WinVer = sprintf ('0x%02x%02x', $vers [1], $vers [2]);
 
# metadata
name            'Win32-LongPath';
abstract        'Windows file functions that use very long paths and Unicode.';
author          'Robert Boisvert <rdbprog@gmail.com>';
version_from    'lib/Win32/LongPath.pm';
license         'perl';
requires        'Carp' => 0;
requires        'Encode' => 0;
requires        'Fcntl' => 0;
requires        'File::Spec::Functions' => 0;
requires        'Time::Local' => 0;
repository      'https://github.com/rdboisvert/Win32-LongPath';
bugtracker      'https://github.com/rdboisvert/Win32-LongPath/issues';
win32;

# XS
configure_requires
                'ExtUtils::ParseXS';
use_ppport 3.19;
cc_define       "-DWINVER=$WinVer -D_WIN32_WINNT=$WinVer";
cc_warnings;
cc_src_paths    'xs';
makemaker_args (
  LDDLFLAGS => "$Config{lddlflags} -static-libgcc -static-libstdc++"
);

# tests
tests           't/*.t';
test_requires   'Test::More' => 0;
test_requires   'Devel::Refcount' => 0;

# create Makefile
WriteAll;

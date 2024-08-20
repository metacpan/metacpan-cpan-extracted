# https://toby.ink/blog/2023/01/24/perl-testing-in-2023/
# loads all of my modules, or at least the important ones, then passes without
# any real testing being done. The purpose of this is to quickly check for 
# syntax errors so extreme that they prevent your code from even compiling. 
use 5.014;
use warnings;

use Test::More;

BEGIN {
  unless ( $^O eq 'MSWin32' ) {
    plan skip_all => 'This is not MSWin32';
  }
  else {
    plan tests => 8;
  }
}

use_ok 'Win32::Console::DotNet';
use_ok 'System';
use_ok 'Win32Native';
use_ok 'IO::DebugOutputTextWriter';
use_ok 'ConsoleColor';
use_ok 'ConsoleKey';
use_ok 'ConsoleKeyInfo';
use_ok 'ConsoleModifiers';

done_testing;

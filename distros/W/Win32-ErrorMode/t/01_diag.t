use strict;
use warnings;
use Test::More tests => 1;
use Win32::ErrorMode;

diag '';
diag '';
diag '';

diag "has real GetErrorMode = ", Win32::ErrorMode::_has_real_GetErrorMode();
diag "has thread variant    = ", Win32::ErrorMode::_has_thread();

diag '';
diag '';

pass 'good';

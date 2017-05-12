
use inc::Module::Install;

name 'Test-TCP-Multi';

all_from 'lib/Test/TCP/Multi.pm';

requires 'Test::SharedFork' => 0.11;
requires 'Storable';
requires 'Time::HiRes';

auto_set_repository;

WriteAll;

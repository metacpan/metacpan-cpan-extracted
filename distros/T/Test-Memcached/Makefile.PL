use inc::Module::Install;

name 'Test-Memcached';
all_from 'lib/Test/Memcached.pm';

requires 'IO::Socket::INET';
requires 'Class::Accessor::Lite';
requires 'Cwd';
requires 'File::Temp';
requires 'Time::HiRes';
test_requires 'Test::More' => '0.94';

author_tests 'xt';
WriteAll;
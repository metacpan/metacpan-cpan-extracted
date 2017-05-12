use inc::Module::Install;
name 'Test-FTP-Server';
all_from 'lib/Test/FTP/Server.pm';

requires 'Net::FTPServer';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More' => '0.88';
test_requires 'Test::TCP';
test_requires 'File::Copy::Recursive';

auto_set_repository;
auto_include;
WriteAll;

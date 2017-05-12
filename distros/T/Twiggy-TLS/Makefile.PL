use inc::Module::Install;

name 'Twiggy-TLS';
all_from 'lib/Twiggy/TLS.pm';

requires 'Twiggy' => '0.1010';
requires 'Plack'  => '0.99';
requires 'IO::Socket::SSL' => '1.62';

test_requires 'Test::More' => '0.88';
test_requires 'Test::TCP';
test_requires 'LWP::UserAgent'       => '6.00';
test_requires 'LWP::Protocol::https' => '6.02';
test_requires 'FindBin';

bugtracker 'https://github.com/und3f/Twiggy-TLS/issues';
repository 'https://github.com/und3f/Twiggy-TLS';

WriteAll;

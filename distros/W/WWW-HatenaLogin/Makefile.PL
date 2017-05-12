use inc::Module::Install;
name 'WWW-HatenaLogin';
all_from 'lib/WWW/HatenaLogin.pm';

requires $_ for (qw/
    Crypt::SSLeay
    URI
    WWW::Mechanize
/);

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;

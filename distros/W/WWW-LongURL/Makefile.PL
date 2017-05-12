use inc::Module::Install;

name     'WWW-LongURL';
author   q{Kevin Spencer <kspencer@cpan.org>};
license  'perl';
abstract 'Perl bindings to LongURL API';
perl_version '5.008008';
all_from 'lib/WWW/LongURL.pm';

test_requires 'Test::More';
test_requires 'LWP::Online';

requires 'Class::Accessor::Fast';
requires 'LWP::UserAgent';
requires 'JSON::Any';
requires 'URI::Escape';

auto_install;

WriteAll;

use inc::Module::Install;

name('WebService-Windows-LiveID-Auth');
author('Toru Yamaguchi <zigorou@cpan.org>');
version_from('lib/WebService/Windows/LiveID/Auth.pm');
abstract('Perl implementation of Windows Live ID Web Authentication 1.0');
license('perl');

requires('Carp::Clan');
requires('CGI');
requires('Class::Accessor::Fast');
requires('Crypt::Rijndael');
requires('DateTime');
requires('Digest::SHA');
requires('MIME::Base64');
requires('URI');
requires('URI::Escape');
requires('URI::QueryParam');

use_test_base;

auto_include;
auto_install;

WriteAll;

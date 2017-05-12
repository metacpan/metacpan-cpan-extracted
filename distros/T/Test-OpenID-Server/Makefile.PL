use inc::Module::Install 0.46;
use strict;
use warnings;

name('Test-OpenID-Server');
license('Perl');
version_from('lib/Test/OpenID/Server.pm');
author('Jesse Vincent <jesse@bestpractical.com>');
requires('Net::OpenID::Server');
requires('Test::OpenID::Consumer');
requires('Test::HTTP::Server::Simple');
requires('Test::WWW::Mechanize');
requires('HTTP::Server::Simple');
test_requires('Test::Warnings', '0.009');
auto_install();
WriteAll();

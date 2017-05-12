use inc::Module::Install 0.46;
use strict;
use warnings;

name('Test-OpenID-Consumer');
license('Perl');
version_from('lib/Test/OpenID/Consumer.pm');
readme_from('lib/Test/OpenID/Consumer.pm', { format => 'md' });
author('Thomas Sibley <trs@bestpractical.com>');
requires('Net::OpenID::Consumer');
requires('Test::HTTP::Server::Simple');
requires('HTTP::Server::Simple');
requires('LWP::UserAgent::Paranoid', '0.97');
requires('Cache::FileCache');
requires('Test::Builder');
auto_install();
WriteAll();

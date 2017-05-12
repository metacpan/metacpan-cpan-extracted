# $Id: Makefile.PL 1810 2005-03-16 22:48:49Z btrott $

use inc::Module::Install;

name('WWW-Blog-Metadata-Icon');
abstract('Extract icon URI (FOAF photo, favicon) from weblog');
author('Benjamin Trott <ben+cpan@stupidfool.org>');
version_from('lib/WWW/Blog/Metadata/Icon.pm');
license('perl');
no_index(directory => 't');
sign(1);

include('ExtUtils::AutoInstall');

requires('WWW::Blog::Metadata');
requires('XML::FOAF');
requires('URI');
requires('LWP::UserAgent');

auto_include();
auto_install();

&WriteAll;

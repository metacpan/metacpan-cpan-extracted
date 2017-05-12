use strict;
use warnings;
use inc::Module::Install;

name 'XRI-Resolution-Lite';
author 'Toru Yamaguchi <zigorou@cpan.org>';
all_from 'lib/XRI/Resolution/Lite.pm';
license 'perl';

requires 'parent';
requires 'Carp';
requires 'Class::Accessor::Fast';
requires 'HTTP::Request';
requires 'LWP::UserAgent';
requires 'URI';
requires 'XML::LibXML';
requires 'XML::LibXML::XPathContext';

use_test_base;

auto_include;
auto_install;

WriteAll;

use strict;
use warnings;
use inc::Module::Install;

name 'Test-WWW-Mechanize-Object';
author 'Hans Dieter Pearcey <hdp@cpan.org>';
all_from;

build_requires 'Test::More' => 0;

# no idea of the real version we need, this is the latest
# right now
requires 'Test::WWW::Mechanize' => '1.12';

requires 'URI' => 0;

WriteAll;

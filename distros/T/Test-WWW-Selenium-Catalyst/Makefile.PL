use strict;
use warnings;
use inc::Module::Install 0.91;
#use Module::Install::AuthorRequires;

name          'Test-WWW-Selenium-Catalyst';
perl_version  '5.008000';
all_from      'lib/Test/WWW/Selenium/Catalyst.pm';
license       'Perl';
requires(
	 'Alien::SeleniumRC' => 0,
	 'Catalyst::Runtime' => '5.9',
	 'Test::WWW::Selenium' => 0,
	 'Test::More' => 0,
	 'Catalyst::Utils' => 0,
);

test_requires 'IPC::Cmd' => '0.42';
test_requires 'Test::More' => '0.92';

#author_requires 'Test::Pod';
#author_requires 'Test::Pod::Coverage';

resources repository => 'git://git.shadowcat.co.uk/catagits/Test-WWW-Selenium-Catalyst.git';

WriteAll();

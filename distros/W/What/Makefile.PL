use inc::Module::Install;

name('What');
author('Toni Prug <toni@irational.org>');
abstract('Find out what services run, MTAs to start with');
license('gpl');
version_from('lib/What.pm');

build_requires(qw(
	   Test::More 0
           Test::Exception 0		  
));

requires(qw(
	Error 0
	Exception::Class 1.21
	Net::Cmd 0    
        IO::Socket::INET 0
));

auto_install;
WriteAll;

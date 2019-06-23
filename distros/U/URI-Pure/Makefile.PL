$| = 1;
use strict;
use warnings;
use ExtUtils::MakeMaker 6.48;

WriteMakefile(
    NAME              => 'URI::Pure',
    VERSION_FROM      => 'URI/Pure.pm', # finds $VERSION
	MIN_PERL_VERSION  => 5.016,
    PREREQ_PM         => {
		'Encode' => 0,
		'Net::IDN::Punycode' => 0,
	}, # e.g., Module::Name => 1.1
    test => {TESTS => 't.pl'},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'URI/Pure.pm', # retrieve abstract from module
       AUTHOR         => 'Nick Kostyria <kni@cpan.org>') : ()),
);

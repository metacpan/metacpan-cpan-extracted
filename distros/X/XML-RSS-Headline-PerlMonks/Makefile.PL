use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'XML::RSS::Headline::PerlMonks',
    VERSION_FROM      => 'lib/XML/RSS/Headline/PerlMonks.pm', # finds $VERSION
    PREREQ_PM         => { 
		'XML::RSS::Feed' => '0',
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/XML/RSS/Headline/PerlMonks.pm', # retrieve abstract from module
       AUTHOR         => 'Don Shanks <donshank@cpan.org>') : ()),
);

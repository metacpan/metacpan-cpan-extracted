use 5.00600;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Test::XML::Count',
    VERSION_FROM      => 'lib/Test/XML/Count.pm', # finds $VERSION
    LICENSE						=> 'perl',
    PREREQ_PM         => {
														'Test::Simple' => 0, 
														'XML::LibXML' => 1.00, 
												}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Test/XML/Count.pm', # retrieve abstract from module
       AUTHOR         => 'Adam J Kaplan <akaplan@cpan.org>') : ()),
);

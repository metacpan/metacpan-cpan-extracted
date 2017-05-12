use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WebService::Postcodeanywhere::BACS::REST',
    VERSION_FROM      => 'lib/WebService/Postcodeanywhere/BACS/REST.pm', # finds $VERSION
    PREREQ_PM         => {
			  Class::Data::Inheritable => 0.02,
			  XML::Twig => 3.1,
			 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
       (AUTHOR         => 'Aaron J Trevena <aaron@fsite.com>') : ()),
);

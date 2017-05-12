

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Weblogic::UserAdmin',
    VERSION_FROM => 'lib/Weblogic/UserAdmin.pm', # finds \$VERSION
    AUTHOR       => 'David Peters (David.Peters@EssentialEnergy.com.au)',
    ABSTRACT     => 'Administration Functions For Weblogic 8.1 Automated',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Test::Strict' => 0.01,
                     'Test::Distribution' => 0.01,
                     'WWW::Mechanize' => 1.66,
                     	
    				}
);

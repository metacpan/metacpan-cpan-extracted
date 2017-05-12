use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'XML::Atom::Syndication',
    'VERSION_FROM'	=> 'lib/XML/Atom/Syndication.pm',
    'PREREQ_PM'		=> { 
        XML::Elemental=>2.0, 
        MIME::Base64=>0,
        Class::ErrorHandler=>0,
        XML::Writer=>0.600,
        Test::More=>0
    }
);

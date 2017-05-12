use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'XML::RSS::Parser',
    'VERSION_FROM'	=> 'lib/XML/RSS/Parser.pm',
    'PREREQ_PM'		=> { XML::Elemental=>'2.0', Class::XPath=>1.4, Class::ErrorHandler=>0, Test::More=>0 }
);
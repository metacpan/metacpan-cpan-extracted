use ExtUtils::MakeMaker;
use 5.006;
WriteMakefile(
    NAME		=> 'XML::Filter::ExceptionLocator',
    VERSION_FROM	=> 'ExceptionLocator.pm',
    PREREQ_PM		=> {
                            'XML::SAX'   => 0,
                            'Test::More' => 0,
                            'XML::SAX::ExpatXS' => 1.01,
                           },
    ABSTRACT_FROM       => 'ExceptionLocator.pm',
    AUTHOR              => 'Sam Tregar <sam@tregar.com>',
);

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'WebService::Technorati',
    VERSION_FROM => 'lib/WebService/Technorati.pm', # finds $VERSION
    AUTHOR       => 'Ian Kallen (ikallen@technorati.com)',
    ABSTRACT     => '',
    PREREQ_PM    => {
                     'Exception::Class' => 1.19,
                     'XML::XPath' => 1.13,
                     'Test::Simple' => 0.44,
                    },
);

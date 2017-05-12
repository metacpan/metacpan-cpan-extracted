use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'XML::Filter::XSLT',
    VERSION_FROM   => 'lib/XML/Filter/XSLT.pm',
    PREREQ_PM      => {
        XML::SAX => 0.03, 
        XML::LibXSLT => 1.31,
        XML::SAX::Writer => 0.20,
    },
    ABSTRACT_FROM  => 'lib/XML/Filter/XSLT.pm',
    AUTHOR         => 'Matt Sergeant <matt@sergeant.org>',
);


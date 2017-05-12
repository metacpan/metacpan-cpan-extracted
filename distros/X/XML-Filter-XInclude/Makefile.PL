use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME' => 'XML::Filter::XInclude',
    'VERSION_FROM' => 'lib/XML/Filter/XInclude.pm',
    'PREREQ_PM' => { XML::SAX => 0.05 },
    'ABSTRACT_FROM' => 'lib/XML/Filter/XInclude.pm',
    'AUTHOR' => 'Matt Sergeant <matt@sergeant.org>',
);

use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME' => 'Text::WikiFormat::SAX',
    'VERSION_FROM' => 'lib/Text/WikiFormat/SAX.pm',
    'PREREQ_PM' => {XML::SAX => 0, XML::SAX::Writer => 0},
    'ABSTRACT_FROM' => 'lib/Text/WikiFormat/SAX.pm',
    'AUTHOR' => 'Matt Sergeant <matt@sergeant.org>',
);

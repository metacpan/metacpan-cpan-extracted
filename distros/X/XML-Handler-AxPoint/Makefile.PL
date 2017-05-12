use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME' => 'XML::Handler::AxPoint',
    'VERSION_FROM' => 'lib/XML/Handler/AxPoint.pm',
    'PREREQ_PM' => {
        'PDFLib' => 0.14,
    	'XML::SAX' => 0.09,
    	'XML::SAX::Writer' => 0.39,
        'Time::Piece' => 1.08,
        'Text::Iconv' => 0,
    },
    EXE_FILES => [ 'scripts/axpoint' ],
    'ABSTRACT_FROM' => 'lib/XML/Handler/AxPoint.pm',
    'AUTHOR' => 'Matt Sergeant <matt@sergeant.org>',
);

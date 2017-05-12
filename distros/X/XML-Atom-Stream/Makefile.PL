use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'XML::Atom::Stream',
    'VERSION_FROM' => 'lib/XML/Atom/Stream.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
        LWP => 5.0,
        XML::SAX => 0.12,
        XML::Handler::Trees => 0.02,
        XML::Atom => 0.20,
        XML::LibXML::SAX => '1.00',
    },
);

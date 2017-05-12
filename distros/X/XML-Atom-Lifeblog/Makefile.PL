use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'XML::Atom::Lifeblog',
    'VERSION_FROM' => 'lib/XML/Atom/Lifeblog.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	MIME::Types => 0,
	XML::Atom => 0.11,
        File::Type => 0,
    },
);

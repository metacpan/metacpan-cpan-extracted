use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'WebService::ChangesXml',
    'VERSION_FROM' => 'lib/WebService/ChangesXml.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	XML::Simple => 2.08,
        HTTP::Date => 0,
        LWP::UserAgent => 0,
    },
);

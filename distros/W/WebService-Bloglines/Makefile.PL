use ExtUtils::MakeMaker;
use 5.8.1;
WriteMakefile(
    'NAME'      => 'WebService::Bloglines',
    'VERSION_FROM' => 'lib/WebService/Bloglines.pm', # finds $VERSION
    'PREREQ_PM' => {
        Encode => 2.10,
	Test::More => 0.32,
	LWP => 0,
	XML::RSS::LibXML => 0.09,
        XML::Liberal => 0.02,
    },
);

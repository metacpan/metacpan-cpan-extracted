use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'WWW::Blog::Metadata::OpenSearch',
    'VERSION_FROM' => 'lib/WWW/Blog/Metadata/OpenSearch.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
    },
);

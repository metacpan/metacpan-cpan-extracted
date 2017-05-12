use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'WWW::Blog::Metadata::MobileLinkDiscovery',
    'VERSION_FROM' => 'lib/WWW/Blog/Metadata/MobileLinkDiscovery.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
        WWW::Blog::Metadata => 0.02,
    },
);

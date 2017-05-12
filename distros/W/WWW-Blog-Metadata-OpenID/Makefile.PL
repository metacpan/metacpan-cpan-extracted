use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'WWW::Blog::Metadata::OpenID',
    'VERSION_FROM' => 'lib/WWW/Blog/Metadata/OpenID.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
        WWW::Blog::Metadata => 0.02,
    },
);

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'WWW::Mediawiki::Client',
    VERSION_FROM    => 'lib/WWW/Mediawiki/Client.pm',
    EXE_FILES       => ['bin/mvs'],
    PREREQ_PM       => 
        { 
            'Test::Differences'=> 0,
            'VCS::Lite' => 0,
            'Getopt::Std'=> 0,
            'Pod::Usage' => 0,
            'File::Spec' => 0,
            'File::Find' => 0,
            'Bundle::LWP' => 1.11,
            'HTML::TokeParser' => 0,
            'HTTP::Message' => 1.56,
            'HTTP::Request' => 1.40,
            'HTTP::Request::Common' => 1.26,
            'HTTP::Cookies' => 0,
            'XML::LibXML' => 0,
            'URI' => 1.31,
            'Carp' => 0,
            'Data::Dumper' => 0,
            'Exception::Class' => 0,
            'Encode' => 1.75,
            'Encode::Guess' => 0,
        },
);


use 5.010;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'WWW::Google::Translate',
    VERSION_FROM => 'lib/WWW/Google/Translate.pm',
    PREREQ_PM    => {
        'URI'            => '1.56',
        'JSON'           => '2.27',
        'Readonly'       => '1.03',
        'Storable'       => 0,
        'HTTP::Status'   => 0,
        'Data::Dumper'   => '2.128',
        'Sys::Hostname'  => 0,
        'LWP::UserAgent' => '5.835',
    },
    (
        $] >= 5.005
        ? (
            ABSTRACT_FROM => 'lib/WWW/Google/Translate.pod',
            AUTHOR        => 'Dylan Doxey <dylan@cpan.org>'
            )
        : ()
    ),
);

use 5.010;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'WWW::Google::Translate',
    VERSION_FROM => 'lib/WWW/Google/Translate.pm',
    PREREQ_PM    => {
        'JSON'           => '2.27',
        'LWP::UserAgent' => '5.835',
        'URI'            => '1.56',
        'Readonly'       => '1.03',
        'HTTP::Status'   => 0,
        'Sys::Hostname'  => 0,
        'File::Spec'     => 0,
        'Data::Dumper'   => '2.128',
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

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Test::HTTP',
    ABSTRACT     => 'Testing for HTTP services',
    AUTHOR       => 'Socialtext <socialtext@socialtext.com>',
    VERSION_FROM => 'lib/Test/HTTP.pm',
    PREREQ_PM    => {
        Test::Builder::Module => 0,
        Carp                  => 0,
        Class::Field          => 0,
        LWP                   => '5.827',
        LWP::UserAgent        => 0,
        Test::More            => 0,
        Text::Balanced        => 0,
        Filter::Simple        => 0,
        Encode                => 0,
    },
);

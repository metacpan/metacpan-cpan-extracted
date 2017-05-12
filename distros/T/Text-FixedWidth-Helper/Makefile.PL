use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Text::FixedWidth::Helper',
    VERSION_FROM => 'lib/Text/FixedWidth/Helper.pm',
    AUTHOR       => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT     => 'Create or verify samples of fixed-width data',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Carp' => 0,
                     'Cwd' => 0,
                     'IO::File' => 0,
                     'Scalar::Util' => 0, # verify
                     'IO::CaptureOutput' => 0, # for testing only
                    },
    LICENSE     => 'perl',
);

use ExtUtils::MakeMaker;
require 5.006;

my $mm_ver = ExtUtils::MakeMaker->VERSION;

WriteMakefile(
    NAME            => 'Text::CSV::Hashify',
    VERSION_FROM    => 'lib/Text/CSV/Hashify.pm',
    AUTHOR          => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT        => 'Turn a CSV file into a Perl hash',
    PREREQ_PM       =>  {
                        'Text::CSV' => 0,
                        },
    ( $mm_ver < 6.63_03 ? 'BUILD_REQUIRES' : 'TEST_REQUIRES' )
                    =>  {
                            'Test::Simple' => 0.44,
                        },
    ($mm_ver < 6.46 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            homepage => 'http://thenceforward.net/perl/modules/Text-CSV-Hashify/',
            repository => {
                url => 'https://github.com/jkeenan/text-csv-hashify.git',
                web => 'https://github.com/jkeenan/text-csv-hashify',
                type => 'git',
            },
            bugtracker => {
                web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Text-CSV-Hashify',
            },
        },
    })),
);

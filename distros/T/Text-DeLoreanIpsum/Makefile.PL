use 5.018002;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME            => 'Text::DeLoreanIpsum',
    VERSION_FROM    => 'lib/Text/DeLoreanIpsum.pm',
    ABSTRACT_FROM   => 'lib/Text/DeLoreanIpsum.pm',
    AUTHOR          => 'Mariano Spadaccini (marianos)',
    LICENSE         => 'perl',
    PREREQ_PM     => {
        'List::MoreUtils'   => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'git@github.com/spadacciniweb/Text-DeLoreanIpsum.git',
                web  => 'https://github.com/spadacciniweb/Text-DeLoreanIpsum',
            },
            bugtracker => {
                web => 'https://github.com/spadacciniweb/Text-DeLoreanIpsum/issues'
            },
            homepage   => 'https://one2zero.it/',
        },
    },
);

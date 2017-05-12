use ExtUtils::MakeMaker;
my $mm_ver = ExtUtils::MakeMaker->VERSION;

WriteMakefile (
    NAME        => 'asterisk-perl',
    AUTHOR        => 'James Golovich <james@gnuinter.net>',
    VERSION_FROM    => 'lib/Asterisk.pm',
    ABSTRACT    => 'Asterisk Perl Interface',
    PREREQ_PM    => {
        'IO::Socket' => 0, 
        'Digest::MD5' => 0,
        'Net::Telnet' => 0
    },
    ($mm_ver < 6.46 ? () : (META_MERGE => {
        'meta-spec' => { version => 2},
        dynamic_config => 1,
        resources => {
            repository => {
                type => 'git',
                url  =>  'https://github.com/asterisk-perl/asterisk-perl.git',
                web  =>  'https://github.com/asterisk-perl/asterisk-perl'
            },
        },
    })),
);

1;

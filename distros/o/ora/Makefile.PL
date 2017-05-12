use ExtUtils::MakeMaker;
WriteMakefile
(
    NAME => 'Bio::ORA',
    AUTHOR => 'Michaël Bekaert (michael.bekaert@stir.ac.uk)',
    ABSTRACT => 'Olfactory Receptor family Assigner (bioperl module)',
    LICENSE => 'gpl_3',
    PL_FILES => {},
    INSTALLDIRS => 'site',
    EXE_FILES => [
        'scripts/or.fasta',
        'scripts/or.hmm',
        'scripts/or.hmm.h3f',
        'scripts/or.hmm.h3i',
        'scripts/or.hmm.h3m',
        'scripts/or.hmm.h3p',
        'scripts/or.pl',
    ],
    VERSION_FROM => 'lib/Bio/ORA.pm',
    PREREQ_PM => {
        'Getopt::Long' => 0,
        'IO::File' => 0,
        'File::Temp' => 0,
        'File::Basename' => 0,
        'Bio::Root::Version' => 0,
        'Cwd' => 0,
    },
    META_MERGE => {
        resources => {
            repository  => {
                url  => 'git://github.com/pseudogene/ora.git',
                web  => 'https://github.com/pseudogene/ora',
                type => 'git',
            },
        }, 
    },
);

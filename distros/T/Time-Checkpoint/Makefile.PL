use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'      => 'Time::Checkpoint',
    'PREREQ_PM'     => {
        'Params::Validate' => 0,
        'Test::More'       => 0,
    },
    'dist' => { 
        'COMPRESS' => 'gzip -9f',
        'SUFFIX' => 'gz',
    },
    'VERSION'  => '0.36',
    'AUTHOR'   => 'Jane A. Avriette (jane@cpan.org)',
    'ABSTRACT' => 'Time-based checkpoints / deltas',
);


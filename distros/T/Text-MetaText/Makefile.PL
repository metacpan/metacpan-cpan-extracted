use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Text::MetaText',
    'VERSION_FROM' => 'MetaText.pm', 
    'EXE_FILES'    => [ 'bin/metapage' ],
    'PMLIBDIRS'    => [ 'MetaText' ],
    'PREREQ_PM'    => { 'Date::Format' => 0, 'File::Recurse' => 0 },
    'dist'         => { 
	'COMPRESS' => 'gzip', 
	'SUFFIX'   => 'gz',
    },
);


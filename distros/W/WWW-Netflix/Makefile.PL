use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		   => 'WWW::Netflix',
    'LICENSE'      => 'perl',
    'VERSION_FROM' => 'lib/WWW/Netflix.pm',
    'PREREQ_PM'    => {
		'WWW::Mechanize' => 0.59,
        'YAML'           => 0.66,
        'Net::SSL'       => 2.84,
	}, 
    'EXE_FILES'    => [ 'netflix_mover' ],
    ($] >= 5.006 ? ( AUTHOR => 'Christie Robertson and Colin Meyer <pants@helvella.org>') : ()),
);

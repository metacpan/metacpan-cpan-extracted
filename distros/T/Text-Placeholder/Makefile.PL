use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'Text::Placeholder',
	'VERSION_FROM'  => 'lib/Text/Placeholder.pm',
	'AUTHOR'	=> 'Winfried Trumper <pub+perl@wt.tuxomania.net>',
	'LICENSE'	=> 'perl',
	'PREREQ_PM'	  => {
		'Object::By' => '0.01'
	},
);

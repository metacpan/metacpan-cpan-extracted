use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Test::Nightly',
    'VERSION_FROM'  => 'lib/Test/Nightly.pm', 
    'PREREQ_PM'     => {
		'Carp'						=> '1.02',
		'Class::Accessor::Chained'	=> 0.01,
		'DateTime'					=> 0.28,
		'Email::Send'				=> 1.46,
		'Email::Simple'				=> 1.92, 
		'Email::Simple::Creator'	=> 1.4, 
		'File::Find::Rule'			=> 0.26,
		'File::Spec'				=> 0.82,
		'List::Util'				=> 1.17,
        'Template' 					=> 1.4,
		'Test::Harness::Straps'		=> 0.23,
		'Test::More'				=> 0.54,
    },
);

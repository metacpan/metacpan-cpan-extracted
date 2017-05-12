
use ExtUtils::MakeMaker;

WriteMakefile( 
	'VERSION_FROM' => 'lib/Pod/Simple/Wiki/Twiki/Upload.pm',
	'NAME' => 'Twiki-Upload',
	($] >= 5.005 ?
	('ABSTRACT' => "Upload POD to Twiki",
	'AUTHOR'   => 'David Muir Sharnoff <muir@idiom.org>') : ()),
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	'PREREQ_PM' => {
		'Data::Dumper'		=> 0,
		'File::Find'		=> 0,
		'File::Spec'		=> 0,
		'IO::File'		=> 0,
		'File::Slurp'		=> 0,
		'Pod::Html'		=> 0,
		'File::Path'		=> 0,
		'Pod::Simple::Wiki'	=> 0,
		'WWW::TWikiClient'	=> 0,
		'IO::Scalar'		=> 0,
	},
);


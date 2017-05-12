use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'XML::XSPF',
	VERSION_FROM      => 'lib/XML/XSPF.pm', # finds $VERSION
	PREREQ_PM         => {
		'Class::Accessor' => '0.20',
		'Date::Parse'     => '2.20',
		'HTML::Entities'  => '1.30',
		'XML::Parser'     => '2.30',
		'XML::Writer'     => '0.600',
	},
	($] >= 5.005 ?     ## Add these new keywords supported since 5.005
	(ABSTRACT_FROM  => 'lib/XML/XSPF.pm', # retrieve abstract from module
	AUTHOR         => 'Dan Sully <dan | at | slimdevices.com>') : ()),
);

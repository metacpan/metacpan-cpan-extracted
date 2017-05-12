use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'         => 'WebService::Upcoming',
	'VERSION_FROM' => 'Upcoming.pm',
	'PREREQ_PM'	   =>
	 {
		'LWP::UserAgent'      => 0,
		'HTTP::Request'       => 0,
		'HTTP::Response'      => 0,
		'URI'                 => 0
	 });

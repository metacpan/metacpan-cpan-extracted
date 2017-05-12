use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=>	'XPanel',
	VERSION_FROM	=>	'lib/XPanel.pm',
	PREREQ_PM		=>	{
							'CGI::Session' => 0, 
							'File::Type' => 0, 
							'Digest::MD5'=> 0,
							'Test::More' => 0,
							'HTML::Template' => 0,
							'Geo::IP::PurePerl' => 0,
						},
	ABSTRACT		=>	'xpanel.com',
	AUTHOR			=>	'Lilian Rudenco <xpanel@cpan.org>',
);

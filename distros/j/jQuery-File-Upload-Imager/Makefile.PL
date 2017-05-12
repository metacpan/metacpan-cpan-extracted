use 5.006;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile
(
	NAME               => 'jQuery::File::Upload::Imager',
	AUTHOR             => q{Adam Hopkins <srchulo@cpan.org>},
	VERSION_FROM       => 'lib/jQuery/File/Upload/Imager.pm',
	ABSTRACT           => 'Server-side solution for blueimp jQuery file upload plugin',
	LICENSE            => 'Artistic_2_0',
	PL_FILES           => {},
	MIN_PERL_VERSION   => 5.006,
	CONFIGURE_REQUIRES =>
	{
		ExtUtils::MakeMaker => 0,
	},
	BUILD_REQUIRES =>
	{
		Test::More => 0,
	},
	PREREQ_PM =>
	{
		CGI             => 3.63,
		Cwd             => 0,
		Digest::MD5     => 2.52,
		Imager          => 0.96,
		JSON::XS        => 2.34,
		Net::SSH2       => 0.48,
		Net::SSH2::SFTP => undef,
		strict          => 0,
		URI             => 1.60,
		warnings        => 0,
	},
	dist  =>
	{
		COMPRESS => 'gzip -9f',
		SUFFIX   => 'gz',
	},
	clean =>
	{
		FILES => 'jQuery-File-Upload-Imager-*',
	},
);

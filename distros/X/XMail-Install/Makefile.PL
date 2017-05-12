use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
	($] ge '5.005') ?
	(
		'AUTHOR' => 'Ron Savage (ron@savage.net.au)',
		'ABSTRACT' => 'A module to install the MS Windows mail server XMail',
    ) : (),
	clean			=>
	{
		FILES		=> 'blib/* Makefile MANIFEST XMail-Install-*'
	},
	dist			=>
	{
		COMPRESS	=> 'gzip',
		SUFFIX		=> 'gz'
	},
	DISTNAME		=> 'XMail-Install',
	NAME			=> 'XMail::Install',
	PL_FILES		=> {},
	PREREQ_PM		=>
	{
		Carp					=> 0,
		Email::Send				=> 0,
		File::Copy				=> 0,
		File::Copy::Recursive	=> 0,
		File::Path				=> 0,
		Mail::POP3Client		=> 0,
		Path::Class				=> 0,
		Test::More				=> 0,
		Test::Pod				=> 0,
		Win32					=> 0,
		Win32::Process			=> 0,
		Win32::Process::List	=> 0,
		Win32::Service			=> 0,
		Win32::TieRegistry		=> 0,
	},
	VERSION_FROM	=> 'lib/XMail/Install.pm',
);

use 5.006006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'WebService::Thumbalizr',
    VERSION_FROM      => 'lib/WebService/Thumbalizr.pm', # finds $VERSION
    PREREQ_PM         => {
		URI::Escape		=> 0,
		Text::Trim		=> 0,
		LWP::UserAgent		=> 0,
		LWP::Protocol::https	=> 0,
		IO::Socket::SSL		=> 0,
		Digest::MD5		=> 0,
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WebService/Thumbalizr.pm', # retrieve abstract from module
       AUTHOR         => 'Julien Sobrier <jsobrier@thumbalizr.com>') : ()),
);

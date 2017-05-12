use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'WWW::BookBot',
    'VERSION_FROM'	=> 'BookBot.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			Encode,
			File::Basename,
			File::Spec::Functions,
			File::Path,
			Fcntl,
    		LWP::UserAgent,
			HTTP::Request::Common,
			HTTP::Response,
			HTTP::Cookies,
			HTTP::Date,
			URI,
    		Carp,
    		Data::Dumper,
    		POSIX,
    		Getopt::Long,
    	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'BookBot.pm', # retrieve abstract from module
       AUTHOR     => 'Qing-Jie Zhou <qjzhou@hotmail.com>') : ()),
);

use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::Geni',
    VERSION_FROM      => 'lib/WWW/Geni.pm', # finds $VERSION
    PREREQ_PM         => {
		HTTP::Cookies => undef,
		HTTP::Response => undef,
		LWP::UserAgent => undef,
		JSON => undef
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Geni.pm', # retrieve abstract from module
       AUTHOR         => 'Erin Spiceland <erin@thespicelands.com>') : ()),
);

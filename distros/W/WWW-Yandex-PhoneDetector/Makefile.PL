use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::Yandex::PhoneDetector',
    VERSION_FROM      => 'lib/WWW/Yandex/PhoneDetector.pm', # finds $VERSION
    PREREQ_PM         =>  {
		'LWP::UserAgent'=>0,
		'XML::LibXML'=>0,
		'URI::Escape'=>0,
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Yandex/PhoneDetector.pm', # retrieve abstract from module
       AUTHOR         => 'Kostya Ten <kostya@yandex.ru>') : ()),
);

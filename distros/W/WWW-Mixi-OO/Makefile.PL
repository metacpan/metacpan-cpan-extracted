use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::Mixi::OO',
    VERSION_FROM      => 'lib/WWW/Mixi/OO.pm', # finds $VERSION
    PREREQ_PM         => {
#	LWP::RobotUA => 0,
	LWP::UserAgent => 0,
	Hash::Case::Preserve => 0,
	Class::Accessor::Fast => 0,
	HTML::Parser => 0,
    }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM  => 'lib/WWW/Mixi/OO.pm', # retrieve abstract from module
    AUTHOR         => 'Topia <topia@clovery.jp>',
    (MM->can('signature_target') ? (SIGN => 1) : ()),
);

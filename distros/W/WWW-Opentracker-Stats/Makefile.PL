use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::Opentracker::Stats',
    VERSION_FROM      => 'lib/WWW/Opentracker/Stats.pm', # finds $VERSION
    PREREQ_PM         => {
        'parent'                    => 0,
        'Bit::Vector'               => 0,
        'Carp'                      => 0,
        'Class::Accessor::Fast'     => 0,
        'Class::Data::Inheritable'  => 0,
        'Convert::Bencode'          => 0,
        'LWP::UserAgent'            => 0,
        'Params::Validate'          => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Opentracker/Stats.pm', # retrieve abstract from module
       AUTHOR         => 'Knut-Olav Hoven <knutolav@gmail.com>') : ()),
);

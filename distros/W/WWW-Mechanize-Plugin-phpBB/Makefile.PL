use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::Mechanize::Plugin::phpBB',
    VERSION_FROM      => 'lib/WWW/Mechanize/Plugin/phpBB.pm', # finds $VERSION
    PREREQ_PM         => {
        WWW::Mechanize            => 0,
        WWW::Mechanize::Pluggable => 0.10,
        Module::Pluggable         => 0,
        HTML::TreeBuilder         => 0,
        Log::Log4perl             => 1.0,
        Class::Accessor           => 0.19,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Mechanize/Plugin/phpBB.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Schilli <mschilli@ms.com>') : ()),
);

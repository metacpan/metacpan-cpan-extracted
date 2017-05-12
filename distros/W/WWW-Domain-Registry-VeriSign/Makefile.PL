use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::Domain::Registry::VeriSign',
    VERSION_FROM      => 'lib/WWW/Domain/Registry/VeriSign.pm', # finds $VERSION
    PREREQ_PM         => {
                          Test::More => 0.62,
                          WWW::Mechanize => 0,
                          Class::Accessor => 0,
                      }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/Domain/Registry/VeriSign.pm', # retrieve abstract from module
       AUTHOR         => 'Masahito Yoshida <masahito@cpan.org>') : ()),
);

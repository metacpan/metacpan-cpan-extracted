use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WebService::BuzzurlAPI',
    VERSION_FROM      => 'lib/WebService/BuzzurlAPI.pm', # finds $VERSION
    PREREQ_PM         => {
                          "Class::Accessor"    => 0.25,
                          "JSON::Syck"         => 0.21,
                          "LWP::UserAgent"     => 2.032,
                          "Readonly"           => 1.01,
                          "UNIVERSAL::require" => 0.10,
                        }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WebService/BuzzurlAPI.pm', # retrieve abstract from module
       AUTHOR         => 'Akira Horimoto <kurt0027@gmail.com>') : ()),
);

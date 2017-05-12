use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::LastFMAPI',
    VERSION_FROM      => 'lib/Net/LastFMAPI.pm', # finds $VERSION
    PREREQ_PM         => {
        map { $_ => 0 } qw{
LWP::UserAgent
  Digest::MD5
    JSON::XS
    YAML::Syck
      File::Slurp
        File::Path
	  File::HomeDir }
        }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/LastFMAPI.pm', # retrieve abstract from module
       AUTHOR         => 'Steev Eeeriumn <drsteve@cpan.org>') : ()),
);

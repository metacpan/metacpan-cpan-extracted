use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Wx::Perl::DataWalker',
    VERSION_FROM      => 'lib/Wx/Perl/DataWalker.pm', # finds $VERSION
    PREREQ_PM         => {
      'Wx' => '0.88',
      'YAML::XS' => '0.32',
      'Scalar::Util' => '0',
      'Devel::Size' => '0.71',
      'Class::XSAccessor' => '0.06',
    }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM  => 'lib/Wx/Perl/DataWalker.pm', # retrieve abstract from module
    AUTHOR         => 'Steffen Mueller <smueller@cpan.org>',
);

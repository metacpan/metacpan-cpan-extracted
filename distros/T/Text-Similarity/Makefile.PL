use 5.006;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my @programs = qw(text_similarity.pl);

WriteMakefile(
    NAME              => 'Text::Similarity',
    VERSION_FROM      => 'lib/Text/Similarity.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    EXE_FILES         => [map "bin/$_", @programs],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Text/Similarity.pm', # retrieve abstract from module
       AUTHOR         => 'Ted Pedersen <tpederse at d.umn.edu>') : ()),
   # allows make dist to create .tar.gz with correct name/version
   'dist'             => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'},
   # allows for automatic creation of META.yml
   ($ExtUtils::MakeMaker::VERSION ge '6.30_00'?
   ('LICENSE' => 'gpl', ) : ()),
);

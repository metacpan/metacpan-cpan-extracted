use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Test::Mock::Simple',
    VERSION_FROM      => 'lib/Test/Mock/Simple.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Test/Mock/Simple.pm', # retrieve abstract from module
       AUTHOR         => 'Erik Tank <tank@jundy.com>') : ()),
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'  => 'perl', ) : ()),
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
    'meta-spec' => { version => 2 },
     resources => {
         repository => {
             type => 'git',
             url  => 'https://github.com/skeletonkey/TestMockSimple.git',
             web  => 'https://github.com/skeletonkey/TestMockSimple',
         },
     }})
     : ()
    ),
);

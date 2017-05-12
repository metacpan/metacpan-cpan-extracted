use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  MIN_PERL_VERSION  => 5.008000,
  NAME              => 'Win32::MultiLanguage',
  VERSION_FROM      => 'lib/Win32/MultiLanguage.pm', # finds $VERSION
  PREREQ_PM         => {}, # e.g., Module::Name => 1.1
  ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM  => 'lib/Win32/MultiLanguage.pm', # retrieve abstract from module
     AUTHOR         => 'Bjoern Hoehrmann <bjoern@hoehrmann.de>') : ()),
  LIBS              => [''], # e.g., '-lm'
  DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
# Insert -I. if you add *.h files later:
  INC               => '', # e.g., '-I/usr/include/other'
# Un-comment this if you add C files to link with later:
  # OBJECT            => '$(O_FILES)', # link all the C files too

  LICENSE           => 'perl',
  'dist'            => {
    PREOP     => 'chmod 600 Makefile.PL',
    TARFLAGS	=> '--group=none --owner=bjoern --mode=a+rw -cvf',
  },
  META_MERGE        => {
    'meta-spec' => { version => 2 },
    resources => {
       repository => {
         type => 'git',
         url  => 'https://github.com/hoehrmann/Win32-MultiLanguage.git',
         web  => 'https://github.com/hoehrmann/Win32-MultiLanguage',
      },
    },
  },

);

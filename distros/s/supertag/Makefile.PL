use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'supertag',
  EXE_FILES     => [ 'supertag' ],
  VERSION_FROM  => 'supertag',
  PREREQ_PM     => {
    'MP3::Info'           => 1,
    'Audio::FLAC::Header' => 1,
  },
($] >= 5.005 ?     ## Add these new keywords supported since 5.005
  (ABSTRACT_FROM    => 'supertag', 
   AUTHOR           => 'Alan Grow <agrow+nospam@iobound.net>') : ()),
);


use ExtUtils::MakeMaker;
WriteMakefile
  (NAME            => 'WWW::Rafb',
   VERSION_FROM    => 'Rafb.pm',
   PREREQ_PM       => {LWP::UserAgent => 0,
                       URI::Escape     => 0,
                      },
   dist =>
   {COMPRESS       => 'gzip',
    SUFFIX         => 'gz',
   },
  );


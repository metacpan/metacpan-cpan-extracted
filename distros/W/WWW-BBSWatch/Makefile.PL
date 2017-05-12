use ExtUtils::MakeMaker;
WriteMakefile
  (NAME            => 'WWW::BBSWatch',
   VERSION_FROM    => 'BBSWatch.pm',
   PREREQ_PM       => {LWP::UserAgent => 0,
                       MIME::Lite     => 0,
                      },
   dist =>
   {COMPRESS       => 'gzip',
    SUFFIX         => 'gz',
   },

   clean           => {FILES => ".test*"},
  );

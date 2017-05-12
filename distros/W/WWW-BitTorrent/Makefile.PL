use ExtUtils::MakeMaker;
WriteMakefile
  (NAME            => 'WWW::BitTorrent',
   VERSION_FROM    => 'BitTorrent.pm',
   PREREQ_PM       => {LWP::UserAgent => 0,
                       LWP::Simple     => 0,
                      },
   dist =>
   {COMPRESS       => 'gzip',
    SUFFIX         => 'gz',
   },
  );


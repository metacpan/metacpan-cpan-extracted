use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'           => 'Tie::FileLRUCache',
    'VERSION_FROM'   => 'lib/Tie/FileLRUCache.pm',
    'PREREQ_PM'      => { 
                          'Digest::SHA1'      => 0,
                          'Storable'          => 0,
                          'Class::ParmList'   => '1.03',
                          'Test::More'        => 0,
                          'File::Temp'        => 0,
                         },
    'linkext'        => { LINKTYPE => '' },    # no link needed
    'dist'           => { 'COMPRESS' => 'gzip -9f', 
                            'SUFFIX' => 'gz',
                               'ZIP' => '/usr/bin/zip',
                          'ZIPFLAGS' => '-rl'
                        },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (
       AUTHOR         => 'Benjamin Franz <snowhare@nihongo.org>') : ()),

       ($] >= 5.800 ?     ## Add these new keywords supported since 5.8
             (NO_META      => 1) : ()),

       PL_FILES       => {},

);

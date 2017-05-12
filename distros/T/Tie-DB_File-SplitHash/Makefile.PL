use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	     => 'Tie::DB_File::SplitHash',
    'VERSION_FROM'   => 'lib/Tie/DB_File/SplitHash.pm',
    'linkext'        => { LINKTYPE=>'' },	# no link needed
    'dist'           => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz',
	                 'ZIP'=>'/usr/bin/zip','ZIPFLAGS'=>'-rl'},
    'PREREQ_PM'      => {
                          'Digest::SHA1' => 0,
                          'DB_File'      => 0,
                          'File::Path'   => 0,
                          'File::Spec'   => 0,
                          'File::Temp'   => 0,
                          'Fcntl'        => 0,
                          'Carp' => 0,
    }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (
      ABSTRACT => 'Divides a DB_File hash across multiple files',
       AUTHOR  => 'Benjamin Franz <snowhare@nihongo.org>') : ()),

       ($] >= 5.800 ?     ## Add these new keywords supported since 5.8
             (NO_META      => 1) : ()),

       PL_FILES       => {},

);

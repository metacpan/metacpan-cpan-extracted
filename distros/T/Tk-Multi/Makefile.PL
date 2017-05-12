use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
              'NAME'	   => 'Tk::Multi',
              'VERSION' => '1.006',
              'dist' => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'},
              ($] >= 5.005 ?
               (ABSTRACT   => 'Manage together Text, Canvas or Frame widgets',
                AUTHOR     => 'Dominique Dumont (domi@komarr.grenoble.hp.com)') : ()),
              'PREREQ_PM' =>
              {
               'Tk' => '800.013',
               'Tk::TFrame' => 0,
               'Tk::Pod' => 0,
               'Tk::ObjScanner' => 1.016,
               'Tie::IxHash' => 0
              }
             );

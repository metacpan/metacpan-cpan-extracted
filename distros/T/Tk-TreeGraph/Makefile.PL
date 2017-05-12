use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  (
   'NAME'	=> 'Tk::TreeGraph',
   'VERSION_FROM' => 'TreeGraph.pm',
   'dist' => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'},
   PM            => 
   {
    'TreeGraph.pm'   => '$(INST_LIB)/Tk/TreeGraph.pm',
    'demo/treegraph.pl' => '$(INST_ARCHLIB)/Tk/demos/widtrib/treegraph.pl'
   },
   PREREQ_PM   => 
   {
    'Tk'	=> '0', 
   },
   ABSTRACT   => 'Widget to draw a tree in a Canvas',
   AUTHOR     => 'Dominique Dumont (domi@komarr.grenoble.hp.com)'
  );

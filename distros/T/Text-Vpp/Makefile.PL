use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
  (
   'NAME'	=> 'Text::Vpp',
   'VERSION_FROM' => 'Vpp.pm', # finds $VERSION
   'EXE_FILES' => ['vpp'],
   ABSTRACT   => 'Versatile text pre-processor',
   AUTHOR     => 'Dominique Dumont (domi@barrayar.grenoble.hp.com)',
   'dist' => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'}
  );

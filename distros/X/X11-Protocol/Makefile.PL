use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  ('ABSTRACT' => 'Raw interface to X Window System servers',
   'AUTHOR' => 'Stephen McCamant <SMCCAM@cpan.org>',
   'NAME'	=> 'X11::Protocol',
   'VERSION_FROM' => 'Protocol.pm', # finds $VERSION
   'PMLIBDIRS' => ['Protocol/', 'Protocol/Ext', 'Protocol/Connection'],
   'dist' => {COMPRESS => 'gzip -9', SUFFIX => 'gz'},
  );

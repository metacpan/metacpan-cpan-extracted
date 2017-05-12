require 5.006;
use ExtUtils::MakeMaker;
WriteMakefile
  (
   NAME  => 'Tk::ErrorDump',
   VERSION => '0.01',
   PREREQ_PM => { 'Tk' => '800.024', 'Tk::ROText' => '0.0' }
  );

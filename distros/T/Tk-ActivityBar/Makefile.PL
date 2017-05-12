require 5.000;
use ExtUtils::MakeMaker;
WriteMakefile
  (
   NAME  => 'Tk::ActivityBar',
   VERSION => '0.01',
   PREREQ_PM => { 'Tk::ProgressBar' => '3.012' }
  );

use strict;
use warnings;

if (  $^O =~ /MSWin32/ismx
   or $^O =~ /linux/ismx
   or $^O =~ /darwin/ismx )
{

   use ExtUtils::MakeMaker;

   WriteMakefile(
      NAME             => 'Tkx::TclTk::Bind::ImageLibrary',
      AUTHOR           => 'Juergen von Brietzke <juergen.von.brietzke@t-online.de>',
      VERSION_FROM     => 'lib/Tkx/TclTk/Bind/ImageLibrary.pm',
      ABSTRACT_FROM    => 'lib/Tkx/TclTk/Bind/ImageLibrary.pm',
      PL_FILES         => {},
      MIN_PERL_VERSION => '5.012000',
      PREREQ_PM => {
         'Modern::PBP::Perl' => 0,
         'Tkx::TclTk::Bind'  => 0,
      },
      BUILD_REQUIRES => {
         'Test::More'          => 0,
         'Test::Pod'           => 1.14,
         'Test::Pod::Coverage' => 1.04,
      },
      dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
      clean => { FILES => 'Tkx-TclTk-Bind-ImageLibrary*' },
   );
}
else {
   {
      print("OS unsupported\nModul supported Linux, MSWin32 and MacOS X")
         and exit;
   }
}

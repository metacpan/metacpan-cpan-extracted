use strict;
use warnings;

if (  $^O =~ /MSWin32/ismx
   or $^O =~ /linux/ismx
   or $^O =~ /darwin/ismx )
{

   use ExtUtils::MakeMaker;

   WriteMakefile(
      NAME             => 'Tkx::TclTk::Bind::IWidgets',
      AUTHOR           => 'Juergen von Brietzke <juergen.von.brietzke@t-online.de>',
      VERSION_FROM     => 'lib/Tkx/TclTk/Bind/IWidgets.pm',
      ABSTRACT_FROM    => 'lib/Tkx/TclTk/Bind/Iwidgets.pm',
      PL_FILES         => {},
      MIN_PERL_VERSION => '5.012000',
      PREREQ_PM => {
         'Env::C'            => 0,
         'Modern::PBP::Perl' => 0,
         'Tkx::TclTk::Bind'  => 0,
      },
      BUILD_REQUIRES => {
         'Test::More'          => 0,
         'Test::Pod'           => 1.14,
         'Test::Pod::Coverage' => 1.04,
      },
      dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
      clean => { FILES => 'Tkx-TclTk-Bind-IWidgets*' },
   );
}
else {
   {
      print("OS unsupported\nModul supported Linux, MSWin32 and MacOS X")
         and exit;
   }
}

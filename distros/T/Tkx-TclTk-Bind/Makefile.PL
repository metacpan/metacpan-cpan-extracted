use strict;
use warnings;

if (  $^O =~ /MSWin32/ismx
   or $^O =~ /linux/ismx
   or $^O =~ /darwin/ismx )
{

   use ExtUtils::MakeMaker;

   WriteMakefile(
      NAME             => 'Tkx::TclTk::Bind',
      AUTHOR           => 'Juergen von Brietzke <juergen.von.brietzke@t-online.de>',
      VERSION_FROM     => 'lib/Tkx/TclTk/Bind.pm',
      ABSTRACT_FROM    => 'lib/Tkx/TclTk/Bind.pm',
      PL_FILES         => {},
      MIN_PERL_VERSION => '5.012000',
      PREREQ_PM => {
         'Archive::Tar'       => 0,
         'Config'             => 0,
         'Const::Fast'        => 0,
         'English'            => 0,
         'Exporter'           => 0,
         'File::Remove'       => 0,
         'File::Spec'         => 0,
         'Modern::PBP::Perl'  => 0,
         'Tkx'                => 0,
      },
      BUILD_REQUIRES => {
         'Test::More'          => 0,
         'Test::Pod'           => 1.14,
         'Test::Pod::Coverage' => 1.04,
      },
      dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
      clean => { FILES => 'Tkx-TclTk-Bind-*' },
   );
}
else {
   {
      print("OS unsupported\nModul supported Linux, MSWin32 and MacOS X")
         and exit;
   }
}

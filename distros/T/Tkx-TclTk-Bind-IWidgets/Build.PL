use strict;
use warnings;

if (  $^O =~ /MSWin32/ismx
   or $^O =~ /linux/ismx
   or $^O =~ /darwin/ismx )
{

   use Module::Build;

   my $builder = Module::Build->new(
      module_name       => 'Tkx::TclTk::Bind::IWidgets',
      license           => 'artistic2',
      dist_author       => 'Juergen von Brietzke <juergen.von.brietzke@t-online.de>',
      dist_version_from => 'lib/Tkx/TclTk/Bind/IWidgets.pm',
      requires => {
         'Env::C'            => 0,
         'Modern::PBP::Perl' => 0,
         'Tkx::TclTk::Bind'  => 0,
      },
      build_requires => {
         'Test::More'          => 0,
         'Test::Pod'           => 1.14,
         'Test::Pod::Coverage' => 1.04,
      },
      configure_requires => { 'Module::Build' => 0.42 },
      add_to_cleanup     => [ 'Tkx-TclTk-Bind-IWidgets*' ],
   );
   $builder->add_build_element('pl');
   $builder->add_build_element('tar');
   $builder->create_build_script();
}
else {
   {
      print("OS unsupported\nModul supported Linux, MSWin32 and MacOS X")
         and exit;
   }
}

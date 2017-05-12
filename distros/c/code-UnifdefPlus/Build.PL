use 5.010000; # NOT 5.8.8 - needed by CPAN testers

use Module::Build;

  my $builder = Module::Build
    ->new( module_name => 'code::UnifdefPlus'
           , license => 'perl'
#           , requires => { perl => '>= 5.10.0' }   #hmm, this doesn't work...  this causes a hard to track problem!
           , dist_version => '0.005.004'
           , dist_author => 'John Ulvr <perldev@ulvr.com>'
           , dist_abstract => 'processes conditional parts of makefiles, c/c++ and kconfig files'
           , create_readme => 0
           , create_makefile_pl => 'traditional'
         );
  $builder->create_build_script;  #generate Build
  
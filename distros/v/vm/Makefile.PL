use ExtUtils::MakeMaker;

WriteMakefile(
  'AUTHOR'		=> 'Dan Brumleve <dan_brumleve@yahoo.com>',
  'NAME'		=> 'vm',
  'VERSION_FROM'	=> 'vm.pm',
  clean			=> {FILES => '*.so'},
);

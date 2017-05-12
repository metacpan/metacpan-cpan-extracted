use ExtUtils::MakeMaker;

WriteMakefile(
  'AUTHOR'		=> 'Dan Brumleve <dan_brumleve@yahoo.com>',
  'NAME'		=> 'autobless',
  'VERSION_FROM'	=> 'autobless.pm',
  clean			=> {FILES => '*.so'},
);

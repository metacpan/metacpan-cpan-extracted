##
##  Makefile.PL -- MakeMaker config file
##

use ExtUtils::MakeMaker;

#   avoid implicit conversion by MakeMaker 
#   which is introduced by a not very nice Warning... 
use Cwd;
($root = cwd()) =~ s|/[^/]+/[^/]+/?$||;

WriteMakefile(
    'NAME'         => 'Parse::ePerl',
    'VERSION_FROM' => 'ePerl.pm',
    'INC'          => "-I$root", 
    'LIBS'         => ["-L$root -leperl"],
);

##EOF##

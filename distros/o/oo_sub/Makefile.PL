use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(

  NAME         => 'oo_sub' ,
  VERSION_FROM => 'lib/oo_sub.pm' ,
  AUTHOR       => 'Elvin Aslanov <rwp.primary@gmail.com>' ,
  ABSTRACT     => 'Enable OOP for supported Perl functions' ,
  LICENSE      => 'Perl' ,

  META_MERGE   => {
    release_status => 'stable' ,
    keywords       => [ 'pragma' , 'oop' , 'cpan' ] ,
    resources      => {
      homepage   => 'https://github.com/rwp0/oo_sub' ,
      repository =>
        {
          url  => 'git://github.com/rwp0/oo_sub.git' ,
          type => 'git' ,
          web  => 'https://github.com/rwp0/oo_sub' ,
        } ,
      bugtracker => {
        web    => 'https://github.com/rwp0/oo_sub/issues' ,
        mailto => 'rwp.primary@gmail.com'
      }
    } ,
  } ,

);

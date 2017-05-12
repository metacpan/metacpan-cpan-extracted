use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
   NAME          => 'WWW::Comix',
   AUTHOR        => 'Flavio Poletti <flavio [at] polettix [dot] it>',
   VERSION_FROM  => 'lib/WWW/Comix.pm',
   ABSTRACT_FROM => 'lib/WWW/Comix.pm',
   PL_FILES      => {},
   PREREQ_PM     => {
      'Test::More'               => 0,
      'version'                  => 0,
      'Moose'                    => 0,
      'Moose::Policy::FollowPBP' => 0,
      'Path::Class'              => 0,
      'WWW::Mechanize'           => 0,
      'Module::Pluggable'        => 0,
      'HTML::Entities'           => 0,
      'List::MoreUtils'          => 0,
      'Readonly'                 => 0,
      'URI'                      => 0,
      'HTML::LinkExtor'          => 0,
   },
   dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
   clean => {FILES    => 'WWW-Comix-*'},
);

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME              => "XS::Manifesto",
  VERSION_FROM      => "lib/XS/Manifesto.pm",
  ABSTRACT_FROM     => "lib/XS/Manifesto.pm",
  LICENSE           => "perl",
  AUTHOR            => 'Ivan Baidakou (DMOL) <i.baydakov@crazypanda.ru>',
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
  META_MERGE => {
    resources => {
        repository => 'https://github.com/basiliscos/p5-XS-Manifesto',
        bugtracker => { web => 'https://github.com/basiliscos/p5-XS-Manifesto/issues' },
    },
  }
);

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tk::Canvas::Draw',
    AUTHOR              => q{jcnorton <jchnorton@verizon.net>},
    VERSION_FROM        => 'lib/Tk/Canvas/Draw.pm',
    ABSTRACT_FROM       => 'lib/Tk/Canvas/Draw.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        Tk           => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Tk-Canvas-Draw-*' },
);

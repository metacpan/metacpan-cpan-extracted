use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::Mojo::Plack',
    AUTHOR              => q{Nicolas Mendoza <mendoza@pvv.ntnu.no>},
    VERSION_FROM        => 'lib/Test/Mojo/Plack.pm',
    ABSTRACT_FROM       => 'lib/Test/Mojo/Plack.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'IO::String' => 0,
        'Test::More' => 0,
        'Mojolicious' => 5.0,
        'Class::Load' => 0,
        'List::MoreUtils' => 0,
        'Scalar::Util' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-Mojo-Plack-*' },
);

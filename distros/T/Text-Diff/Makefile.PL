use strict;

BEGIN {
    require 5.005_03;
}
use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

WriteMakefile(
    NAME         => 'Text::Diff',
    ABSTRACT     => 'Perform diffs on files and record sets',
    VERSION_FROM => 'lib/Text/Diff.pm',
    PREREQ_PM    => {
        'Exporter'        => 0,
        'Algorithm::Diff' => '1.19',
    },
    ( $] >= 5.005 ? ( AUTHOR => 'Adam Kennedy <adamk@cpan.org>', ) : () ),
    (
        $ExtUtils::MakeMaker::VERSION ge '6.30_00' ? ( LICENSE => 'perl', ) : ()
    ),
    (
        $ExtUtils::MakeMaker::VERSION ge '6.46'
        ? ( META_MERGE => { build_requires => { Test => 0 } } )
        : ()
    ),
    META_MERGE =>
      { resources => {
           repository => 'https://github.com/neilbowers/Text-Diff'
        }
      },

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.006)
        : ()
    ),

);

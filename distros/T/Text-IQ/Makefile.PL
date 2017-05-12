use strict;
use warnings;
use ExtUtils::MakeMaker;
use 5.008003;

my $MM_Version = $ExtUtils::MakeMaker::VERSION;

if ( $MM_Version =~ /_/ )    # dev version
{
    $MM_Version = eval $MM_Version;
    die $@ if ($@);
}

WriteMakefile(
    NAME          => 'Text::IQ',
    AUTHOR        => q{Peter Karman <karman@cpan.org>},
    VERSION_FROM  => 'lib/Text/IQ.pm',
    ABSTRACT_FROM => 'lib/Text/IQ.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'           => 0,
        'Search::Tools'        => '1.000',
        'Text::Aspell'         => 0,
        'Lingua::EN::Syllable' => 0.28,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Text-IQ-*' },
    ( $MM_Version >= 6.48 ? ( MIN_PERL_VERSION => '5.8.3' ) : () ),
    ( $MM_Version >= 6.31 ? ( LICENSE          => 'perl' )  : () ),
    (   $MM_Version <= 6.44 ? ()
        :

            (
            META_MERGE => {
                resources => {
                    license  => 'http://dev.perl.org/licenses/',
                    homepage => 'https://github.com/karpet/text-iq-perl',
                    bugtracker =>
                        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-IQ',
                    repository => 'git@github.com:karpet/text-iq-perl.git',
                },
            }
            )
    ),

);


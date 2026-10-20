use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

my( $mm ) = $ExtUtils::MakeMaker::VERSION =~ /^([^_]+)/;

WriteMakefile(
    NAME             => 'Validator::LIVR',
    AUTHOR           => q{Viktor Turskyi <koorchik@cpan.org>},
    VERSION_FROM     => 'lib/Validator/LIVR.pm',
    ABSTRACT_FROM    => 'lib/Validator/LIVR.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More'      => '0.96', # subtests without a plan
        'Test::Exception' => '0',
        'JSON'            => '0'
    },
    PREREQ_PM => {
        # Core modules, but some systems install them separately
        'Carp'         => '0',
        'Scalar::Util' => '0',
    },
    ( $mm < 6.46
        ? ()
        : ( META_MERGE => {
              resources => {
                  repository => 'https://github.com/koorchik/Validator-LIVR',
                  bugtracker => 'https://github.com/koorchik/Validator-LIVR/issues',
              },
            }
        )
    ),
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Validator-LIVR-*' },
);

package MY;

# MakeMaker before 7.32 installs a top-level README.pod as Validator/README.pod
sub libscan {
    my ( $self, $path ) = @_;
    return '' if $path =~ /^README\.pod$/i;
    return $self->SUPER::libscan($path);
}

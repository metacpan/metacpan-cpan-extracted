use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# other OS do have an arc4random(3) but the quality on it may be iffy or
# it may require arc4random_stir(3) calls to suck less...
use lib qw(inc);
use Devel::AssertOS qw(OpenBSD);

sub merge_key_into {
    my ( $href, $target, $source ) = @_;
    %{ $href->{$target} } = ( %{ $href->{$target} }, %{ delete $href->{$source} } );
}

my %params = (
    NAME         => 'Unix::OpenBSD::Random',
    ABSTRACT     => 'interface to arc4random(3) on OpenBSD',
    AUTHOR       => q{Jeremy Mates <jmates@cpan.org>},
    VERSION_FROM => 'lib/Unix/OpenBSD/Random.pm',

    LICENSE          => 'bsd',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',

    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '6.48', 'strict' => 0, },
    BUILD_REQUIRES     => {},
    TEST_REQUIRES      => {
        'Config'       => 0,
        'Scalar::Util' => 0,
        'Test::Most'   => 0,
        'lib'          => 0,
    },
    PREREQ_PM => { 'Exporter' => 0, 'XSLoader' => 0, 'strict' => 0, },

    META_MERGE => {
        'meta-spec'         => { version => 2 },
        'homepageresources' => {
            repository => {
                url  => 'git://github.com/thrig/Unix-OpenBSD-Random.git',
                web  => 'https://github.com/thrig/Unix-OpenBSD-Random',
                type => 'git',
            },
        },
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Unix-OpenBSD-Random-*' },
);

(   my $mm_version = ExtUtils::MakeMaker->VERSION(
        $params{CONFIGURE_REQUIRES}{'ExtUtils::MakeMaker'}
    )
) =~ tr/_//d;

if ( $mm_version < 6.67_04 ) {
    *ExtUtils::MM_Any::_add_requirements_to_meta_v1_4 =
      \&ExtUtils::MM_Any::_add_requirements_to_meta_v2;
}

if ( $mm_version < 6.63_03 ) {
    merge_key_into \%params, 'BUILD_REQUIRES', 'TEST_REQUIRES';
}

if ( $mm_version < 6.55_01 ) {
    merge_key_into \%params, 'CONFIGURE_REQUIRES', 'BUILD_REQUIRES';
}

if ( $mm_version < 6.51_03 ) {
    merge_key_into \%params, 'PREREQ_PM', 'CONFIGURE_REQUIRES';
}

WriteMakefile( ( MM->can('signature_target') ? ( SIGN => 1 ) : () ), %params );

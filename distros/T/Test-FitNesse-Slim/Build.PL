use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::FitNesse::Slim',
    dist_abstract       => 'Perl implementation of the FitNesse SLiM protocol',
    license             => 'perl',
    dist_author         => q{Greg Bacon <gbacon@gbacon.com>},
    dist_version_from   => 'lib/Test/FitNesse/Slim.pm',
    configure_requires => {
        'Module::Build' => '0.20',
    },
    requires => {
        'perl'              => '5.36.0',
        'HTML::TreeBuilder' => '5.07',
    },
    build_requires => {
        'Test::More'          => '0.88',
        'Test::Exception'     => '0',
        'Test::Pod'           => '1.22',
        'Test::Pod::Coverage' => '1.08',
        'Pod::Text'           => '0',
        'HTTP::Tiny'          => '0.070',
        'IPC::Run'            => '20260322.0',
    },
    script_files        => ['bin/perl-slim'],
    meta_add => {
        # The distribution's own code uses the Perl 5 dual license. Test-only
        # fixture adaptations also include material under FitNesse's CPL 1.0.
        'meta-spec' => {
            version => 2,
            url => 'https://metacpan.org/pod/CPAN::Meta::Spec',
        },
        license => [ 'perl_5', 'open_source' ],
        resources => {
            license => [
                'https://github.com/gbacon/test-slim/blob/main/LICENSE',
                'https://www.gnu.org/licenses/old-licenses/gpl-1.0.en.html',
                'https://dev.perl.org/licenses/artistic.html',
                'https://github.com/unclebob/fitnesse/blob/v20251025/LICENSE.txt',
            ],
            repository => 'https://github.com/gbacon/test-slim',
        },
    },
    add_to_cleanup      => [ 'test-slim-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();

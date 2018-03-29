use 5.006001;

use strict;
use warnings;

use Module::Build;


my $class = Module::Build->subclass( code => <<'END_SUBCLASS' );

    sub ACTION_test {
        my ($self) = @_;

        $self->depends_on('manifest');

        return $self->SUPER::ACTION_test();
    }

    sub ACTION_authortest {
        my ($self) = @_;

        $self->depends_on('build');
        $self->depends_on('manifest');
        $self->depends_on('distmeta');

        $self->test_files( qw< t xt > );
        $self->recursive_test_files(1);

        $self->depends_on('test');

        return;
    } # end ACTION_authortest()

    sub ACTION_distdir {
        my ($self) = @_;

        $self->depends_on('authortest');

        return $self->SUPER::ACTION_distdir;
    } # end ACTION_distdir

END_SUBCLASS

my $builder = $class->new(
    module_name     => 'Test::Perl::Critic',
    dist_author     => 'Jeffrey Thalhammer <thaljef@cpan.org>',
    dist_abstract   => 'Use Perl::Critic in test programs.',
    license         => 'perl',
    create_readme   => 1,
    create_packlist => 1,
    sign            => 0,

    configure_requires   => {
        'Module::Build'             => 0.4,
     },

    requires             => {
        'Carp'                      => 0,
        'English'                   => 0,
        'MCE'                       => 1.827,
        'Perl::Critic'              => 1.105,
        'Perl::Critic::Utils'       => 1.105,
        'Perl::Critic::Violation'   => 1.105,
        'strict'                    => 0,
        'Test::Builder'             => 0.88,
        'warnings'                  => 0,
    },

    build_requires       => {
        'Test::More'                => 0,
    },

    add_to_cleanup  => [ qw(Test-Perl-Critic-* MANIFEST.bak) ],

    meta_merge          => {
        resources => {
            bugtracker  => 'https://github.com/Perl-Critic/Test-Perl-Critic/issues',
            repository  => 'git://github.com/Perl-Critic/Test-Perl-Critic.git',
            license     => [ 'http://dev.perl.org/licenses' ],
            homepage    => 'http://perlcritic.com',

        },
    },
);

$builder->create_build_script();

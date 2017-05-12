use 5.008;
use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
    class => 'My::Builder',
    code  => q{
        sub ACTION_authortest {
            my ($self) = @_;
            $self->test_files( qw< xt > );
            $self->recursive_test_files(1);
            $self->depends_on('test');
            return;
        }
        sub ACTION_distdir {
            my ($self) = @_;
            $self->depends_on('authortest');
            return $self->SUPER::ACTION_distdir();
        }
    }
);

my $builder = $class->new(
    module_name        => 'TheSchwartz',
    license            => 'perl',
    dist_author        => 'Six Apart <cpan@sixapart.com>',
    dist_version_from  => 'lib/TheSchwartz.pm',
    configure_requires => { 'Module::Build' => 0 },
    build_requires     => {
        'Module::Build'      => 0,
        'Test::More'         => 0,
        'Data::ObjectDriver' => 0.04,
        'Digest::MD5'        => 0,
        'Storable'           => 0,
    },
    requires => {
        'Data::ObjectDriver' => 0.04,
        'Digest::MD5'        => 0,
        'Storable'           => 0,
    },
    add_to_cleanup => [ 'TheSchwartz-*', 'tmp', 'blib', '*.bak', 'META.*' ],
    script_files   => ['bin/schwartzmon'],
);

$builder->create_build_script();

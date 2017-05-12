use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
    class => 'My::Builder',
    code  => q{
        sub ACTION_authortest {
            my ($self) = @_;
            $self->depends_on('build');
            $self->depends_on('distmeta');
            $self->test_files( qw< t xt/author > );
            $self->recursive_test_files(1);
            $self->depends_on('test');
            return;
        }
        sub ACTION_distdir {
            my ($self) = @_;
            $self->depends_on('authortest');
            return $self->SUPER::ACTION_distdir();
        }
    },
);

my $builder = $class->new(
    module_name        => 'XML::Catalog',
    license            => 'perl',
    dist_author        => 'Jeff Fearn <jfearn@cpan.org>',
    dist_version_from  => 'lib/XML/Catalog.pm',
    create_makefile_pl => 'traditional',
    configure_requires => { 'Module::Build' => 0 },
    build_requires     => {
        'Test::More'          => 0,
        'XML::Parser'         => 0,
        'LWP::Simple'         => 0,
        'URI::URL'            => 0,
        'Text::ParseWords'    => 0,
        'Cwd'                 => 0,
    },
    requires => {
        'XML::Parser'      => 0,
        'LWP::Simple'      => 0,
        'URI::URL'         => 0,
        'Text::ParseWords' => 0,
    },
    add_to_cleanup => [ 'XML-Catalog-*', 'tmp', 'blib', '*.bak', 'META.yml', 'META.json' ],
    script_files   => [],
);

$builder->create_build_script();

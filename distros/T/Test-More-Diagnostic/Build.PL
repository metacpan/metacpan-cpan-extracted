# $Id: Build.PL 2676 2007-10-03 17:38:27Z andy $
use strict;
use warnings;
use Module::Build;

my $build_class = Module::Build->subclass(
    class => 'inc::MyBuilder',
    code  => <<'    SUBCLASS',
      sub ACTION_testauthor {
          my $self = shift;
          $self->test_files('t', 'xt/author');
          $self->generic_test( type => 'default' );
      }
    SUBCLASS
);

my $builder = $build_class->new(
    module_name       => 'Test::More::Diagnostic',
    license           => 'perl',
    dist_author       => 'Andy Armstrong <andy@hexten.net>',
    dist_version_from => 'lib/Test/More/Diagnostic.pm',
    requires          => {
        'Test::More'                   => 0,
        'TAP::Parser::YAMLish::Writer' => 2.99
    },
    add_to_cleanup => ['Test-More-Diagnostic-*'],
);

$builder->create_build_script();

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Tree::Navigator',
    license             => 'perl',
    dist_author         => 'Laurent Dami <dami AT cpan.org>',
    dist_version_from   => 'lib/Tree/Navigator.pm',
    requires => {
        'namespace::autoclean'            => 0,  
        'Alien::GvaScript'                => 0,
        'DBI'                             => 0,
        'DBIx::DataModel'                 => 0,
        'Devel::StackTrace::WithLexicals' => 0,
        'Devel::StackTrace::AsHTML'       => 0,
        'Devel::Symdump'                  => 0,
        'HTTP::Date'                      => 0,
        'List::MoreUtils'                 => 0,
        'List::Util'                      => 0,
        'Moose'                           => 0,
        'MooseX::NonMoose'                => 0,
        'MooseX::Params::Validate'        => 0,
        'Params::Validate'                => 0,
        'Plack'                           => 1.0004,
        'Plack::Component'                => 0,
        'Plack::MIME'                     => 0,
        'Plack::Request'                  => 0,
        'Plack::Util'                     => 0,
        'Scalar::Util'                    => 0,
        'Template'                        => 0,
        'URI::Escape'                     => 0,   
      },
    build_requires => {
      'Test::More'                        => 0,   
    },
    add_to_cleanup      => [ 'Tree-Navigator-*' ],
    meta_merge => {
      resources => {
        repository => 'https://github.com/damil/Tree-Navigator',
       }
     },
);

$builder->create_build_script();


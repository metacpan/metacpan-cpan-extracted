use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::FreshMeat::API',
    license             => 'perl',
    dist_author         => 'Barry Walsh <draegtun@cpan.org>',
    dist_version_from   => 'lib/WWW/FreshMeat/API.pm',
    
    build_requires => {
        'Test::More' => 0,
    },
    
    requires => {
        'Moose'      => 0.40,   # number in the dark... but hopefully good one!
        'XML::RPC'   => 0.8,
    },
    
    add_to_cleanup      => [ 'WWW-FreshMeat-API-*' ],
    
    meta_merge => {
      resources => {
          repository => 'http://github.com/draegtun/WWW-FreshMeat-API'
      }
    },

);

$builder->create_build_script();

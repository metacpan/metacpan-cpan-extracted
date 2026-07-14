use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::HTMLTagAttributeCounter',
    license             => 'perl',
    dist_author         => q|Zoffix <'zoffix@cpan.org'>|,
    dist_version_from   => 'lib/WWW/HTMLTagAttributeCounter.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'LWP::UserAgent'           => 2.036,
        'HTML::TokeParser::Simple' => 3.15,
        'overload'                 => 1.04,
        'Class::Accessor::Grouped' => 0,
        'perl' => '5.006',
    },
    add_to_cleanup      => [ 'WWW-HTMLTagAttributeCounter-*' ],
    create_makefile_pl => 'traditional',
);
if ( $ENV{RELEASE_TESTING} ) {
    system('pod2text lib/WWW/HTMLTagAttributeCounter.pm > README');
}

$builder->create_build_script();

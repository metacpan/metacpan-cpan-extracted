use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'lib::findbin',
    license             => 'perl',
    dist_author         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from   => 'lib/lib/findbin.pm',
    requires => {
        'Test::More' => 0, # for testing, I know I know: Test::XT
        'FindBin'    => 0,
    },
    add_to_cleanup      => [ 'lib-findbin-*' ],
);

$builder->create_build_script();

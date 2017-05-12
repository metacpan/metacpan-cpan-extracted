use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Tie::Hash::ReadonlyStack',
    license             => 'perl',
    dist_author         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from   => 'lib/Tie/Hash/ReadonlyStack.pm',
    requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Tie-Hash-ReadonlyStack-*' ],
);

$builder->create_build_script();

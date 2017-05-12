use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Throw::Back',
    license           => 'perl',
    dist_author       => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from => 'lib/Throw/Back.pm',
    requires          => {
        'Test::More' => 0,
        'Test::Deep' => 0,
    },
    add_to_cleanup => ['Throw-Back-*'],
);

$builder->create_build_script();

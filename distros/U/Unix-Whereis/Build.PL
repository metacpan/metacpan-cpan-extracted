use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Unix::Whereis',
    license           => 'perl',
    dist_author       => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from => 'lib/Unix/Whereis.pm',
    requires          => {
        'Test::More'  => 0,
        'File::Temp'  => 0,
        'File::Slurp' => 0,

        'File::Spec' => 0,
    },
    add_to_cleanup => ['Unix-Whereis-*'],
);

$builder->create_build_script();

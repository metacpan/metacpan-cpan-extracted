use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Text::Fold',
    license           => 'perl',
    dist_author       => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from => 'lib/Text/Fold.pm',
    requires          => {
        'Test::More'          => 0,
        'String::UnicodeUTF8' => 0,
    },
    add_to_cleanup => ['Text-Fold-*'],
);

$builder->create_build_script();

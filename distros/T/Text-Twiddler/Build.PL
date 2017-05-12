use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Text::Twiddler',
    license             => 'perl',
    dist_author         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from   => 'lib/Text/Twiddler.pm',
    requires => {
        'Test::More'  => 0,
        'version'     => 0,
        'Class::Std'  => 0,
        'Class::Std::Utils'  => 0,
        'Locale::Maketext::Pseudo' => 0,
        'List::Cycle' => 0,
    },
    add_to_cleanup      => [ 'Text-Twiddler-*' ],
);

$builder->create_build_script();

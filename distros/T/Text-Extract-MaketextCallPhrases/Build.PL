use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Text::Extract::MaketextCallPhrases',
    license           => 'perl',
    dist_author       => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from => 'lib/Text/Extract/MaketextCallPhrases.pm',
    requires          => {
        'Test::More'          => 0,
        'Text::Balanced'      => 0,
        'String::Unquotemeta' => 0,
        'Module::Want'        => '0.6',
    },
    add_to_cleanup => ['Text-Extract-MaketextCallPhrases-*'],
);

$builder->create_build_script();

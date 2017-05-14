use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'WWW::ORCID',
    license => 'perl',
    dist_author => [
        'Patrick Hochstenbach <patrick.hochstenbach@ugent.be>',
        'Nicolas Steenlant <nicolas.steenlant@ugent.be>',
        'Simeon Warner <simeon.warner@cornell.edu>',
    ],
    build_requires => {
        'Software::License' => 0,
        'Test::Exception'   => '0.31',
    },
    requires => {
        'perl' => '5.10.1',
        'JSON' => '2.51',
        'LWP::UserAgent' => 0,
        'Moo' => '1.000008',
        'namespace::clean' => '0.24',
        'URI' => 0,
        'XML::Writer' => 0,
    },
    recommends => {
        'JSON::XS' => '2.3',
    },
    add_to_cleanup => [qw(
        WWW-ORCID-*
    )],
    create_makefile_pl => 'traditional',
    create_license => 1,
);

$build->create_build_script;


use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Text::Restructured::Writer::LibXML',
    license             => 'perl',
    dist_name           => 'Text-Restructured-Writer-LibXML',
    dist_abstract       => <<'END_ABSTRACT',
This module implements a "Writer" for Text::Restructured, that instead
of returning a string, returns a LibXML DOM.
END_ABSTRACT
    dist_author         => 'Gianni Ceccarelli <dakkar@thenautilus.net>',
    dist_version_from   => 'lib/Text/Restructured/Writer/LibXML.pm',
    requires            => {
      'Text::Restructured' => 0.003031,
      'XML::LibXML' => 1.61,
    },
    build_requires      => {
        'Test::More' => 0,
        'XML::LibXML::XPathContext' => 1.61,
    },
    add_to_cleanup      => [ 'Text-Restructured-Writer-LibXML-*' ],
    create_makefile_pl  => 'traditional',
    create_packlist     => 1,
    recursive_test_files=> 1,
    sign                => 1,
);

$builder->create_build_script();

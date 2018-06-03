use strict;
use warnings;

use lib "./inc";

use Module::Build 0.4004;
use XML::Grammar::Builder;

my $builder = XML::Grammar::Builder->new(
    module_name         => 'XML::Grammar::ProductsSyndication',
    license             => 'mit',
    dist_author         => 'Shlomi Fish <shlomif@cpan.org>',
    dist_version_from   => 'lib/XML/Grammar/ProductsSyndication.pm',
    configure_requires => {
        'Module::Build' => '0.36',
    },
    requires => {
        'Class::Accessor' => 0,
        'File::Spec' => 0,
        'Imager' => '0.91',
        'LWP::UserAgent' => 0,
        'XML::Amazon' => 0,
        'XML::LibXML' => 0,
        'XML::LibXSLT' => 0,
        'perl' => '5.008',
        'strict' => 0,
        'warnings' => 0,
    },
    test_requires => {
        'Test::More' => 0,
        'Test::XML' => 0,
    },
    add_to_cleanup      => [ 'XML::Grammar::ProductsSyndication-*' ],
    create_makefile_pl => 'passthrough',
    meta_merge =>
    {
        resources =>
        {
            repository => 'http://bitbucket.org/shlomif/perl-xml-grammar-productssyndication',
        },
    },
);

$builder->create_build_script();


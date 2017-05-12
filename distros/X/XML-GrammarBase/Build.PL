use strict;
use warnings;

use lib "./inc";

use Test::Run::Builder;

my $builder = Test::Run::Builder->new(
    module_name         => 'XML::GrammarBase',
    license             => 'mit',
    dist_author         => q{Shlomi Fish <shlomif@cpan.org>},
    dist_version_from   => 'lib/XML/GrammarBase.pm',
    configure_requires => {
        'Module::Build' => '0.36',
    },
    requires => {
        'autodie' => 0,
        'File::ShareDir' => 0,
        'Moo::Role' => 0,
        'MooX' => 0,
        'MooX::Role' => 0,
        'MooX::late' => 0,
        'MooX::Types::MooseLike' => 0,
        'Package::Variant' => 0,
        'perl' => '5.008',
        'strict' => 0,
        'warnings' => 0,
        'XML::LibXML' => '2.0017',
        'XML::LibXSLT' => '1.80',
    },
    build_requires => {
        'File::Temp' => 0,
        'Test::More' => 0,
        'Test::XML::Ordered' => 0,
    },
    add_to_cleanup      => [ 'XML-GrammarBase-*' ],
    meta_merge =>
    {
        resources =>
        {
            repository => "http://bitbucket.org/shlomif/perl-xml-grammarbase",
            homepage => "http://www.shlomifish.org/open-source/projects/XML-Grammar/Base/",
        },
        keywords =>
        [
            "abstraction",
            "base",
            "grammar",
            "moo",
            "moose",
            "relaxng",
            "rng",
            "role",
            "roles",
            "xml",
            "xslt",
        ],
    }
);

$builder->create_build_script();

use strict;
use warnings;

use 5.014;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use XML::Grammar::Builder;

my $builder = XML::Grammar::Builder->new(
    module_name         => 'XML::Grammar::Fortune',
    license             => 'mit',
    dist_author         => 'Shlomi Fish <shlomif@iglu.org.il>',
    dist_version_from   => 'lib/XML/Grammar/Fortune.pm',
    configure_requires =>
    {
        'Module::Build' => '0.36',
    },
    requires =>
    {
        'File::Spec' => 0,
        'perl' => "5.014",
        'Text::Format' => 0,
        'vars' => 0,
        'warnings' => 0,
        'XML::LibXML' => '2.0017',
        'XML::LibXSLT' => '1.80',
        'XML::GrammarBase::Role::RelaxNG' => '0.2.2',
        'XML::GrammarBase::Role::XSLT' => '0.2.2',
        'MooX' => 0,
        'MooX::late' => 0,
    },
    build_requires =>
    {
        'IO::String' => 0,
        'Test::Differences' => 0,
        'Test::More' => 0,
        'Test::XML::Ordered' => 0,
    },
    add_to_cleanup      => [ 'XML-Grammar-Fortune-*' ],
    meta_merge =>
    {
        resources =>
        {
            repository => "https://bitbucket.org/shlomif/fortune-xml",
            homepage => "http://web-cpan.berlios.de/modules/XML-Grammar-Fortune/",
            "Freshmeat" => "http://freshmeat.net/projects/fortune-xml",
        },
        keywords =>
        [
            "convert",
            "fortune",
            "fortunes",
            "grammar",
            "markup",
            "meta-data",
            "quotation",
            "quotations",
            "quote",
            "quotes",
            "text",
            "unix",
            "xml",
        ],
    },
);

$builder->create_build_script();

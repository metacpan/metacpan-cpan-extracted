use t::TestYAMLPerl tests => 8;

use YAML::Perl::Loader;

package YAML::Scanner::Darkly;
use YAML::Perl::Scanner -base;

package YAML::Reader::Digest;
use YAML::Perl::Reader -base;

package main;

my $loader = YAML::Perl::Loader->new(
    scanner_class => 'YAML::Scanner::Darkly',
    reader_class => 'YAML::Reader::Digest',
);

is $loader->parser->scanner_class, 'YAML::Scanner::Darkly',
    'Loader propagates class names';

is $loader->scanner->reader_class, 'YAML::Reader::Digest',
    'Loader propagates a second class name';

is ref($loader->scanner), 'YAML::Scanner::Darkly',
    'Scanner object is correct';

is ref($loader->reader), 'YAML::Reader::Digest',
    'Reader object is correct';

###
use YAML::Perl;
$loader = YAML::Perl->loader;
$loader->scanner_class('YAML::Scanner::Darkly')
       ->reader_class('YAML::Reader::Digest');

is $loader->parser->scanner_class, 'YAML::Scanner::Darkly',
    'Loader propagates class names';

is $loader->scanner->reader_class, 'YAML::Reader::Digest',
    'Loader propagates a second class name';

is ref($loader->scanner), 'YAML::Scanner::Darkly',
    'Scanner object is correct';

is ref($loader->reader), 'YAML::Reader::Digest',
    'Reader object is correct';

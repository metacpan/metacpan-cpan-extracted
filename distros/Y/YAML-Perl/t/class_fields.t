use t::TestYAMLPerl tests => 6;

use YAML::Perl;

my $y1 = YAML::Perl->new();

is $y1->loader_class, 'YAML::Perl::Loader',
    'Default Loader class is correct';
is $y1->dumper_class, 'YAML::Perl::Dumper',
    'Default Dumper class is correct';

my $y2 = YAML::Perl->new(
    loader_class => 'YAML::Perl::Loader::Foo',
    dumper_class => 'YAML::Perl::Dumper::Foo',
);

is $y2->loader_class, 'YAML::Perl::Loader::Foo',
    'Override Loader class is correct';
is $y2->dumper_class, 'YAML::Perl::Dumper::Foo',
    'Override Dumper class is correct';

$YAML::Perl::LoaderClass = 'YAML::Perl::Loader::Bar';
$YAML::Perl::DumperClass = 'YAML::Perl::Dumper::Bar';

my $y3 = YAML::Perl->new();

is $y3->loader_class, 'YAML::Perl::Loader::Bar',
    'Global override Loader class is correct';
is $y3->dumper_class, 'YAML::Perl::Dumper::Bar',
    'Global override Dumper class is correct';

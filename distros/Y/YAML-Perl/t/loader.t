use t::TestYAMLPerl; # tests => 3;

use YAML::Perl::Loader;

spec_file('t/data/parser_emitter');
filters {
    yaml => 'load_yaml',
    perl => 'eval',
};

run_is_deeply yaml => 'perl';

sub load_yaml {
    my $l = YAML::Perl::Loader->new();
    $l->open($_);
    $l->load();
}

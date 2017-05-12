use t::TestYAMLPerl; # tests => 3;

use YAML::Perl::Constructor;
use YAML::Perl::Nodes;

spec_file('t/data/parser_emitter');
filters {
    yaml => 'construct_yaml',
    perl => 'eval',
};

run_is_deeply yaml => 'perl';

sub construct_yaml {
    my $c = YAML::Perl::Constructor->new();
    $c->open($_);
    $c->construct();
}

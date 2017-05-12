use t::TestYAMLPerl; # tests => 2;

use YAML::Perl::Representer;

spec_file('t/data/parser_emitter');
filters {
    perl => [qw'eval represent'],
    dump => 'assert_dump_for_dumper',
};

run_is perl => 'dump';

sub represent {
    $_ = YAML::Perl::Representer->new()
        ->open()
        ->represent(@_);
}

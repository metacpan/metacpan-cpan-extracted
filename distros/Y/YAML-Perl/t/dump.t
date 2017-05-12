use t::TestYAMLPerl; # tests => 4;

use YAML::Perl;
no_diff;

spec_file('t/data/parser_emitter');
filters {
    perl => ['eval', 'dump_yaml'],
    dump => 'assert_dump_for_dumper',
};

run_is perl => 'dump';

sub dump_yaml {
    Dump(@_);
}


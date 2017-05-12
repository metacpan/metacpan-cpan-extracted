use t::TestYAMLPerl tests => 4;

use YAML::Perl;

ok defined(&Dump),
    'YAML::Perl::Dump is exported';
ok defined(&Load),
    'YAML::Perl::Load is exported';

ok not(defined(&DumpFile)),
    'YAML::Perl::DumpFile in not exported';
ok not(defined(&LoadFile)),
    'YAML::Perl::LoadFile in not exported';

use t::TestYAMLPerl tests => 1;

use YAML::Perl;
use YAML::Perl::Loader;
use YAML::Perl::Constructor;
use YAML::Perl::Composer;
use YAML::Perl::Parser;
use YAML::Perl::Scanner;
use YAML::Perl::Reader;

pass "TODO";
exit;

is_deeply XXX YAML::Perl::Load("---\n- 4\n- 4\n"), [2, 4],
    'Test YAML::Perl::Load';

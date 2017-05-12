use Test::More;

use_ok 'YAML::Full';

for my $module (qw(
    Loader
    Dumper
    Constructor
    Representer
    Composer
    Serializer
    Parser
    Emitter
    Base
    Node
)) {
    use_ok "YAML::Full::$module";
}

done_testing;

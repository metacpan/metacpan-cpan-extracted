use t::TestYAMLPerl tests => 15 * 2 - 2;

# These are all of the (Perl version of the) modules that PyYaml defines:
my @modules = (qw'
    YAML::Perl
    YAML::Perl::Composer
    YAML::Perl::Constructor
    YAML::Perl::Dumper
    YAML::Perl::Emitter
    YAML::Perl::Events
    YAML::Perl::Loader
    YAML::Perl::Nodes
    YAML::Perl::Parser
    YAML::Perl::Reader
    YAML::Perl::Representer
    YAML::Perl::Resolver
    YAML::Perl::Scanner
    YAML::Perl::Serializer
    YAML::Perl::Tokens
');
#     YAML::Perl::Error

for my $module (@modules) {
    use_ok($module);
    next if $module eq 'YAML::Perl::Events';
    next if $module eq 'YAML::Perl::Nodes';
    eval { $module->new() };
    is("$@", '', "Make a $module object");
}

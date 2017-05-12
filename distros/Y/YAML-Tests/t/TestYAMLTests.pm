package t::TestYAMLTests;
use Test::Base -Base;
@t::TestYAMLTests::EXPORT = qw(Load Dump);

sub load_config() {
    my $config_file = shift;
    my $config = {};
    return $config unless -f $config_file;
    open CONFIG, $config_file or die $!;
    my $yaml = do {local $/; <CONFIG>};
    if ($yaml =~ /^yaml_module:\s+([\w\:]+)/m) {
        $config->{yaml_module} = $1;
    }
    if ($yaml =~ /^use_blib:\s+([01])/m) {
        $config->{use_blib} = $1;
    }
    $config->{use_blib} ||= 0;
    return $config;
}

my $yaml_module;
BEGIN {
    my $config = load_config('t/yaml_tests.yaml');
    if ($config->{use_blib}) {
        eval "use blib; 1" or die $@;
    }
    $yaml_module = $ENV{PERL_YAML_TESTS_MODULE} || $config->{yaml_module}
      or die "Can't determine which YAML module to use for this test.";
    eval "require $yaml_module; 1" or die $@;
}

sub Load() {
    no strict 'refs';
    &{$yaml_module . "::Load"}(@_);
}
sub Dump() {
    no strict 'refs';
    &{$yaml_module . "::Dump"}(@_);
}

no_diff;
delimiters ('===', '+++');

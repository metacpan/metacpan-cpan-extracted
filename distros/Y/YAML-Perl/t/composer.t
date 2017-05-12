use t::TestYAMLPerl;

skip_all_unless_require('YAML::XS');

plan tests => 2;

use YAML::Perl::Composer;
use YAML::Perl::Events;

spec_file('t/data/parser_emitter');
filters {
    yaml => [qw'compose_yaml'],
    nodes => 'yaml_load',
};

run {
    my $block = shift;
    return unless $block->{yaml};
    my (@nodes) = @{$block->{yaml}};
    return unless $block->{nodes};
    my (@want) = @{$block->{nodes}}; 
    like ref($nodes[0]), qr/^YAML::Perl::Node::/,
        'compose() produces a YAML node';
};

sub event_string {
    map {
        my $string = ref($_);
        $string =~ s/^YAML::Perl::Event:://;
        if ($string eq 'Scalar') {
            $string .= " value " . $_->value;
        }
        $string .= "\n";
    } @_;
}

sub compose_yaml {
    my $c = YAML::Perl::Composer->new();
    $c->open($_);
    $c->compose();
}

sub yaml_load {
    YAML::XS::Load(@_);
}

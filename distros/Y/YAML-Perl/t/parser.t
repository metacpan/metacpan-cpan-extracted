use t::TestYAMLPerl; # tests => 3;

use YAML::Perl::Parser;
use YAML::Perl::Events;

spec_file('t/data/parser_emitter');
filters { yaml => [qw'parse_yaml event_string join'] };

run_is yaml => 'events';

sub event_string {
    map {
        my $event = ref($_);
        my $string = $event;
        $string =~ s/^YAML::Perl::Event:://;
        if ($_->can('version') and $_->version) {
            $string .= " version " . $_->version;
        }
        if ($_->can('anchor') and $_->anchor) {
            $string .= " anchor " . $_->anchor;
        }
        if ($event =~ /::Scalar$/) {
            my $value = $_->value;
            $value =~ s/\n/\\n/g;
            $string .= " value $value";
        }
        $string .= "\n";
    } @_;
}

sub parse_yaml {
    my $p = YAML::Perl::Parser->new();
    $p->open($_);
    $p->parse();
}

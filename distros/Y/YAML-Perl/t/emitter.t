use t::TestYAMLPerl; # tests => 2;

use YAML::Perl::Emitter;
use YAML::Perl::Events;

spec_file('t/data/parser_emitter');
filters {
    events => [qw(lines chomp make_events emit_yaml)],
    dump => 'assert_dump_for_emit',
};

run_is events => 'dump';

sub make_events {
    map {
        my ($event, %args) = split /\s+/, $_, 3;
        if (defined $args{value}) {
            $args{value} =~ s/\\n/\n/g;
        }
        "YAML::Perl::Event::$event"->new(%args);
   } @_;
}

sub emit_yaml {
    YAML::Perl::Emitter->new()
        ->open()
        ->emit(@_);
}

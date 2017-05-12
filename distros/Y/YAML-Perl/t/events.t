use t::TestYAMLPerl tests => 1;

use YAML::Perl::Events;

my $event = YAML::Perl::Event::Scalar->new(
    anchor => 'bar',
    implicit => 1,
);

is 
    "$event",
    'YAML::Perl::Event::Scalar(anchor=bar, implicit=1)',
    'YAML::Perl::Event objects stringifies correctly'
;

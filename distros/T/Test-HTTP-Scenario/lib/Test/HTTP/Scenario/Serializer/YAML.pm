package Test::HTTP::Scenario::Serializer::YAML;

use strict;
use warnings;
use Carp qw(croak carp);
use YAML::XS ();

#----------------------------------------------------------------------#
# Constructor
#----------------------------------------------------------------------#

sub new {
    my ($class) = @_;

    # Entry: class name
    # Exit:  new serializer object
    # Side effects: none
    # Notes: stateless object

    my $self = bless {}, $class;

    return $self;
}

#----------------------------------------------------------------------#
# Encoding
#----------------------------------------------------------------------#

sub encode_scenario {
    my ($self, $data) = @_;

    # Entry: hashref representing a scenario
    # Exit:  YAML string
    # Side effects: none
    # Notes: keys are sorted for deterministic output

    croak 'encode_scenario() requires a hashref'
        unless ref $data eq 'HASH';

    my $normalized = _normalize_structure($data);

    my $yaml = YAML::XS::Dump($normalized);

    return $yaml;
}

#----------------------------------------------------------------------#
# Decoding
#----------------------------------------------------------------------#

sub decode_scenario {
    my ($self, $text) = @_;

    # Entry: YAML string
    # Exit:  hashref representing a scenario
    # Side effects: none
    # Notes: validates that result is a hashref

    croak 'decode_scenario() requires a defined string'
        unless defined $text;

    my $data = YAML::XS::Load($text);

    croak 'decode_scenario() did not return a hashref'
        unless ref $data eq 'HASH';

    return $data;
}

#----------------------------------------------------------------------#
# Internal normalization
#----------------------------------------------------------------------#

sub _normalize_structure {
    my ($value) = @_;

    # Entry: arbitrary Perl structure
    # Exit:  structure with hashes sorted by key
    # Side effects: none
    # Notes: recursive normalization for deterministic dumps

    if (ref $value eq 'HASH') {
        my %out;
        for my $k (sort keys %{$value}) {
            $out{$k} = _normalize_structure($value->{$k});
        }
        return \%out;
    }

    if (ref $value eq 'ARRAY') {
        my @out = map { _normalize_structure($_) } @{$value};
        return \@out;
    }

    return $value;
}

1;

__END__

=head1 NAME

Test::HTTP::Scenario::Serializer::YAML - YAML serializer for Test::HTTP::Scenario

=head1 SYNOPSIS

  use Test::HTTP::Scenario::Serializer::YAML;

  my $ser = Test::HTTP::Scenario::Serializer::YAML

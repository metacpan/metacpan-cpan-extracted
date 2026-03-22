package Test::HTTP::Scenario::Serializer::JSON;

use strict;
use warnings;
use Carp qw(croak carp);
use JSON::MaybeXS ();

#----------------------------------------------------------------------#
# Constructor
#----------------------------------------------------------------------#

sub new {
    my ($class) = @_;

    # Entry: class name
    # Exit:  new serializer object
    # Side effects: none
    # Notes: holds a JSON encoder and decoder

    my $json = JSON::MaybeXS->new(
        utf8           => 0,
        pretty         => 1,
        canonical      => 1,
        allow_nonref   => 0,
    );

    my $self = bless {
        json => $json,
    }, $class;

    return $self;
}

#----------------------------------------------------------------------#
# Encoding
#----------------------------------------------------------------------#

sub encode_scenario {
    my ($self, $data) = @_;

    # Entry: hashref representing a scenario
    # Exit:  JSON string
    # Side effects: none
    # Notes: canonical output for deterministic fixtures

    croak 'encode_scenario() requires a hashref'
        unless ref $data eq 'HASH';

    my $json = $self->{json}->encode($data);

    return $json;
}

#----------------------------------------------------------------------#
# Decoding
#----------------------------------------------------------------------#

sub decode_scenario {
    my ($self, $text) = @_;

    # Entry: JSON string
    # Exit:  hashref representing a scenario
    # Side effects: none
    # Notes: validates that result is a hashref

    croak 'decode_scenario() requires a defined string'
        unless defined $text;

    my $data = $self->{json}->decode($text);

    croak 'decode_scenario() did not return a hashref'
        unless ref $data eq 'HASH';

    return $data;
}

1;

__END__

=head1 NAME

Test::HTTP::Scenario::Serializer::JSON - JSON serializer for Test::HTTP::Scenario

=head1 SYNOPSIS

  use Test::HTTP::Scenario::Serializer::JSON;

  my $ser = Test::HTTP::Scenario::Serializer::JSON->new;
  my $json = $ser->encode_scenario(\%data);
  my $data = $ser->decode_scenario($json);

=head1 DESCRIPTION

This module provides JSON based serialization for Test::HTTP::Scenario.
It uses JSON::MaybeXS with canonical output so that fixture files are
deterministic.

=head1 METHODS

=head2 new

Constructs a new serializer object.

=head2 encode_scenario

Takes a hashref representing a scenario and returns a JSON string.

=head2 decode_scenario

Takes a JSON string and returns a hashref representing a scenario.

=head1 NOTES

This module assumes that scenario data structures contain only simple
scalars, arrays and hashes.

=cut

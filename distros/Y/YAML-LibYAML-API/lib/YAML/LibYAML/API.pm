# ABSTRACT: Wrapper around the C libyaml library
package YAML::LibYAML::API;
use strict;
use warnings;

our $VERSION = '0.012'; # VERSION

use YAML::PP::Common qw/
    YAML_ANY_SCALAR_STYLE YAML_PLAIN_SCALAR_STYLE
    YAML_SINGLE_QUOTED_SCALAR_STYLE YAML_DOUBLE_QUOTED_SCALAR_STYLE
    YAML_LITERAL_SCALAR_STYLE YAML_FOLDED_SCALAR_STYLE
    YAML_QUOTED_SCALAR_STYLE

    YAML_ANY_SEQUENCE_STYLE
    YAML_BLOCK_SEQUENCE_STYLE YAML_FLOW_SEQUENCE_STYLE

    YAML_ANY_MAPPING_STYLE
    YAML_BLOCK_MAPPING_STYLE YAML_FLOW_MAPPING_STYLE
/;

my @scalar_styles = (
    YAML_ANY_SCALAR_STYLE,
    YAML_PLAIN_SCALAR_STYLE,
    YAML_SINGLE_QUOTED_SCALAR_STYLE,
    YAML_DOUBLE_QUOTED_SCALAR_STYLE,
    YAML_LITERAL_SCALAR_STYLE,
    YAML_FOLDED_SCALAR_STYLE,
);
my %scalar_styles;
@scalar_styles{ @scalar_styles } = 0 .. $#scalar_styles;

my @sequence_styles = (
    YAML_ANY_SEQUENCE_STYLE,
    YAML_BLOCK_SEQUENCE_STYLE,
    YAML_FLOW_SEQUENCE_STYLE,
);
my %sequence_styles;
@sequence_styles{ @sequence_styles } = 0 .. $#sequence_styles;

my @mapping_styles = (
    YAML_ANY_MAPPING_STYLE,
    YAML_BLOCK_MAPPING_STYLE,
    YAML_FLOW_MAPPING_STYLE,
);
my %mapping_styles;
@mapping_styles{ @mapping_styles } = 0 .. @mapping_styles;

# deprecated
sub parse_events {
    parse_string_events(@_);
}

sub parse_string_events {
    my ($yaml, $events) = @_;
    YAML::LibYAML::API::XS::parse_string_events($yaml, $events);
    _numeric_to_string($events);
}

sub parse_file_events {
    my ($file, $events) = @_;
    YAML::LibYAML::API::XS::parse_file_events($file, $events);
    _numeric_to_string($events);
}

sub parse_filehandle_events {
    my ($fh, $events) = @_;
    YAML::LibYAML::API::XS::parse_filehandle_events($fh, $events);
    _numeric_to_string($events);
}

sub emit_string_events {
    my ($events, $options) = @_;
    $options ||= {};
    _string_to_numeric($events);
    return YAML::LibYAML::API::XS::emit_string_events($events, $options);
}

sub emit_file_events {
    my ($file, $events, $options) = @_;
    $options ||= {};
    _string_to_numeric($events);
    return YAML::LibYAML::API::XS::emit_file_events($file, $events, $options);
}

sub emit_filehandle_events {
    my ($fh, $events, $options) = @_;
    $options ||= {};
    _string_to_numeric($events);
    return YAML::LibYAML::API::XS::emit_filehandle_events($fh, $events, $options);
}

sub _numeric_to_string {
    my ($events) = @_;
    for my $event (@$events) {
        if ($event->{name} eq 'scalar_event') {
            $event->{style} = $scalar_styles[ $event->{style} ];
        }
        elsif ($event->{name} eq 'sequence_start_event') {
            $event->{style} = $sequence_styles[ $event->{style} ];
        }
        elsif ($event->{name} eq 'mapping_start_event') {
            $event->{style} = $mapping_styles[ $event->{style} ];
        }
    }
}

sub _string_to_numeric {
    my ($events) = @_;
    for my $event (@$events) {
        if ($event->{name} eq 'scalar_event') {
            $event->{style} = $scalar_styles{ $event->{style} };
        }
        elsif ($event->{name} eq 'sequence_start_event') {
            $event->{style} = $sequence_styles{ $event->{style} };
        }
        elsif ($event->{name} eq 'mapping_start_event') {
            $event->{style} = $mapping_styles{ $event->{style} };
        }
    }
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

YAML::LibYAML::API - Wrapper around the C libyaml library

=head1 SYNOPSIS

    use YAML::LibYAML::API::XS;

    my $version = YAML::LibYAML::API::XS::libyaml_version();

    my $yaml = <<'EOM';
    # An example of various kinds of events
    ---
    foo: &ALIAS bar
    'alias': *ALIAS
    tag: !!int 23
    list:
    - "doublequoted"
    - >
      folded
    - |-
      literal
    EOM

    # parse
    my $events = [];
    YAML::LibYAML::API::XS::parse_string_events($yaml, $events);
    # or:
    YAML::LibYAML::API::XS::parse_file_events($filename, $events);
    YAML::LibYAML::API::XS::parse_filehandle_events($fh, $events);

    # emit
    my $yaml = YAML::LibYAML::API::XS::emit_string_events($events);
    # or:
    YAML::LibYAML::API::XS::emit_file_events($filename, $events);
    YAML::LibYAML::API::XS::emit_filehandle_events($fh, $events);

=head1 DESCRIPTION

This module provides a thin wrapper around the C libyaml API.

Currently it provides functions for parsing and emitting events.

libyaml also provides a loader/dumper API to load/dump YAML into a list
of nodes. There's no wrapper for these functions yet.

This is just one of the first releases. The function names will eventually be
changed.

The sources of C<libyaml-dev> are included in this distribution. You can
build this module with the system libyaml instead, if you remove the libyaml
sources and call C<Makefile.PL> with C<WITH_SYSTEM_LIBYAML=1>.

=head1 SEE ALSO

=over

=item L<libyaml|https://github.com/yaml/libyaml>

=item L<YAML::XS>

=back

=head1 AUTHOR

Tina Müller <tinita@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2018 by Tina Müller

This library is free software and may be distributed under the same terms
as perl itself.

=cut

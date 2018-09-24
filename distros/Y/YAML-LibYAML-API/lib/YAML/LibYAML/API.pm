# ABSTRACT: Wrapper around the C libyaml library
package YAML::LibYAML::API;
use strict;
use warnings;

our $VERSION = '0.001'; # VERSION

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
    my $events = [];
    YAML::LibYAML::API::XS::parse_events($yaml, $events);

=head1 DESCRIPTION

This module provides a thin wrapper around the C libyaml API. Currently it
only provides a function for getting a list of parsing events for an input
string.

C<libyaml-dev> has to be installed.

=head1 SEE ALSO

=over

=item libyaml L<https://github.com/yaml/libyaml>

=item YAML::XS L<https://metacpan.org/pod/YAML::XS>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2018 by Tina Müller

This library is free software and may be distributed under the same terms
as perl itself.

=cut

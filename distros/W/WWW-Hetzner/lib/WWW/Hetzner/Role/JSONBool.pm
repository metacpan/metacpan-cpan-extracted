package WWW::Hetzner::Role::JSONBool;
# ABSTRACT: Helper role for JSON boolean values in the Hetzner API

our $VERSION = '0.102';

use Moo::Role;
use namespace::clean;


# The Cloud API only accepts JSON booleans for boolean fields; a Perl 0/1
# would be encoded as a JSON number and rejected as invalid_input (karr #30).
# Accepts plain truthy/falsy values, \0/\1 and JSON boolean objects alike.
sub _json_bool {
    my ($value) = @_;
    $value = $$value if ref $value eq 'SCALAR';
    return $value ? \1 : \0;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Role::JSONBool - Helper role for JSON boolean values in the Hetzner API

=head1 VERSION

version 0.102

=head1 SYNOPSIS

    package WWW::Hetzner::Cloud::API::Widgets;
    use Moo;
    with 'WWW::Hetzner::Role::JSONBool';

    sub create {
        my ($self, %params) = @_;
        my $body = { enabled => _json_bool($params{enabled}) };
        return $self->client->post('/widgets', $body);
    }

=head1 DESCRIPTION

The Hetzner API expects JSON booleans (C<true>/C<false>) for boolean fields.
A Perl C<0> or C<1> is encoded as a JSON number and the API rejects such a
request with C<invalid_input>. This role provides the C<_json_bool> helper
that normalizes a Perl value into a JSON boolean.

The helper is a plain function call, not a method call:

    $body->{enabled} = _json_bool($params{enabled});

=head2 _json_bool

    my $bool = _json_bool($value);

Normalizes C<$value> into a JSON boolean: C<\1> for a true value, C<\0> for
a false one. A C<\0> or C<\1> reference is dereferenced first, so C<\0>
becomes C<false> and not the true value of a reference.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-hetzner/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

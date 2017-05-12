package URI::urn::uuid;

use strict;
our $VERSION = '0.03';

use base qw(URI::urn);
use Data::UUID;

sub uuid {
    my $self = shift;
    my $nss  = $self->nss(@_);

    my $ug = Data::UUID->new;
    my $uuid = eval { $ug->from_string($nss) } or return;
    return lc $ug->to_string($uuid);
}

sub uuid_binary {
    my $self = shift;
    my $ug = Data::UUID->new;
    return eval { $ug->from_string($self->nss) } || undef;
}

1;
__END__

=head1 NAME

URI::urn::uuid - UUID URN Namespace

=head1 SYNOPSIS

  use URI;
  use URI::urn::uuid;

  my $uri = URI->new("urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6");
  $uri->uuid;        # f81d4fae-7dec-11d0-a765-00a0c91e6bf6
  $uri->uuid_binary; # in 128 bit binary form of Data::UUID

  $uri = URI->new("urn:uuid:");
  $uri->uuid( lc Data::UUID->new->create_str );

=head1 DESCRIPTION

URI::urn::uuid is an URI class that implement UUID URN namespace.

=head1 METHODS

=over 4

=item uuid

  $uuid = $uri->uuid;
  $old  = $uri->uuid($new);

Returns UUID string as a canonicalized, lowercase form. If the given
UUID format is invalid, it just returns undef.

=item uuid_binary

  $uuid_binary = $uri->uuid_binary;

Returns UUID as a 128 bit binary. Returns undef if the given UUID
format is invalid.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://www.ietf.org/rfc/rfc4122.txt>, L<Data::UUID>

=cut

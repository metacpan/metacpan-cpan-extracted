package WWW::Keycloak::Diff;

# ABSTRACT: Compare a Keycloak representation with the wanted state, without I/O

use strict;
use warnings;
use Scalar::Util qw( blessed );
use JSON::MaybeXS;

our $VERSION = '0.001';


my $JSON = JSON::MaybeXS->new( canonical => 1, allow_nonref => 1, convert_blessed => 1 );

sub changes {
  my ( $self, $current, $wanted ) = @_;
  $current = {} unless ref $current eq 'HASH';
  my %changes;
  for my $key ( keys %$wanted ) {
    my ( $have, $want ) = ( $current->{$key}, $wanted->{$key} );
    if ( ref $want eq 'HASH' ) {
      my $inner = $self->changes( ref $have eq 'HASH' ? $have : {}, $want );
      $changes{$key} = $self->merge( ref $have eq 'HASH' ? $have : {}, $want ) if %$inner;
      next;
    }
    $changes{$key} = $want unless $self->same( $have, $want );
  }
  return \%changes;
}


sub merge {
  my ( $self, $current, $wanted ) = @_;
  my %merged = %{ $current || {} };
  for my $key ( keys %$wanted ) {
    $merged{$key} = ref $wanted->{$key} eq 'HASH' && ref $merged{$key} eq 'HASH'
      ? $self->merge( $merged{$key}, $wanted->{$key} )
      : $wanted->{$key};
  }
  return \%merged;
}


sub same {
  my ( $self, $have, $want ) = @_;
  return 1 if !defined $have && !defined $want;
  return 0 if !defined $have || !defined $want;
  my ( $have_bool, $want_bool ) = ( $self->_bool($have), $self->_bool($want) );
  return $have_bool eq $want_bool ? 1 : 0 if defined $have_bool && defined $want_bool
    && ( $self->_is_bool($have) || $self->_is_bool($want) );
  if ( ref $have eq 'ARRAY' && ref $want eq 'ARRAY' && !grep { ref } @$have, @$want ) {
    # Keycloak returns lists like redirectUris sorted, whatever order they were sent in
    return $JSON->encode( [ sort @$have ] ) eq $JSON->encode( [ sort @$want ] ) ? 1 : 0;
  }
  return $JSON->encode($have) eq $JSON->encode($want) ? 1 : 0 if ref $have || ref $want;
  return "$have" eq "$want" ? 1 : 0;
}


sub _is_bool {
  my ( $self, $value ) = @_;
  return 1 if ref $value eq 'SCALAR' || ( blessed $value && $value->isa('JSON::PP::Boolean') );
  return 1 if JSON::MaybeXS::is_bool($value);
  return 1 if !ref $value && ( $value eq 'true' || $value eq 'false' );
  return 0;
}

sub _bool {
  my ( $self, $value ) = @_;
  return ${$value} ? 1 : 0 if ref $value eq 'SCALAR';
  return $value ? 1 : 0 if JSON::MaybeXS::is_bool($value);
  return if ref $value;
  return 1 if $value eq 'true' || $value eq '1';
  return 0 if $value eq 'false' || $value eq '0' || $value eq '';
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Keycloak::Diff - Compare a Keycloak representation with the wanted state, without I/O

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $changes = WWW::Keycloak::Diff->changes( $current, { enabled => \1, attributes => { a => 'b' } } );
    return unless %$changes;                        # nothing to do
    my $full = WWW::Keycloak::Diff->merge( $current, $wanted );

=head1 DESCRIPTION

The comparison behind every C<ensure_*> method of L<WWW::Keycloak::Admin>,
kept free of I/O so that L<Net::Async::Keycloak> uses the very same code.

Only the keys of the wanted state are looked at. Hashes are compared key by
key, so a wanted C<attributes> hash with one entry checks that entry and leaves
the others alone. Lists of plain values are compared as sets, because Keycloak
returns lists such as C<redirectUris> sorted; lists holding structures are
compared in order. Booleans compare equal
whatever their spelling: C<\1>, a JSON true, C<"true"> and C<1> are the same
value, and so are C<\0>, a JSON false, C<"false"> and C<0>. Everything else is
compared as a string, so C<3600> and C<"3600"> are equal.

=head2 changes

    my $changes = WWW::Keycloak::Diff->changes( \%current, \%wanted );

The keys that have to be written to turn the current state into the wanted
one, as a hash. A nested hash that differs comes back merged with its current
content, because Keycloak replaces such a hash as a whole. Empty when there is
nothing to do.

=head2 merge

    my $full = WWW::Keycloak::Diff->merge( \%current, \%wanted );

The current state with the wanted keys laid over it, nested hashes merged key
by key.

=head2 same

    WWW::Keycloak::Diff->same( $a, $b )

True when two values are the same in the sense described above.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-keycloak/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package WWW::Authentik::Diff;

# ABSTRACT: Compare an authentik representation with the wanted state, without I/O

use strict;
use warnings;
use Scalar::Util qw( blessed );
use JSON::MaybeXS;

our $VERSION = '0.001';


my $JSON = JSON::MaybeXS->new( canonical => 1, allow_nonref => 1, convert_blessed => 1 );

sub list_defaults {
  return { redirect_uris => { redirect_uri_type => 'authorization' } };
}


sub with_defaults {
  my ( $self, $key, $value ) = @_;
  my $defaults = $self->list_defaults->{$key};
  return $value unless $defaults && ref $value eq 'ARRAY';
  return [ map { ref $_ eq 'HASH' ? { %$defaults, %$_ } : $_ } @$value ];
}


sub changes {
  my ( $self, $current, $wanted ) = @_;
  $current = {} unless ref $current eq 'HASH';
  my %changes;
  for my $key ( keys %$wanted ) {
    my ( $have, $want ) = ( $current->{$key}, $self->with_defaults( $key, $wanted->{$key} ) );
    if ( ref $want eq 'HASH' ) {
      my $inner = $self->changes( ref $have eq 'HASH' ? $have : {}, $want );
      $changes{$key} = $self->merge( ref $have eq 'HASH' ? $have : {}, $want ) if %$inner;
      next;
    }
    $changes{$key} = $wanted->{$key} unless $self->same( $have, $want );
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
  if ( ref $have eq 'ARRAY' && ref $want eq 'ARRAY' ) {
    return 0 unless @$have == @$want;
    return $JSON->encode( [ sort map { $JSON->encode($_) } @$have ] )
        eq $JSON->encode( [ sort map { $JSON->encode($_) } @$want ] ) ? 1 : 0;
  }
  return $JSON->encode($have) eq $JSON->encode($want) ? 1 : 0 if ref $have || ref $want;
  return 1 if "$have" eq "$want";
  # authentik trims leading and trailing whitespace off every text field, so a
  # wanted value that carries any can never be reached and would report a
  # change on every run. Only this one direction counts as equal: what is
  # stored is exactly the trimmed form of what was asked for. Values inside
  # `attributes` keep their whitespace, and there a difference is still a
  # difference.
  return 1 if "$have" eq ( "$want" =~ s/\A\s+//r =~ s/\s+\z//r );
  return 0;
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
  # undef, not a bare return: the caller takes two of these in a list, where
  # an empty return would shift the second value into the first slot
  return undef if ref $value;
  return 1 if $value eq 'true' || $value eq '1';
  return 0 if $value eq 'false' || $value eq '0' || $value eq '';
  return undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Authentik::Diff - Compare an authentik representation with the wanted state, without I/O

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $changes = WWW::Authentik::Diff->changes( $current, { name => 'probe', attributes => { a => 'b' } } );
    return unless %$changes;                        # nothing to do
    my $full = WWW::Authentik::Diff->merge( $current, $wanted );

=head1 DESCRIPTION

The comparison behind every C<ensure_*> method of L<WWW::Authentik::API>, kept
free of I/O so that L<Net::Async::Authentik> uses the very same code.

Only the keys of the wanted state are looked at. Hashes are compared key by
key, so a wanted C<attributes> hash with one entry checks that entry and leaves
the others alone; a nested hash that differs comes back merged, because
authentik replaces such a hash as a whole.

Every list is compared as a multiset: authentik hands C<property_mappings>
back in its own order, and in none of the lists this client writes does the
order carry meaning. Lists of hashes are compared the same way, each element
as canonical JSON.

Some fields come back with values authentik filled in. L</list_defaults> names
them, and L</with_defaults> lays them over the wanted value before the
comparison, so that writing a C<redirect_uris> entry without
C<redirect_uri_type> does not report a change on every run.

Booleans compare equal whatever their spelling: C<\1>, a JSON true, C<"true">
and C<1> are the same value, and so are C<\0>, a JSON false, C<"false"> and
C<0>. Everything else is compared as a string, so C<3600> and C<"3600"> are
equal.

One asymmetry: authentik trims leading and trailing whitespace off every text
field it stores, so a wanted C<"two lines\n"> comes back as C<"two lines">.
Such a value could never be reached and C<ensure_*> would report a change for
ever, so a stored value that is exactly the trimmed form of the wanted one
counts as equal. The comparison runs in that direction only: a stored value
with whitespace against a wanted one without it is still a difference, which
is what happens inside C<attributes>, where authentik keeps whitespace.

=head2 list_defaults

    my $defaults = WWW::Authentik::Diff->list_defaults;

The fields where authentik fills a value into every element of a list, as a
hash of field name to the defaults for one element. Override it in a subclass
when a later authentik version adds another.

=head2 with_defaults

    my $wanted = WWW::Authentik::Diff->with_defaults( redirect_uris => \@uris );

The value with L</list_defaults> laid under every element, so it can be
compared with what authentik stored. Anything that is not a list of hashes
comes back unchanged.

=head2 changes

    my $changes = WWW::Authentik::Diff->changes( \%current, \%wanted );

The keys that have to be written to turn the current state into the wanted
one, as a hash. A nested hash that differs comes back merged with its current
content. The values are the ones that were asked for, not the ones the
defaults were laid under. Empty when there is nothing to do.

=head2 merge

    my $full = WWW::Authentik::Diff->merge( \%current, \%wanted );

The current state with the wanted keys laid over it, nested hashes merged key
by key.

=head2 same

    WWW::Authentik::Diff->same( $a, $b )

True when two values are the same in the sense described above.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-authentik/issues>.

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

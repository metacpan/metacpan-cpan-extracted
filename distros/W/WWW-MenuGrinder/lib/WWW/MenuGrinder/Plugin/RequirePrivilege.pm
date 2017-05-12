package WWW::MenuGrinder::Plugin::RequirePrivilege;
BEGIN {
  $WWW::MenuGrinder::Plugin::RequirePrivilege::VERSION = '0.06';
}

# ABSTRACT: WWW::MenuGrinder plugin that does privilege checks on items.

use Moose;
use List::Util;

with 'WWW::MenuGrinder::Role::ItemMogrifier';

sub plugin_required_grinder_methods { qw(has_priv) }


sub item_mogrify {
  my ( $self, $item ) = @_;

  if (exists $item->{need_priv}) {
    my @privs = ref($item->{need_priv}) ? 
      @{ $item->{need_priv} } : $item->{need_priv};

    for my $priv (@privs) {
      if (! $self->grinder->has_priv($priv) ) {
        return ();
      }
    }
  }

  if (exists $item->{no_priv}) {
    my @privs = ref($item->{no_priv}) ?
      @{ $item->{no_priv} } : $item->{no_priv};

    for my $priv (@privs) {
      if ($self->grinder->has_priv($priv) ) {
        return ();
      }
    }
  }

  if (exists $item->{need_user}) {
    return () unless $self->grinder->has_user;
  }

  if (exists $item->{no_user}) {
    return () if $self->grinder->has_user;
  }

  if (exists $item->{need_user_in_realm}) {
    return () unless $self->grinder->has_user_in_realm($item->{need_user_in_realm});
  }

  if (exists $item->{no_user_in_realm}) {
    return () if $self->grinder->has_user_in_realm($item->{need_user_in_realm});
  }

  return $item;
}

__PACKAGE__->meta->make_immutable;

no Moose;
1;


__END__
=pod

=head1 NAME

WWW::MenuGrinder::Plugin::RequirePrivilege - WWW::MenuGrinder plugin that does privilege checks on items.

=head1 VERSION

version 0.06

=head1 DESCRIPTION

C<WWW::MenuGrinder::Plugin::RequirePrivilege> is a plugin for
C<WWW::MenuGrinder>. You should not use it directly, but include it in the
C<plugins> section of a C<WWW::MenuGrinder> config.

When loaded, this plugin will remove any menu item containing one of the
following keys, along with all of that item's children, if the current request's
user doesn't meet a specific requirement:

=over 4

=item * C<need_user>

The item will only be displayed if a user is logged in.

=item * C<no_user>

The item will only be displayed if a user is not logged in.

=item * C<need_user_in_realm>

The item will only be displayed if a user is logged into the realm identified by
this key.

=item * C<no_user_in_realm>

The item will only be displayed if a user is not logged into the realm
identified by this key.

=item * C<need_priv>

The item will only be displayed if the user possesses the privilege identified
by this key.

=item * C<no_priv>

The item will only be displayed if the user does not possess the privilege
identified by this key.

=back

=head2 Configuration

None.

=head2 Required Methods

In order to load this plugin your C<WWW::MenuGrinder> subclass must implement
the method C<has_priv>, which receives a privilege name as a string and returns
true or false indicating whether the privilege check was successful.

=head1 AUTHOR

Andrew Rodland <andrew@hbslabs.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by HBS Labs, LLC..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


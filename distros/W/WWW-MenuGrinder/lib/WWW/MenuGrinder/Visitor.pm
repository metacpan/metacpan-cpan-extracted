package WWW::MenuGrinder::Visitor;
BEGIN {
  $WWW::MenuGrinder::Visitor::VERSION = '0.06';
}

# ABSTRACT: WWW::MenuGrinder plugin that allows item-by-item mogrification.

use Moose;

use Scalar::Util;

# Nothing on CPAN gives me a nice simple interface as well as post-order
# traversal so here's one we prepared earlier.

# Traverse a tree-like data structure, making a copy of it and modifying it 
# along the way.
sub _visit {
  my ( $obj, $cb ) = @_;

  my $reftype = Scalar::Util::reftype($obj);

  if ( defined $reftype ) {
    # Don't bother with any fancy inheritance checks, just mostly leave objects
    # alone.
    if (Scalar::Util::blessed($obj)) {
      return $cb->{OBJECT}->($obj) if defined $cb->{OBJECT};
      return $obj;
    }
    if ( $reftype eq 'HASH' ) {
      my $tmp = {};
      for my $key ( keys %{$obj} ) {
        my @ret = _visit( $_[0]{$key}, $cb );
        $tmp->{$key} = $ret[0] if @ret;
      }

      return $cb->{HASH}->($tmp) if exists $cb->{HASH};
      return $tmp;
    } elsif ( $reftype eq 'ARRAY' ) {
      my $tmp = [];
      for my $val ( @{$obj} ) {
        push @$tmp, _visit( $val, $cb );
      }

      return $cb->{ARRAY}->($tmp) if exists $cb->{ARRAY};
      return $tmp;
    } elsif ( $reftype eq 'SCALAR' ) {
      my $tmp = \( _visit( $$obj, $cb ) );

      return $cb->{SCALARREF}->($tmp) if exists $cb->{SCALARREF};
      return $tmp;
    } elsif ( $reftype eq 'GLOB' ) {
      my $tmp = $obj;
      return $cb->{GLOB}->($tmp) if exists $cb->{GLOB};
      return $tmp;
    } else {
      warn "Ignoring a $reftype-reference I don't know how to handle.";
      return $obj;
    }
  } else {    # Not a reference
    return $cb->{SCALAR}->($obj) if defined $cb->{SCALAR};
    return $obj;
  }
}

sub visit_menu {
  my ( $self, $menu, $actions ) = @_;

#  warn "Doing at once: ", (join ", ", map { $_->{plugin} } @$actions), "\n";

  $menu = _visit($menu, {
      HASH => sub {
        my ( $item ) = @_;
        for my $action (@$actions) {
          my $plugin = $action->{plugin};
          my $method = $action->{method};
          $item = $plugin->$method($item);
          return () unless defined $item;
        }
        return $item;
      },
    }
  );

  return $menu;
}

__PACKAGE__->meta->make_immutable;

no Moose;
1;


__END__
=pod

=head1 NAME

WWW::MenuGrinder::Visitor - WWW::MenuGrinder plugin that allows item-by-item mogrification.

=head1 VERSION

version 0.06

=head1 DESCRIPTION

C<WWW::MenuGrinder::Visitor> is utility class for C<WWW::MenuGrinder>. It's not
especially meant for external use. It applies a series of actions to the menu on
an item-by-item basis.

=head1 AUTHOR

Andrew Rodland <andrew@hbslabs.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by HBS Labs, LLC..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


package WWW::MenuGrinder::Plugin::ActivePath;
BEGIN {
  $WWW::MenuGrinder::Plugin::ActivePath::VERSION = '0.06';
}

# ABSTRACT: WWW::MenuGrinder plugin that finds a path to the currently active page.

use Moose;
use List::Util;

with 'WWW::MenuGrinder::Role::ItemMogrifier';
with 'WWW::MenuGrinder::Role::BeforeMogrify';

has path => ( is => 'rw' );

has active_child_ref => (
  is => 'rw',
  default => 0,
);

sub plugin_required_grinder_methods { qw(path) }

sub before_mogrify {
  my ($self) = @_;

  $self->path( $self->grinder->path );
}

has 'longest' => (
  is => 'rw',
  default => 0
);

sub item_mogrify_methods {
  qw(find_longest_match mark_active_path)
};

sub find_longest_match {
  my ( $self, $item ) = @_;

  if (exists $item->{location}) {
    my @loc = ref($item->{location}) eq 'ARRAY' ? 
      @{ $item->{location} } : $item->{location};

    for my $location ( @loc ) {

      my $active;
      # XML::Simple is stupid
      if ($location eq '' or (ref($location) && ref($location) eq 'HASH') ) { 
        $active = 0.01; # more than 0, less than 1
      } elsif ( $self->path =~ m#^\Q$location\E(/|$)# ) {
        $active = length($location);
      }

      if (defined $active && $active > $self->longest) {
        $self->longest( $active );
        # This one might be the longest, so we might use it later.
        # If not, we'll delete it.
        $item->{active} = $active;
      }
    }
  }

  return $item;
}

sub mark_active_path {
  my ( $self, $item ) = @_;

  # If we were the longest match, set active="yes".
  # If one of our children is active (of either type) set active="child".

  my $max = $self->longest;

  if (defined $item->{active} and $item->{active} == $max) {
    $item->{active} = "yes";
  } else {
    delete $item->{active};
    if (ref ($item->{item})) {
      for my $child ( @{ $item->{item} } ) {
        if (defined $child->{active}) {
          $item->{active} = "child";
          $item->{active_child} = $child if $self->active_child_ref;
          last;
        }
      }
    }
  }

  return $item;
}

sub cleanup {
  my ($self) = @_;
  $self->longest(0);
}

__PACKAGE__->meta->make_immutable;

no Moose;
1;


__END__
=pod

=head1 NAME

WWW::MenuGrinder::Plugin::ActivePath - WWW::MenuGrinder plugin that finds a path to the currently active page.

=head1 VERSION

version 0.06

=head1 DESCRIPTION

C<WWW::MenuGrinder::Plugin::ActivePath> is a plugin for C<WWW::MenuGrinder>. You
should not use it directly, but include it in the C<plugins> section of a
C<WWW::MenuGrinder> config.

When loaded, this plugin will visit each item of the menu, comparing any item
with a C<location> attribute to the current URL path. The item that best matches
the current path will have its C<active> key set to "yes", and each of its
ancestors will have its C<active> key set to "child".

=head2 Configuration

=over 4

=item * C<active_child_ref>

Boolean (default: false). If set to a true value, items with C<active>="child"
will also have a key C<active_child>, which is a reference to its child which
is active.

=back

=head2 Required Methods

In order to load this plugin your C<WWW::MenuGrinder> subclass must implement
the method C<path> returning a path name for the current request.

=head2 Other Considerations

It's advisable to load this plugin after any plugins that may remove items from
the menu, to ensure that the chain of active items is unbroken.

=head1 AUTHOR

Andrew Rodland <andrew@hbslabs.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by HBS Labs, LLC..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


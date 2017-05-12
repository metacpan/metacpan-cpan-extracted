package WWW::MenuGrinder::Plugin::DefaultTarget;
BEGIN {
  $WWW::MenuGrinder::Plugin::DefaultTarget::VERSION = '0.06';
}

# ABSTRACT: WWW::MenuGrinder plugin that sets a default link target.

use Moose;

with 'WWW::MenuGrinder::Role::ItemMogrifier';

sub item_mogrify {
  my ($self, $item) = @_;

  if (exists $item->{location} && !exists $item->{target}) {
    if (ref $item->{location} eq "ARRAY") {
      $item->{target} = "/" . $item->{location}[0];
    } elsif (ref $item->{location} eq "HASH") {
      $item->{target} = "/"; # XML::Simple is stupid.
    } else {
      $item->{target} = "/" . $item->{location};
    }
  }

  return $item;
}

__PACKAGE__->meta->make_immutable;

no Moose;
1;


__END__
=pod

=head1 NAME

WWW::MenuGrinder::Plugin::DefaultTarget - WWW::MenuGrinder plugin that sets a default link target.

=head1 VERSION

version 0.06

=head1 DESCRIPTION

C<WWW::MenuGrinder::Plugin::DefaultTarget> is a plugin for C<WWW::MenuGrinder>.
You should not use it directly, but include it in the C<plugins> section of a
C<WWW::MenuGrinder> config.

When loaded, this plugin will create a C<target> (link target) key for each item
of the menu that doesn't have one, but which does have a C<location> key. If an
item has multiple C<locations>, the first is used to set the C<target>.

=head2 Configuration

None.

=head2 Required Methods

None.

=head1 AUTHOR

Andrew Rodland <andrew@hbslabs.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by HBS Labs, LLC..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


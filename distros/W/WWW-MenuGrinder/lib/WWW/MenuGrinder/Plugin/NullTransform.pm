package WWW::MenuGrinder::Plugin::NullTransform;
BEGIN {
  $WWW::MenuGrinder::Plugin::NullTransform::VERSION = '0.06';
}

# ABSTRACT: WWW::MenuGrinder plugin that generates hotkeys from labels.

use Moose;

with 'WWW::MenuGrinder::Role::Mogrifier';

sub mogrify {
  my ($self, $menu) = @_;

  return $menu;
}

__PACKAGE__->meta->make_immutable;

no Moose;
1;


__END__
=pod

=head1 NAME

WWW::MenuGrinder::Plugin::NullTransform - WWW::MenuGrinder plugin that generates hotkeys from labels.

=head1 VERSION

version 0.06

=head1 DESCRIPTION

C<WWW::MenuGrinder::Plugin::NullTransform> is a plugin for C<WWW::MenuGrinder>.
You should not use it directly, but include it in the C<plugins> section of a
C<WWW::MenuGrinder> config.

This plugin makes no change to the menu at all, but it can be used to break up a
series of ItemMogrifier plugins to enforce that a complete pass over the menu
should be completed after running the preceding plugin and before running the
following plugin.

=head2 Configuration

None.

=head1 AUTHOR

Andrew Rodland <andrew@hbslabs.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by HBS Labs, LLC..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


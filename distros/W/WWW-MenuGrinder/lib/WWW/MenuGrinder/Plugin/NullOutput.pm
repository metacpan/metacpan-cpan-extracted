package WWW::MenuGrinder::Plugin::NullOutput;
BEGIN {
  $WWW::MenuGrinder::Plugin::NullOutput::VERSION = '0.06';
}

# ABSTRACT: WWW::MenuGrinder plugin that outputs the menu structure unchanged.

use Moose;

with 'WWW::MenuGrinder::Role::Output';

sub output {
  my ($self, $menu) = @_;

  return $menu;
}

__PACKAGE__->meta->make_immutable;

no Moose;
1;


__END__
=pod

=head1 NAME

WWW::MenuGrinder::Plugin::NullOutput - WWW::MenuGrinder plugin that outputs the menu structure unchanged.

=head1 VERSION

version 0.06

=head1 DESCRIPTION

C<WWW::MenuGrinder::Plugin::NullOutput> is a plugin for C<WWW::MenuGrinder>. You
should not use it directly, but include it in the C<plugins> section of a
C<WWW::MenuGrinder> config.

This is an output plugin that returns the menu structure as used by
C<WWW::MenuGrinder> plugins -- a tree of hashes representing menu items. This
format is suitable for passing to templating systems such as Template Toolkit or
Petal, as well as further processing in Perl.

=head1 AUTHOR

Andrew Rodland <andrew@hbslabs.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by HBS Labs, LLC..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


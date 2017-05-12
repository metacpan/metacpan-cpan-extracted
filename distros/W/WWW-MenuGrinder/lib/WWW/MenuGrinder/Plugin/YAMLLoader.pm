package WWW::MenuGrinder::Plugin::YAMLLoader;
BEGIN {
  $WWW::MenuGrinder::Plugin::YAMLLoader::VERSION = '0.06';
}

# ABSTRACT: WWW::MenuGrinder plugin that loads menus with YAML::XS.

use Moose;

use YAML::XS;

with 'WWW::MenuGrinder::Role::Loader';

has 'filename' => (
  is => 'rw',
);

sub load {
  my ($self) = @_;

  open my $menufh, '<:encoding(UTF-8)', $self->filename or die $!;
  my $menu_yaml = do { local $/; <$menufh> };

  my $menu = Load $menu_yaml;

  return $menu;
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;


__END__
=pod

=head1 NAME

WWW::MenuGrinder::Plugin::YAMLLoader - WWW::MenuGrinder plugin that loads menus with YAML::XS.

=head1 VERSION

version 0.06

=head1 DESCRIPTION

C<WWW::MenuGrinder::Plugin::YAMLLoader> is a plugin for C<WWW::MenuGrinder>. You
should not use it directly, but include it in the C<plugins> section of a
C<WWW::MenuGrinder> config.

This is an input plugin that uses L<YAML::Simple> to load a menu structure.

TODO example file.

=head2 Configuration

The key C<filename> in the global configuration holds the name of the file to be
read.

=head1 AUTHOR

Andrew Rodland <andrew@hbslabs.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by HBS Labs, LLC..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


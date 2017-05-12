package WWW::MenuGrinder::Plugin::XMLLoader;
BEGIN {
  $WWW::MenuGrinder::Plugin::XMLLoader::VERSION = '0.06';
}

# ABSTRACT: WWW::MenuGrinder plugin that loads menus with XML::Simple.

use Moose;

use XML::Simple;

with 'WWW::MenuGrinder::Role::Loader';

has 'filename' => (
  is => 'rw',
);

sub load {
  my ($self) = @_;

  # XML::Simple screws up UTF-8 somehow...
  open my $menufh, '<:encoding(UTF-8)', $self->filename or die $!;
  my $menu_xml = do { local $/; <$menufh> };

  my $menu = XMLin($menu_xml, ForceArray => [ qw(item) ]);

  return $menu;
}

sub BUILD {
  my ($self) = @_;

  my $filename = $self->grinder->config->{filename};
  die "config->{filename} is required" unless defined $filename;

  $self->filename($filename);
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;


__END__
=pod

=head1 NAME

WWW::MenuGrinder::Plugin::XMLLoader - WWW::MenuGrinder plugin that loads menus with XML::Simple.

=head1 VERSION

version 0.06

=head1 DESCRIPTION

C<WWW::MenuGrinder::Plugin::XMLLoader> is a plugin for C<WWW::MenuGrinder>. You
should not use it directly, but include it in the C<plugins> section of a
C<WWW::MenuGrinder> config.

This is an input plugin that uses L<XML::Simple> to load a menu structure.

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


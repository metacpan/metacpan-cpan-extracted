package Dist::Zilla::Plugin::ModuleShareDirs 6.012;
# ABSTRACT: install a directory's contents as module-based "ShareDir" content

use Moose;

use namespace::autoclean;

#pod =head1 SYNOPSIS
#pod
#pod In your F<dist.ini>:
#pod
#pod   [ModuleShareDirs]
#pod   Foo::Bar = shares/foo_bar
#pod   Foo::Baz = shares/foo_baz
#pod
#pod =cut

has _module_map => (
  is   => 'ro',
  isa  => 'HashRef',
  default => sub { {} },
);

sub find_files {
  my ($self) = @_;
  my $modmap = $self->_module_map;
  my @files;

  for my $mod ( keys %$modmap ) {
    my $dir = $modmap->{$mod};
    my @mod_files = grep { index($_->name, "$dir/") == 0 }
      @{ $self->zilla->files };
    push @files, @mod_files;
  }

  return \@files;
}

sub share_dir_map {
  my ($self) = @_;
  my $modmap = $self->_module_map;

  return unless keys %$modmap;
  return { module => $modmap };
}

around BUILDARGS => sub {
  my $orig = shift;
  my ($class, @arg) = @_;

  my $args = $class->$orig(@arg);
  my %copy = %{ $args };

  my $zilla = delete $copy{zilla};
  my $name  = delete $copy{plugin_name};

  return {
    zilla => $zilla,
    plugin_name => $name,
    _module_map => \%copy,
  }
};

with 'Dist::Zilla::Role::ShareDir';
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::ModuleShareDirs - install a directory's contents as module-based "ShareDir" content

=head1 VERSION

version 6.012

=head1 SYNOPSIS

In your F<dist.ini>:

  [ModuleShareDirs]
  Foo::Bar = shares/foo_bar
  Foo::Baz = shares/foo_baz

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

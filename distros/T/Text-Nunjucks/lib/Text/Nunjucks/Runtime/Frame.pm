package Text::Nunjucks::Runtime::Frame;
# ABSTRACT: A scope of template variables (runtime.js class Frame)

our $VERSION = '0.001';

use Moo;
use Text::Nunjucks::Runtime;
use namespace::autoclean;

# upstream: class Frame in src/runtime.js.

# constructor(parent, isolateWrites): variables is a bare bag (JS
# Object.create(null)); topLevel starts false and the compiler/environment
# flip it to true on the root frame, so it is rw.
has variables      => ( is => 'ro', default => sub { {} } );
has parent         => ( is => 'ro' );
has top_level      => ( is => 'rw', default => sub { 0 } );
has isolate_writes => ( is => 'ro' );

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  return $class->$orig(@args) if @args == 1 && ref $args[0] eq 'HASH';
  my ( $parent, $isolate_writes ) = @args;
  return $class->$orig( parent => $parent, isolate_writes => $isolate_writes );
};

sub set {
  my ( $self, $name, $val, $resolve_up ) = @_;

  # Allow variables with dots by automatically creating the nested structure.
  my @parts = split /\./, $name, -1;    # JS split('.') keeps trailing empties
  my $obj   = $self->variables;
  my $frame = $self;

  if ($resolve_up) {
    if ( $frame = $self->resolve( $parts[0], 1 ) ) {
      $frame->set( $name, $val );
      return;
    }
  }

  for my $i ( 0 .. $#parts - 1 ) {
    my $id = $parts[$i];
    # JS: if (!obj[id]) obj[id] = {};  -- JS falsiness (null/None too), not Perl's
    if ( Text::Nunjucks::Runtime->_falsy( $obj->{$id} ) ) {
      $obj->{$id} = {};
    }
    $obj = $obj->{$id};
  }

  $obj->{ $parts[-1] } = $val;
}

sub get {
  my ( $self, $name ) = @_;
  my $val = $self->variables->{$name};
  return $val if defined $val;                  # val !== undefined
  return Text::Nunjucks::Runtime->None;         # JS: return null
}

sub lookup {
  my ( $self, $name ) = @_;
  my $p   = $self->parent;
  my $val = $self->variables->{$name};
  return $val if defined $val;                  # val !== undefined

  # Port-only (k83): one call per frame up the chain, as upstream's lookup
  # recurses; a template that includes itself N deep stands on N frames or
  # more. Perl warns at the 100th nested call of a sub, at the call site; the
  # depth is bounded by memory, not by Perl (see Lib async_iter).
  no warnings 'recursion';
  return $p && $p->lookup($name);              # p && p.lookup(name)
}

sub resolve {
  my ( $self, $name, $for_write ) = @_;
  my $p = ( $for_write && $self->isolate_writes ) ? undef : $self->parent;
  my $val = $self->variables->{$name};
  return $self if defined $val;                 # val !== undefined

  # one call per frame up the chain, as in lookup (k83)
  no warnings 'recursion';
  return $p && $p->resolve($name);
}

sub push {
  my ( $self, $isolate_writes ) = @_;
  return ref($self)->new( $self, $isolate_writes );
}

sub pop {
  my ($self) = @_;
  return $self->parent;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Runtime::Frame - A scope of template variables (runtime.js class Frame)

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Engine-internal: one scope of variables while a template renders, linked to
its parent scope. The compiled template code creates and walks frames through
C<< Text::Nunjucks::Runtime->Frame >>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-text-nunjucks/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Text::Nunjucks::Nodes::CallExtension;
# ABSTRACT: AST node CallExtension (fields extName, prop, args, contentArgs), ported from nodes.js

our $VERSION = '0.001';

use Moo;
use Scalar::Util qw( blessed );
use Text::Nunjucks::Nodes::NodeList;
use namespace::autoclean;

extends 'Text::Nunjucks::Nodes::Node';

# upstream: Node.extend('CallExtension', { init, fields }) -- custom init,
# declared in nodes.js before CallExtensionAsync.

has extName     => ( is => 'rw' );
has prop        => ( is => 'rw' );
has args        => ( is => 'rw' );
has contentArgs => ( is => 'rw' );
has autoescape  => ( is => 'rw' );   # carried from the extension; not a field

sub typename { 'CallExtension' }
sub fields   { [ 'extName', 'prop', 'args', 'contentArgs' ] }

# init(ext, prop, args, contentArgs): note -- no lineno/colno. Upstream calls
# this.parent() first, which leaves lineno/colno undefined and then overwrites
# the four fields below, so the observable end state is exactly this hash.
#   extName = ext.__name || ext ; autoescape = ext.autoescape
# How an extension is represented in Perl is not yet decided; extName and
# autoescape are read as an object method or a hash key, else the value passes
# through (mirroring `ext.__name || ext` for a bare string ext).
sub BUILDARGS {
  my ( $class, $ext, $prop, $args, $contentArgs ) = @_;
  return {
    lineno      => undef,
    colno       => undef,
    extName     => ( _ext_attr( $ext, '__name' ) || $ext ),
    prop        => $prop,
    args        => ( $args || $class->_node_class('NodeList')->new ),
    contentArgs => ( $contentArgs || [] ),
    autoescape  => _ext_attr( $ext, 'autoescape' ),
  };
}

sub _ext_attr {
  my ( $ext, $prop ) = @_;
  return undef unless defined $ext && ref $ext;
  return ( $ext->can($prop) ? $ext->$prop : undef ) if blessed $ext;
  return $ext->{$prop} if ref $ext eq 'HASH';
  return undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Nodes::CallExtension - AST node CallExtension (fields extName, prop, args, contentArgs), ported from nodes.js

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Engine-internal: the C<CallExtension> node of the template AST that an
extension builds for a tag it claims; the L<Text::Nunjucks::Compiler> reads it.
See L<Text::Nunjucks::Nodes>.

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

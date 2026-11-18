package Text::Nunjucks::Nodes::UnaryOp;
# ABSTRACT: AST node UnaryOp (fields target), ported from nodes.js

our $VERSION = '0.001';

use Moo;
use namespace::autoclean;

extends 'Text::Nunjucks::Nodes::Node';

# nodes.js: const UnaryOp = Node.extend('UnaryOp', { fields: ['target'] });

has target => ( is => 'rw' );

sub typename { 'UnaryOp' }
sub fields   { [ 'target' ] }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Nodes::UnaryOp - AST node UnaryOp (fields target), ported from nodes.js

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Engine-internal: the C<UnaryOp> node of the template AST, the parent of the
concrete nodes that carry its fields; see L<Text::Nunjucks::Nodes>.

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

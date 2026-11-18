package Text::Nunjucks::Nodes::Value;
# ABSTRACT: Abstract AST node with a value field (nodes.js class Value)

our $VERSION = '0.001';

use Moo;
use namespace::autoclean;

extends 'Text::Nunjucks::Nodes::Node';

# upstream: class Value extends Node -- abstract, under "// Abstract nodes".

has value => ( is => 'rw' );

sub typename { 'Value' }
sub fields   { ['value'] }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Nodes::Value - Abstract AST node with a value field (nodes.js class Value)

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Engine-internal: the abstract parent of the C<Literal> and C<Symbol> nodes of
the template AST in L<Text::Nunjucks::Nodes>.

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

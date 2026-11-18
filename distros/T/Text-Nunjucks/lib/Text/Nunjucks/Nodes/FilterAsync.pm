package Text::Nunjucks::Nodes::FilterAsync;
# ABSTRACT: AST node FilterAsync (fields name, args, symbol), ported from nodes.js

our $VERSION = '0.001';

use Moo;
use namespace::autoclean;

extends 'Text::Nunjucks::Nodes::Filter';

# nodes.js: const FilterAsync = Filter.extend('FilterAsync', { fields: ['name', 'args', 'symbol'] });
# name and args are inherited from Filter; the accessor for symbol is new.

has symbol => ( is => 'rw' );

sub typename { 'FilterAsync' }
sub fields   { [ 'name', 'args', 'symbol' ] }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Nodes::FilterAsync - AST node FilterAsync (fields name, args, symbol), ported from nodes.js

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Engine-internal: the C<FilterAsync> node of the template AST that
L<Text::Nunjucks::Transformer> builds and L<Text::Nunjucks::Compiler> reads; see
L<Text::Nunjucks::Nodes>.

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

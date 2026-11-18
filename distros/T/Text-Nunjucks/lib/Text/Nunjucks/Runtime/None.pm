package Text::Nunjucks::Runtime::None;
# ABSTRACT: The JS null sentinel (ADR 0006)

our $VERSION = '0.001';

use strict;
use warnings;

# A port addition to runtime.js, at its ADR-designated home beside
# Text::Nunjucks::Runtime, which hands it out as Text::Nunjucks::Runtime->None.
#
# A single immutable process-wide sentinel standing for JS `null`. Perl
# `undef` is JS `undefined`; a present-but-null value is this object, so the
# null/undefined distinction (is defined / is none / is undefined,
# throwOnUndefined) survives set/macros/filters where an exists-check cannot.
# No stringification/bool overload on purpose: every output/compare/lookup
# path routes None through suppress_value / op_* / member_lookup, so a raw
# None that leaked into bare Perl concat should stay visible, not silently ''.

my $INSTANCE;
sub instance { $INSTANCE //= bless \( my $x ), __PACKAGE__ }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Runtime::None - The JS null sentinel (ADR 0006)

=head1 VERSION

version 0.001

=head1 DESCRIPTION

The one process-wide object standing for JavaScript C<null>, as
C<< Text::Nunjucks::Runtime->None >> returns it. Perl C<undef> is JavaScript
C<undefined>; a value that is present but null is this object.

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

package Text::Nunjucks::Runtime::KwArgs;
# ABSTRACT: Marker class for keyword arguments, the __keywords hash (ADR 0009)

our $VERSION = '0.001';

use strict;
use warnings;

# A port addition to runtime.js, at its ADR-designated home beside
# Text::Nunjucks::Runtime (whose ->KwArgs names this class).
#
# Marker class only. makeKeywordArgs blesses a caller hashref into this,
# mirroring JS `obj.__keywords = true` -- but the hash keys stay purely the
# keyword name=>value pairs (no __keywords key polluting them). Not a Moo
# class: its hash IS the data. isKeywordArgs is a blessed/isa check.

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Runtime::KwArgs - Marker class for keyword arguments, the __keywords hash (ADR 0009)

=head1 VERSION

version 0.001

=head1 DESCRIPTION

The class the engine blesses a keyword-argument hash into, for the
C<name=value> arguments of a call. Its keys are exactly the keyword names; it
has no methods.

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

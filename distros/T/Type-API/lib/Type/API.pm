package Type::API;

our $AUTHORITY = "cpan:TOBYINK";
our $VERSION   = "0.002";

1;

=pod

=encoding utf-8

=head1 NAME

Type::API - a common interface for type constraints, based on observed patterns (documentation only)

=head1 DESCRIPTION

This distribution documents common patterns used by type constraint
libraries: in particular the methods that type constraints typically
provide, their parameters, return values, and expected behaviour.

Type constraint libraries typically provide more methods than these,
but by restricting your code to making use of those documented in
Type::API, you may be able to improve your code's interoperability.

=over

=item *

L<Type::API::Constraint>

=item *

L<Type::API::Constraint::Coercible>

=item *

L<Type::API::Constraint::Constructor>

=item *

L<Type::API::Constraint::Inlinable>

=back

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

package Type::EmailAddress;
# ABSTRACT: type constraints for email addresses

use warnings;
use strict;
use Email::Valid ();
use Type::Utils qw(declare as where inline_as);
use Types::Standard qw( Str );
use Type::Library
   -base,
   -declare => qw( EmailAddress );

our $VERSION = '0.001'; # VERSION;

declare EmailAddress,
  as Str,
  where { Email::Valid->address( -address => $_ ) },
  inline_as {
     my ($constraint, $varname) = @_;
     return sprintf(
        '%s and Email::Valid->address( -address => %s )',
        $constraint->parent->inline_check($varname),
        $varname,
     );
  };

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Types::EmailAddress - type constraints for email addresses

=head1 DESCRIPTION

This module adds a type constraint for email address using L<Type::Tiny>
library. The validation is done using the L<Email::Valid> module.

=head2 Type constraints

=over

=item C<< EmailAddress >>

String representing a valid email address.

=back

=head1 SEE ALSO

L<Types::Standard>, L<Email::Address>.

=head1 AUTHOR

André Walker E<lt>andre@andrewalker.netE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by André Walker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

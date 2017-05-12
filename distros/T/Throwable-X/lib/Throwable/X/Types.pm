use strict;
use warnings;
package Throwable::X::Types;
{
  $Throwable::X::Types::VERSION = '0.007';
}
# ABSTRACT: private types used by Throwable::X


use Moose::Util::TypeConstraints;

subtype 'Throwable::X::_VisibleStr',
  as 'Str',
  where { length };

# We don't want vertical whitespace, but we also don't want it to be a format
# string, in case we default to it.  Rather than being really cagey and
# demanding we use %% and then we s/%%/% in the ident, we just forbid it.
# Let's not be too clever, just yet. -- rjbs, 2010-10-17
subtype 'Throwable::X::_Ident',
  as 'Throwable::X::_VisibleStr',
  where { /\S/ && ! /[%\x0d\x0a]/ };

# Another idea is to mark both lazy and then have a before BUILDALL (or
# something) that ensures that at least one is set and allows % in the ident as
# long as an explicit message_fmt was given.  I think this is probably better.
# -- rjbs, 2010-10-17

1;

__END__

=pod

=head1 NAME

Throwable::X::Types - private types used by Throwable::X

=head1 VERSION

version 0.007

=head1 DESCRIPTION

None of the types provided by Throwable::X::Types are meant for public
consumption.  Please do not rely on them.  They are likely to change.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

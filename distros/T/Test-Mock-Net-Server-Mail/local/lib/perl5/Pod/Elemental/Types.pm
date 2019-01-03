use strict;
use warnings;
package Pod::Elemental::Types;
# ABSTRACT: data types for Pod::Elemental
$Pod::Elemental::Types::VERSION = '0.103004';
use MooseX::Types -declare => [ qw(FormatName ChompedString) ];
use MooseX::Types::Moose qw(Str);

#pod =head1 OVERVIEW
#pod
#pod This is a library of MooseX::Types types used by Pod::Elemental.
#pod
#pod =head1 TYPES
#pod
#pod =head2 FormatName
#pod
#pod This is a valid name for a format (a Pod5::Region).  It does not expect the
#pod leading colon for pod-like regions.
#pod
#pod =cut

# Probably needs refining -- rjbs, 2009-05-26
subtype FormatName, as Str, where { length $_ and /\A\S+\z/ };

#pod =head2 ChompedString
#pod
#pod This is a string that does not end with newlines.  It can be coerced from a
#pod Str ending in a single newline -- the newline is dropped.
#pod
#pod =cut

subtype ChompedString, as Str, where { ! /\n\z/ };
coerce ChompedString, from Str, via { chomp; $_ };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Types - data types for Pod::Elemental

=head1 VERSION

version 0.103004

=head1 OVERVIEW

This is a library of MooseX::Types types used by Pod::Elemental.

=head1 TYPES

=head2 FormatName

This is a valid name for a format (a Pod5::Region).  It does not expect the
leading colon for pod-like regions.


=head2 ChompedString

This is a string that does not end with newlines.  It can be coerced from a
Str ending in a single newline -- the newline is dropped.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

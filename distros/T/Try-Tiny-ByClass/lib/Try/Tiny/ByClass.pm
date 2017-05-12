package Try::Tiny::ByClass;

use warnings;
use strict;

our $VERSION = '0.01';

use base qw(Exporter);

our @EXPORT = our @EXPORT_OK = qw(try catch finally catch_case);

use Try::Tiny qw(try catch finally);

use Dispatch::Class qw(dispatch);

sub catch_case ($@) {
	my $handlers = shift;
	&catch(dispatch(@$handlers, '*' => sub { die $_[0] }), @_)
}

'ok'

__END__

=head1 NAME

Try::Tiny::ByClass - selectively catch exceptions by class name

=head1 SYNOPSIS

  use Try::Tiny::ByClass;
  
  try {
  	die $exception_object;
  } catch_case [
    'Some::Class' => sub {
      # handle Some::Class exceptions
    },
    'Exception::DivByZero' => sub {
      # handle Exception::DivByZero exceptions
    },
  ], finally {
    # always do this
  };

=head1 DESCRIPTION

This module is a simple wrapper around L<C<Try::Tiny>|Try::Tiny>, which see. It
re-exports L<C<try>|Try::Tiny/try->, L<C<catch>|Try::Tiny/catch->, and
L<C<finally>|Try::Tiny/finally->.

In addition, it provides a way to catch only some exceptions by filtering on
the class (including superclasses and consumed roles) of an exception object.

=head2 Functions

=over

=item catch_case ($;@)

Intended to be used instead of L<C<catch>|Try::Tiny/catch-> in the second
argument position of L<C<try>|Try::Tiny/try->. 

Instead of a block it takes a reference to an array of C<< CLASS => CODEREF >>
pairs, which it passes on to C<dispatch> in
L<C<Dispatch::Class>|Dispatch::Class>.

=back

=head1 SEE ALSO

L<Try::Tiny>, L<Dispatch::Class>

=head1 AUTHOR

Lukas Mai, C<< <l.mai at web.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2013 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

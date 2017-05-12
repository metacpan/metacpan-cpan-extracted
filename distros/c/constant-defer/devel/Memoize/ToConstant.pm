# This was an idea to post-facto mangle a function to be run-once.
#
# Giving a name an anon-sub to constant::defer seems easier than making a
# named sub and then repeating the name to Memoize::ToConstant.
#
# (The _run() here is old, it doesn't make the first installed sub become
# the constant as well as the replacement ...)



# Copyright 2008, 2009 Kevin Ryde

# This file is part of constant-defer.
#
# constant-defer is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# constant-defer is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with constant-defer.  If not, see <http://www.gnu.org/licenses/>.

package Memoize::ToConstant;
use 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = 1;

# an alias for prammatic use ?
# *memoize_to_constant = \&import;

sub import {
  my $caller_package = caller;

  shift @_; # classname
  foreach my $arg (@_) {
    my ($fullname, $package, $basename);

    if ($arg =~ /(.*)::(.*)/s) {
      $fullname = $arg;
      $package = $1;
      $basename = $2;
    } else {
      $package = $caller_package;
      $basename = $arg;
      $fullname = "${caller_package}::$arg";
    }

    # can() might let a strange package autoload the given func, though
    # that'd be pretty unusual
    my $old = $package->can($basename)
      || croak "Function $fullname not defined";

    # print "ToConstant $arg -- $fullname $package $basename $old\n";

    no warnings;
    no strict 'refs';
    *$fullname = sub () { _run($fullname,$old,@_) };
  }
}

sub _run {
  my $fullname = shift;
  my $old = shift;
  # print "ToConstant $fullname $old\n";
  my @ret = $old->(@_);

  no warnings; #
  no strict 'refs';
  if (@ret == 0) {
    *$fullname = \&_nothing;
    return;
  }
  if (@ret == 1) {
    # constant.pm has an optimization to make a constant by storing a scalar
    # into the %Foo::Bar:: hash if there's no typeglob for the name yet.
    # But that doesn't apply here, there's always a typeglob having wrapped
    # and converted an existing function.
    #
    my $value = $ret[0];
    *$fullname = sub () { $value };
    return $value;
  }
  *$fullname = sub () { @ret };
  @ret;
}

sub _nothing () { }

1;
__END__

=head1 NAME

Memoize::ToConstant -- memoize functions to become constants

=head1 SYNOPSIS

 sub foo { ... };
 use Memoize::ToConstant 'foo';

 sub bar { ... };    # or a set of functions at once
 sub quux { ... };
 use Memoize::ToConstant 'bar','quux';

 use Memoize::ToConstant 'Some::Other::func';

=head1 DESCRIPTION

C<Memoize::ToConstant> modifies given functions so the first call runs
normally but then becomes a constant sub like C<use constant>.  The effect
is an on-demand calculation of a constant, or once-only run of some code.

The same sort of thing can be done with the main C<Memoize> module (see
L<Memoize>), but ToConstant doesn't have to keep track of different sets of
arguments (there's no arguments) and in particular it can discard the
original code after it runs, freeing some memory.

=head1 MULTIPLE VALUES

For consistency the original function is always run in array context, no
matter how the memoized wrapper is called.  The kind of constant sub the
function becomes then depends on the number of values returned.

=over 4

=item *

For no values the new sub is an empty C<sub () {}>.

=item *

For one value the new sub is a scalar return C<sub () { $result }>.  This is
the usual case and can be inlined by subsequently loaded code (ie. code
loaded after the first run).

=item *

For two or more values the new sub is an array return C<sub () { @result }>.
This is similar to what C<use constant> gives and in array context (which is
presumably the purpose of multiple values) it returns those multiple
results.

The only subtle thing to note is that when used in scalar context it means
the size of the array, ie. how many values.  This happens even if your
original function was a list style C<return(123,456)> which in scalar
context would normally mean last value in that list.

=back

=head1 FUNCTIONS

There are no functions as such, everything is accomplished through the
C<use> import.

=over 4

=item C<< use Memoize::ToConstant 'func' >>

=item C<< use Memoize::ToConstant 'Some::Package::func' >>

Modify the given C<func> to become a constant after the first call to it.
An unqualified name is taken to be in the caller package doing the C<use>.
That's the normal case, but a fully qualified name (anything with a C<::>)
can be given.  In either case the function must be defined before ToConstant
is applied,

    sub foo { ... };
    use Memoize::ToConstant 'foo';   # right

    use Memoize::ToConstant 'bar';   # WRONG!
    sub bar { ... };

=back

=head1 SEE ALSO

L<constant::defer>, L<Memoize>, L<Attribute::Memoize>, L<Memoize::Attrs>,
L<Data::Lazy>, L<Data::Thunk>, L<Scalar::Defer>, L<Scalar::Lazy>

=cut

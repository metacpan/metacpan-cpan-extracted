# Copyright 2008, 2009, 2010, 2011, 2012, 2015, 2017 Kevin Ryde

# This file is part of Test-VariousBits.
#
# Test-VariousBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Test-VariousBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Test-VariousBits.  If not, see <http://www.gnu.org/licenses/>.

package Test::Weaken::ExtraBits;
use 5.004;
use strict;

use vars '$VERSION', '@ISA', '@EXPORT_OK';
$VERSION = 8;

use Exporter;
@ISA = ('Exporter');
@EXPORT_OK = qw(
                 contents_glob_IO
                 ignore_Class_Singleton
                 ignore_DBI_globals
                 ignore_global_functions
                 ignore_functions
              );

use constant DEBUG => 0;

#------------------------------------------------------------------------------
sub contents_glob_IO {
  my ($ref) = @_;
  ref($ref) eq 'GLOB' || return;
  return *$ref{IO};
}

#------------------------------------------------------------------------------

sub ignore_Class_Singleton {
  my ($ref) = @_;
  my $class;
  require Scalar::Util;
  return (($class = Scalar::Util::blessed($ref))
          && $ref->isa('Class::Singleton')
          && $class->has_instance
          && $class->instance == $ref);
}

sub ignore_DBI_globals {
  my ($ref) = @_;
  require Scalar::Util;

  if (Scalar::Util::blessed($ref)
      && $ref->isa('DBI::dr')) {
    if (DEBUG) { Test::More::diag ("ignore DBI::dr object -- $ref\n"); }
    return 1;
  }

  return 0;
}

sub ignore_global_functions {
  my ($ref) = @_;
  ref $ref eq 'CODE' or return;

  # could use Sub::Identify, but B comes with perl already
  require B;
  my $cv = B::svref_2object($ref);
  my $gv = $cv->GV;
  # as per Sub::Identify, for some sort of undefined GV
  return if $gv->isa('B::SPECIAL');

  my $fullname = $gv->STASH->NAME . '::' . $gv->NAME;
  # Test::More::diag "ignore_global_functions() fullname $fullname";

  return (defined &$fullname && $ref == \&$fullname);
}
#   require Sub::Identify;
#   my $fullname = Sub::Identify::sub_fullname ($ref);
#   return (defined &$fullname
#           && $ref == \&$fullname);

sub ignore_functions {
  my $ref = shift;
  ref $ref eq 'CODE' or return;

  while (@_) {
    my $funcname = shift;
    if (defined &$funcname && $ref == \&$funcname) {
      return 1;
    }
  }
  return 0;
}

#------------------------------------------------------------------------------
# =item C<$bool = Test::Weaken::ExtraBits::contents_glob ($ref)>
# 
# If C<$ref> is a globref then return the contents of all of its slots,
# which means refs to
#
#     SCALAR ARRAY HASH CODE IO GLOB FORMAT
#
# C<Test::Weaken>, as of version 3.006, doesn't descend into globs.  This
# contents func can be used if that's desired.  Usually 
#
# sub contents_glob {
#   my ($ref) = @_;
#   if (ref $ref eq 'GLOB') {
#     return map {*$ref{$_}} qw(SCALAR ARRAY HASH CODE IO GLOB FORMAT);
#   } else {
#     return;
#   }
# }

# =item C<$bool = ignore_module_functions ($ref, $module, $module, ...)>
#
# Return true if C<$ref> is a coderef to any function in any of the given
# modules.
#
# Each C<$module> is a string like C<My::Module>.  If a module doesn't exist
# then it's skipped, so it doesn't matter if the C<My::Module> package is
# actually loaded yet.
#
# sub ignore_module_functions {
#   my $ref = shift;
#   ref $ref eq 'CODE' or return;
# 
#   while (@_) {
#     my $module = shift;
#     my $symtabname = "${module}::";
#     no strict 'refs';
#     %$symtabname or next;
#     foreach my $name (keys %$symtabname) {
#       my $fullname = "${module}::$name";
#       if (defined &$fullname && $ref == \&$fullname) {
#         return 1;
#       }
#     }
#   }
#   return 0;
# }

1;
__END__

=for stopwords globref dup coderef symtab backtraces coderefs lvalue ImplementorClass DBI Ryde Test-VariousBits redefinitions

=head1 NAME

Test::Weaken::ExtraBits -- various extras for Test::Weaken

=head1 SYNOPSIS

 use Test::Weaken::ExtraBits;

=head1 DESCRIPTION

This is a few helper functions for use with C<Test::Weaken>.

=head1 EXPORTS

Nothing is exported by default, but the functions can be requested
individually in the usual C<Exporter> style (see L<Exporter>).

    use Test::Weaken::ExtraBits qw(ignore_Class_Singleton);

=head1 FUNCTIONS

=head2 Contents

=over

=item C<$io = Test::Weaken::ExtraBits::contents_glob_IO ($ref)>

If C<$ref> is a globref then return the contents of its C<IO> slot.  This is
the underlying Perl I/O of a file handle.

Note that C<Test::Weaken> 3.006 doesn't track IO objects by default so to
detect leaks of them add to C<tracked_types> too,

    leaks (constructor => sub { ... },
           contents => \&Test::Weaken::ExtraBits::contents_glob_IO,
           tracked_types => ['IO']);

This is good for detecting an open file leaked through a Perl-level dup (see
L<perlfunc/open>) even after its original C<$fh> handle is destroyed and
freed.

    open my $dupfh, '<', $fh;
    # $dupfh holds and uses *$fh{IO}

=back

=head2 Ignores

=over 4

=item C<$bool = Test::Weaken::ExtraBits::ignore_global_functions ($ref)>

Return true if C<$ref> is a coderef to a global function like

    sub foo {}

A global function is identified by the C<$ref> having a name and the current
function under that name equal to this C<$ref>.  Plain functions created as
C<sub foo {}> etc work, but redefinitions or function-creating modules like
C<Memoize> or C<constant> generally don't.

The name in a coderef is essentially just a string from its original
creation.  Things like C<Memoize> etc often end up with anonymous functions.
C<constant> only ends up with a name in the symtab optimization case.

See L<Sub::Name> to add a name to a coderef, though you probably wouldn't
want that merely to make C<ignore_global_functions()> work.  (Though a name
can help C<caller()> and stack backtraces too.)

=item C<$bool = ignore_functions ($ref, $funcname, $funcname, ...)>

Return true if C<$ref> is a coderef to any of the given named functions.
This is designed for use when making an ignore handler,

    sub my_ignore_callback {
      my ($ref) = @_;
      return (ignore_functions ($ref, 'Foo::Bar::somefunc',
                                      'Quux::anotherfunc')
              || ...);
    }         

Each C<$funcname> argument should be a fully-qualified string like
C<Foo::Bar::somefunc>.  Any functions which doesn't exist are skipped, so it
doesn't matter if a particular package is loaded yet, etc.

If you've got coderefs to functions you want to ignore then there's no need
for C<ignore_functions()>, just test C<$ref==$mycoderef> etc.

=item C<$bool = Test::Weaken::ExtraBits::ignore_Class_Singleton ($ref)>

Return true if C<$ref> is the singleton instance object of a class using
C<Class::Singleton>.  If C<Class::Singleton> is not loaded or not used by
the C<$ref> object then return false.

Generally C<Class::Singleton> objects are permanent, existing for the
duration of the program.  This ignore helps skip them.

The current implementation requires C<Class::Singleton> version 1.04 for its
C<has_instance()> method.

=item C<$bool = Test::Weaken::ExtraBits::ignore_DBI_globals ($ref)>

Return true if C<$ref> is one of the various C<DBI> module global objects.

This is slightly dependent on the DBI implementation but currently means any
C<DBI::dr> driver object.  A driver object is created permanently for each
driver loaded.  C<DBI::db> handles (created and destroyed in the usual way)
refer to their respective driver object.

A bug in Perl through to at least 5.10.1 related to lvalue C<substr()> means
certain scratchpad temporaries holding "ImplementorClass" strings in DBI end
up still alive after C<DBI::db> and C<DBI::st> objects have finished with
them, looking like leaks, but not.  They aren't recognised by
C<ignore_DBI_globals> currently.  A workaround is to do a dummy C<DBI::db>
handle creation to flush out the old scratchpad.

=back

=head1 SEE ALSO

L<Test::Weaken>,
L<Test::Weaken::Gtk2>

L<Class::Singleton>, L<DBI>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/test-variousbits/index.html>

=head1 COPYRIGHT

Copyright 2008, 2009, 2010, 2011, 2012, 2015, 2017 Kevin Ryde

Test-VariousBits is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published
by the Free Software Foundation; either version 3, or (at your option) any
later version.

Test-VariousBits is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along
with Test-VariousBits.  If not, see L<http://www.gnu.org/licenses/>.

=cut

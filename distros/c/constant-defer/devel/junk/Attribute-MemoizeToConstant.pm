# no good because Attribute::Handlers doesn't run at the right phase in a
# require or eval



# Copyright 2008, 2009, 2010 Kevin Ryde

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

package Attribute::MemoizeToConstant;
use Attribute::Handlers;
## no critic (RequireUseStrict RequireUseWarnings)
no strict;
no warnings;

push @UNIVERSAL::ISA, __PACKAGE__;

use constant DEBUG => 0;

our $c;

my @pending;
my $checked = 0;

sub MODIFY_CODE_ATTRIBUTES {
  my ($package, $coderef, @attrs) = @_;
  if (DEBUG) { print "MemoizeToConstant pending $package $coderef\n"; }
  push @pending, [$package, $coderef];
  if ($checked) {
    run_pending();
  }
  return grep {$_ ne 'MemoizeToConstant'} @attrs;
}

CHECK {
  if (DEBUG) { print "MemoizeToConstant CHECK\n"; }
  $checked = 1;
  run_pending();
}

sub run_pending {
  while (@pending) {
    my ($package, $oldcode) = @{pop @pending};
    if (DEBUG) { print " $package $oldcode\n"; }

    $c = $oldcode;
    require Scalar::Util;
    Scalar::Util::weaken ($c);

    my $found;
    my $phash = \%{"${package}::"};
    foreach my $name (keys %$phash) {
      my $glob = $phash->{$name};
      ref(\$glob) eq 'GLOB' or next;
      (*{$glob}{CODE} || 0) == $oldcode or next;

      my $fullname = "${package}::$name";
      if (DEBUG) { print "  install to $fullname\n"; }

      *$fullname = sub () {
        my $value = $oldcode->(@_);
        *$fullname = sub () { $value };
        return $value;
      };
      $found = 1;
    }
    $found or warn "MemoizeToConstant func $oldcode not found in $package";
  }
}

1;

__END__


  
# sub make_func {
#   return sub () {
#     my $value = $_[0]oldcode->(@_);
#     *$sym = sub () { $value };
#     return $value;
#   }
# }
  
#   use Data::Dumper;
#   print Dumper(\@_);
# 
#   use Data::Dump;
#   print Data::Dump::dump(\*main::foo);
# 
#   my $x = findsym ($package, $coderef);
#   print "findsym ",Dumper($x);
# 
#   no strict;
# 
#   my $type = ref($coderef);



# Attribute::Handlers holds onto to the original coderef, so it's not freed
# when the func is turned into a constant ...

package Attribute::MemoizeToConstant;
use Attribute::Handlers;
use strict;
use warnings;

our $VERSION = 1;

use constant DEBUG => 0;

our $c;

sub UNIVERSAL::MemoizeToConstant : ATTR(CODE) {
  my ($package, $typeglob, $oldcode) = @_;
$c = $oldcode;
Scalar::Util::weaken ($c);

  if (DEBUG) {
    print "MemoizeToConstant on '$package' '",
      *{$typeglob}{NAME}, "' ", $oldcode,"\n";
  }

  no warnings;
  *$typeglob = sub () {
    my $value = $oldcode->(@_);
    *$typeglob = sub () { $value };
    return $value;
  };
}

1;
__END__

=head1 NAME

Attribute::MemoizeToConstant -- memoize functions to become constants

=head1 SYNOPSIS

 use Attribute::MemoizeToConstant;
 sub myfunc : MemoizeToConstant {
   # some long calculation
   return $x;
 }

=head1 BUGS!

Doesn't work when used in a module or file which is loaded by C<require>,
C<do>, etc, only from the main program and things brought in C<use>.

=head1 DESCRIPTION

Attribute C<MemoizeToConstant> arranges for a function to be memoized so its
first call runs the code but it's then transformed into a constant sub (like
C<use constant>) with that first return value.

=head1 SEE ALSO

=for comment
Actually it wants to be attributes(3perl) to avoid attributes(3ncurses), but
the formatters complain about that ...

L<Attribute::Memoize>, L<Memoize::Attrs>, L<attributes>,
L<Attribute::Handlers>, L<Memoize>

=cut

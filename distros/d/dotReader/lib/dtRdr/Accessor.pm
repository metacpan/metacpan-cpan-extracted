package dtRdr::Accessor;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;

use Carp;
use Class::Accessor;


=head1 NAME

dtRdr::Accessor - generate an accessor subclass

=head1 SYNOPSIS

  use dtRdr::Accessor (
    package => 'Your::Subclass', # optional
    ro => [qw(foo bar baz)],
    rw => [qw(thing deal)],
    );

=cut


=head2 import

  dtRdr::Accessor->import(@list);

=cut

sub import {
  my $this_package = shift;
  (@_ % 2) and croak("odd number of elements in arguments");
  my (%options) = @_;

  @_ or return;

  my $caller = caller;

  my $package = $this_package->_create_package(
    'package' => $options{package},
    'caller'  => $caller
    );

  my @rw = @{ $options{rw} || [] };
  my @ro = @{ $options{ro} || [] };
  $package->mk_ro_accessors(@ro);
  $package->mk_accessors(@rw);

  # aliases
  $this_package->_mk_alias_get($package, @ro, @rw);
} # end subroutine import definition
########################################################################


=head2 _create_package

Creates and returns the package in which the accessors will live.  Also
pushes the created accessor package into the caller's @ISA.

If it already exists, simply returns the cached value.

  my $package = dtRdr::Accessor->_create_package(
    'caller' => $caller,
    'package' => $package, # optional
    );

=cut

{
my %package_map;
sub _create_package {
  my $this_package = shift;
  (@_ % 2) and croak("odd number of elements in arguments");
  my (%options) = @_;

  if(exists($package_map{$options{caller}})) {
    # check for attempt to change package (not allowed)
    if(exists($options{package})) {
      ($package_map{$options{caller}} eq $options{'package'}) or die;
    }
    return($package_map{$options{caller}});
  }

  # use a package that can't be stepped on unless they ask for one
  my $caller = $options{caller} or die;
  my $package = $options{package} || $caller . '::--accessors';
  $package_map{$caller} = $package;
  #warn "create $package";

  my $caller_isa;
  {
    no strict 'refs';
    # TODO hang this on a package that doesn't have a new()
    push(@{"${package}::ISA"}, 'Class::Accessor');
    $caller_isa = \@{"${caller}::ISA"};
  }
  push(@$caller_isa, $package)
    unless(grep({$_ eq $package} @$caller_isa));
  $package->follow_best_practice;
  return($package);
} # end subroutine _create_package definition
} # and closure
########################################################################


=head2 _mk_alias_get

Alias "$method"() to be a shortcut for "get_$method"().

  dtRdr::Accessor->_mk_alias_get($package, $method);

=cut

sub _mk_alias_get {
  my $this_package = shift;
  my ($package, @methods) = @_;
  foreach my $method (@methods) {
    # string-eval for speed (see Method::Alias)
    my $subref = eval("sub {\$_[0]->get_$method()}");
    $@ and croak("oops -- $@");
    # warn "$subref for $method";
    no strict 'refs';
    unless(defined(&{"${package}::$method"})) {
      *{"${package}::$method"} = $subref;
    }
    else {
      # hope we never hit that (I'm not solving all the world's problems here)
      warn "$package should probably overload 'get_$method' instead";
    }
  }
} # end subroutine _mk_alias_get definition
########################################################################

=head2 ro

  dtRdr::Accessor->ro(@list);

=cut

sub ro {
  my $this_package = shift;
  my (@list) = @_;
  my $caller = caller;
  $caller->isa(__PACKAGE__) and die;
  my $package = $this_package->_create_package('caller' => $caller);
  $package->mk_ro_accessors(@list);
  $this_package->_mk_alias_get($package, @list);
} # end subroutine ro definition
########################################################################

=head2 rw

  dtRdr::Accessor->rw(@list);

=cut

sub rw {
  my $this_package = shift;
  my (@list) = @_;
  my $caller = caller;
  $caller->isa(__PACKAGE__) and die;
  my $package = $this_package->_create_package('caller' => $caller);
  $package->mk_accessors(@list);
  $this_package->_mk_alias_get($package, @list);
} # end subroutine rw definition
########################################################################


=head2 ro_w

  my $setter = dtRdr::Accessor->ro_w($name);

=cut

sub ro_w {
  my $this_package = shift;
  my ($name) = @_;
  my $caller = caller;
  $caller->isa(__PACKAGE__) and die;
  my $package = $this_package->_create_package('caller' => $caller);

  # just make them as usual
  $package->mk_accessors($name);
  $this_package->_mk_alias_get($package, $name);

  # then delete and put it here
  my $new_name = '--set_' . $name;
  {
    no strict 'refs';
    *{$package.'::'.$new_name} = delete(${$package.'::'}{'set_'.$name});
  }
  return($new_name);
} # end subroutine ro_w definition
########################################################################

=head2 class_ro

  dtRdr::Accessor->class_ro(name => $value, ...);

=cut

sub class_ro {
  my $this_package = shift;
  my (@list) = @_;
  (@list % 2) and croak("odd number of elements in arguments");
  my %data = @list;

  my $caller = caller;
  $caller->isa(__PACKAGE__) and die;
  my $package = $this_package->_create_package('caller' => $caller);
  $this_package->_mk_class_accessors('ro', $package, %data);
  $this_package->_mk_alias_get($package, keys(%data));
} # end subroutine class_ro definition
########################################################################

=head2 class_rw

  dtRdr::Accessor->class_rw(name => $value, ...);

=cut

sub class_rw {
  my $this_package = shift;
  my (@list) = @_;
  (@list % 2) and croak("odd number of elements in arguments");
  my %data = @list;

  my $caller = caller;
  $caller->isa(__PACKAGE__) and die;
  my $package = $this_package->_create_package('caller' => $caller);
  $this_package->_mk_class_accessors('rw', $package, %data);
  $this_package->_mk_alias_get($package, keys(%data));
} # end subroutine class_rw definition
########################################################################

=head2 class_ro_w

Creates a getter and setter and hands you a reference to the setter
instead of installing it.

  my $setter = dtRdr::Accessor->class_ro_w(name => $value);
  $setter->($value);

=cut

sub class_ro_w {
  my $this_package = shift;
  my (@list) = @_;
  (@list > 2) and croak("only one per call");

  my $caller = caller;
  $caller->isa(__PACKAGE__) and die;
  my $package = $this_package->_create_package('caller' => $caller);
  my $subref = $this_package->_mk_class_accessors('ro_w', $package, @list);
  $this_package->_mk_alias_get($package, $list[0]);
  return($subref);
} # end subroutine class_ro_w definition
########################################################################

=head2 _mk_class_accessors

  dtRdr::Accessor->_mk_class_accessors('ro'|'rw', $package, %data);

=cut

sub _mk_class_accessors {
  my $this_package = shift;
  my ($type, $class, @data) = @_;
  (@data % 2) and croak("odd number of elements in arguments");

  my %data = @data;

  foreach my $item (keys(%data)) {

    my $value = $data{$item};

    my $getsub = sub {
      my $class = shift;
      return($value);
    };
    my $setsub = sub {
      my $self = shift;
      $value = shift;
    };
    {
      no strict 'refs';
      defined(&{$class.'::get_'.$item}) and die;
      *{$class.'::get_'.$item} = $getsub;
      if($type eq 'rw') {
        defined(&{$class.'::set_'.$item}) and die;
        *{$class.'::set_'.$item} = $setsub;
      }
      elsif($type eq 'ro_w') {
        # not exactly efficient this way, but ...
        return(sub {$setsub->(undef, @_)});
      }
    }
  }
} # end subroutine _mk_class_accessors definition
########################################################################

=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2006 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

The dotReader(TM) is OSI Certified Open Source Software licensed under
the GNU General Public License (GPL) Version 2, June 1991. Non-encrypted
and encrypted packages are usable in connection with the dotReader(TM).
The ability to create, edit, or otherwise modify content of such
encrypted packages is self-contained within the packages, and NOT
provided by the dotReader(TM), and is addressed in a separate commercial
license.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut

# vi:ts=2:sw=2:et:sta
1;

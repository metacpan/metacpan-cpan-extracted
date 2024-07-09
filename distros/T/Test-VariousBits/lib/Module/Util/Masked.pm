# Copyright 2010, 2011, 2012, 2015, 2017 Kevin Ryde

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

package Module::Util::Masked;
require 5;
use strict;

use vars qw($VERSION);
$VERSION = 8;

# uncomment this to run the ### lines
# use Smart::Comments;

# BEGIN {
#   # Check that Module::Util isn't already loaded.
#   #
#   # is_valid_module_name() here is a representative func, and not one that's
#   # mangled here (so as not to risk hitting that if something goes badly
#   # wrong).  Maybe looking at %INC would be better.
#   #
#   if (Module::Util->can('is_valid_module_name')) {
#     die "Module::Util already loaded, cannot fake after imports may have grabbed its functions";
#   }
# }

use Module::Util;

# Crib notes:
#
# Module::Util uses File::Find which loads Scalar::Util, so the requires of
# that here are unnecessary, but included for certainty.




sub _module_is_unplugged {
  my ($module) = @_;
  if (Devel::Unplug->can('unplugged')) {
    foreach my $unplugged (Devel::Unplug::unplugged()) {
      if (ref $unplugged ? $module =~ $unplugged : $module eq $unplugged) {
        return 1;
      }
    }
  }
  return 0;
}

sub _incval_masks_module {
  my ($incval, $module) = @_;
  ### _incval_masks_module() ...
  ### $incval
  ### $module

  ref $incval or return 0;

  if ($incval == \&Test::Without::Module::fake_module) {
    ### incval is Test-Without-Module fake_module ...
    my $href = Test::Without::Module::get_forbidden_list();
    ### $href

    # Test::Without::Module 0.18 and earlier had Foo::Bar module name
    # Test::Without::Module 0.20 has Foo/Bar.pm path
    # look for either
    if (exists $href->{$module}
       || exists $href->{Module::Util::module_path($module)}) {
      ### Test-Without-Module masks ...
      return 1;
    }
  }

  require Scalar::Util;
  if (Scalar::Util::blessed($incval)
      && $incval->isa('Module::Mask')
      && $incval->is_masked($module)) {
    ### Module-Mask masks ...
    return 1;
  }

  ### not masked ...
  return 0;
}

# _pruned_inc($module) using @INC
# _pruned_inc($module, $dir,$dir,...)
# Return list of dirs preceding any mask of $module.
#
sub _pruned_inc {
  my $module = shift;
  my @inc = @_ ? @_ : @INC;
  ### _pruned_inc() ...

  foreach my $pos (0 .. $#inc) {
    if (_incval_masks_module($inc[$pos],$module)) {
      $#inc = $pos-1; # truncate
      if ($pos == 0) {
        return;
      }
      $#inc = $pos-1;
      last;
    }
  }
  ### pruned to: @inc
  return @inc;
}

{
  my $orig = \&Module::Util::find_installed;

  sub Module_Util_Masked__find_installed ($;@) {
    my $module = shift;
    ### M-U-Masked find_installed(): $module

    if (_module_is_unplugged($module)) {
      return undef;
    }
    my @inc = _pruned_inc($module, @_)
      or return undef;  # nothing after pruned
    ### @inc
    return &$orig($module,@inc);
  }
  no warnings 'redefine';
  *Module::Util::find_installed = \&Module_Util_Masked__find_installed;
}

{
  my $orig = \&Module::Util::all_installed;

  sub Module_Util_Masked__all_installed ($;@) {
    my $module = shift;
    ### M-U-Masked all_installed(): $module

    if (_module_is_unplugged($module)) {
      return;
    }
    my @inc = _pruned_inc($module, @_)
      or return;  # nothing after pruned
    return &$orig($module,_pruned_inc($module, @_));
  }
  no warnings 'redefine';
  *Module::Util::all_installed = \&Module_Util_Masked__all_installed;
}

{
  my $orig = \&Module::Util::find_in_namespace;

  sub Module_Util_Masked__find_in_namespace ($;@) {
    my $namespace = shift;
    ### M-U-Masked find_in_namespace(): $namespace

    my @masks;
    my @ret;
    foreach my $incval (@_ ? @_ : @INC) {
      if (ref $incval
          && do {
            require Scalar::Util;
            (Scalar::Util::refaddr($incval)
             == \&Test::Without::Module::fake_module
             || (Scalar::Util::blessed($incval)
                 && $incval->isa('Module::Mask')))
          }) {
        push @masks, $incval;
      } else {
        my @found = &$orig($namespace, $incval);
        @found = grep {! _module_is_unplugged($_)} @found;
        foreach my $mask (@masks) {
          @found = grep {! _incval_masks_module($mask,$_)} @found;
        }
        push @ret, @found;
      }
    }
    ### ret inc duplicates: @ret
    my %seen;
    return grep { !$seen{$_}++ } @ret;
  }
  no warnings 'redefine';
  *Module::Util::find_in_namespace = \&Module_Util_Masked__find_in_namespace;
}

1;
__END__


# sub _module_is_masked {
#   my ($module) = @_;
#   ### _module_is_masked(): $module
#
#   if (Test::Without::Module->can('get_forbidden_list')) {
#     my $href = Test::Without::Module::get_forbidden_list();
#     if (exists $href->{$module}) {
#       ### no, Test-Without-Module forbidden
#       return 0;
#     }
#   }
#
#   require Scalar::Util;
#   foreach my $inc (@INC) {
#     if (Scalar::Util::blessed($inc)
#         && $inc->isa('Module::Mask')
#         && $inc->is_masked($module)) {
#       ### no, Module-Mask masked
#       return 0;
#     }
#   }
#   return 0;
# }


=for stopwords Ryde Test-VariousBits recognise recognised unmangled coderef

=head1 NAME

Module::Util::Masked - mangle Module::Util to recognise module masking

=head1 SYNOPSIS

 perl -MModule::Util::Masked \
      -MTest::Without::Module=Some::Thing \
      myprog.pl ...

 perl -MModule::Util::Masked \
      -MModule::Mask::Deps \
      myprog.pl ...

 # or within a script
 use Module::Util::Masked;
 use Module::Mask;
 my $mask = Module::Mask->new ('Some::Thing');

=head1 DESCRIPTION

This module mangles L<Module::Util> functions

    find_installed()
    all_installed()
    find_in_namespace()

to have them not return modules which are "masked" by any of

    Module::Mask
    Module::Mask::Deps
    Test::Without::Module
    Devel::Unplug

This is meant for testing, just as these masking modules are meant for
testing, to pretend some modules are not available.  Making the "find"
functions in C<Module::Util> reflect the masking helps code which checks
module availability by a find rather than just C<eval{require...}> or
similar.

=head2 Load Order

C<Module::Util::Masked> should be loaded before anything which might import
the C<Module::Util> functions, so such an import gets the mangled functions
not the originals.

Usually this means loading C<Module::Util::Masked> first, or early enough,
but there's no attempt to detect or enforce that.  A C<-M> on the command
line is good

    perl -MModule::Util::Masked myprog.pl ...

Or for the C<ExtUtils::MakeMaker> testing harness the same in the usual
C<HARNESS_PERL_SWITCHES> environment variable,

    HARNESS_PERL_SWITCHES="-MModule::Util::Masked" make test

Otherwise somewhere near the start of a script

    use Module::Util::Masked;

Nothing actually changes in the C<Module::Util> behaviour until one of the
above mask modules such as C<Test::Without::Module> is loaded and is asked
to mask some modules.  Then the mangled C<Module::Util> will report such
modules not found.

The mangling cannot be undone, but usually there's no need to.  If some
modules should be made visible again then ask the masking in
C<Test::Without::Module> etc to unmask them.

=head2 Implementation

C<Module::Mask> is recognised by the object it adds to C<@INC>.

C<Module::Mask::Deps> is a subclass of C<Module::Mask> and is recognised the
same way.

C<Test::Without::Module> is recognised by the C<fake_module()> coderef it
adds to C<@INC> (which is not documented as such, so is dependent on the
C<Test::Without::Module> implementation).

The masking object or coderef in C<@INC> is applied at the point it appears
in the C<@INC> list.  This means any directory in C<@INC> before the mask is
unaffected, the same way it's unaffected for a C<require> etc.  The masking
modules normally put themselves at the start of C<@INC> and are therefore
usually meant to act on everything.

C<Devel::Unplug> is checked by its C<unplugged()> list, when that function
exists.  It applies to any C<require> so not to a particular place in
C<@INC>.  Should an unplug be enforced when C<find_installed()> etc is given
a path, or only the default C<@INC>?  If a path is C<@INC> plus or minus a
few directories and then unplugging would be desirable, but if it's
something unrelated then maybe not.

=head1 SEE ALSO

L<Module::Util>,
L<Module::Mask>,
L<Module::Mask::Deps>,
L<Test::Without::Module>,
L<Devel::Unplug>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/test-variousbits/index.html>

=head1 COPYRIGHT

Copyright 2010, 2011, 2012, 2015, 2017 Kevin Ryde

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

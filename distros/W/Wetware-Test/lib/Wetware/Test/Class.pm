#-------------------------------------------------------------------------------
#      $URL$
#     $Date$
#   $Author$
# $Revision$
#-------------------------------------------------------------------------------
package Wetware::Test::Class;

use strict;
use warnings;

use Test::Class;
use base 'Test::Class';

use Wetware::Test::Utilities qw(is_testsuite_module);

#------------------------------------------------------------------------------
our $VERSION = 0.02;
#------------------------------------------------------------------------------
INIT { Test::Class->runtests() }
#------------------------------------------------------------------------------

sub is_test_class {
  my ( $class, $file, $dir ) = @_;

  # return unless it's a .pm (the default)
  return unless $class->SUPER::is_test_class( $file, $dir );
  
  # because the simple Module::Build will copy the .svn and CVS file
  # and we do not consider them valid modules to be testing.
  return if ( $dir =~ m{/CVS/} || $dir =~ m{/.svn/} );
  
  # and only allow those that is_testsuite_module() allows
  return is_testsuite_module($file);
}

#------------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Wetware::Test::Class -  Test::Class base class

=head1 SYNOPSIS

  package Wetware::My::TestSuite;
  use base Wetware::Test::Class;
  # write tests as normal...

=head1 DESCRIPTION

This base class provides the magic that allows you to run individual
Test::Class-based modules like regular test scripts.  For example,
either of these will work as long as the F<TestSuite.pm> inherits from
this module:

=over

 prove t/lib/Wetware/My/TestSuite.pm

 ./Build test --test_files=t/lib/Wetware/My/TestSuite.pm

=back

Note that you do not need to inherit from L<Test::Class> if you use
this module as your base.  For reference see:

L<http://search.cpan.org/~adie/Test-Class-0.31/lib/Test/Class/Load.pm#CUSTOMIZING_TEST_RUNS>

=head2 METHODS

This implements an is_test_class() that overrides the base method.

This returns true IF the file is 'TestSuite.pm'.

This will allow us to point at the blib/lib without having
to worry about considering all of the *.pm files as TestSuites.

=head2 BUG

A conflict will arise IF one is using the Test::Compile approach
to testing all of the perl modules in blib, AND one of them is
a Test Class based module. The error will look something like:

=over

 t/00_compile_pm.t ............. 1/2 Too late to run INIT block at 
 /usr/local/lib/perl5/site_perl/5.8.7/Wetware/Test/Class.pm line 22.

=back

where the script t/00_compile_pm.t is of the form:

=over
 
 use strict;
 use warnings;
 use Test::Compile;

 all_pm_files_ok();

=back

I have not yet solved a way to avoid this conflict.

The best advice is to limit what is in a given distribution IF it
will be installing a Test Class Module that is expected to be
inherited for test purposes for those subclassing both the Class
and it's Test Classes.

In that case use the stock 00-load.t approach:

=over

 use Test::More tests => 1;

 BEGIN {
   use_ok( 'Wetware::CLI' );
 }

=back

If one does not need to have the Test Class Module in blib, then
putting them in t/lib and running the simple 01_test_class.t script 

=over

 use strict;
 use warnings;
 use FindBin qw($Bin);
 use Test::Class::Load "$Bin/lib";

=back

will not cause the conflict.

=head1 SEE ALSO

Test::Class

Test::Class::Load

Wetware::Test::Utilities

=head1 AUTHOR

"drieux", C<< <"drieux [AT]  at wetware.com"> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 "drieux", all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# the end 

#-------------------------------------------------------------------------------
#      $URL$
#     $Date$
#   $Author$
# $Revision$
#-------------------------------------------------------------------------------
use strict;
use warnings;
use FindBin qw($Bin);
use Test::Class::Load "$Bin/../blib/lib/";

#-------------------------------------------------------------------------------

__END__

=pod

=head1 NAME

01_test_classes.t - Load and run unit test modules based on L<Test::Class>

=head1 SYNOPSIS

  ./Build test --test_files=t/01_test_classes.t

  prove -b t/01_test_classes.t


=head1 DESCRIPTION

This script leverages L<Test::Class::Load> to automatically discover, 
load, and run tests in modules that are based on L<Test::Class>. 

Note, in our case we have a TestSuite.pm that needs to be delivered, and
as such is in lib/ vice t/lib. But to keep the testcover from breaking,
I have opted to include a stub 

=over

=item * t/lib/Wetware/CLI/TestSuite/Stub.pm

=back

that is found by this script.

=head1 RUNNING INDIVIDUAL TESTS

You can still run the tests in an individual test class, just by running them the
same way that you would run a test script.  For example:

  ./Build test --test_files=t/lib/Wetware/CLI/TestSuite.pm
  
  prove -b -It/lib t/lib/Wetware/CLI/TestSuite.pm
    
Note that C<prove> requires an additional C<-I> argument.  I might fix this soon.
And remember that you can set the C<TEST_METHOD> environment variable to control
exactly which test methods will be run.


=head1 WHY ARE MY TESTS BEING SKIPPED?

When running tests in this fashion, L<Test::Class> skips the remaining assertions
within a test method as soon as an assertion fails.  This kinda sucks, but it
usually doesn't cause too much aggrivation as long as you know that it is happening.

=cut

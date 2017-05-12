#-------------------------------------------------------------------------------
#      $URL$
#     $Date$
#   $Author$
# $Revision$
#-------------------------------------------------------------------------------
package Wetware::Test;

use warnings;
use strict;

our $VERSION = 0.07;

#-------------------------------------------------------------------------------

1; 

__END__

=pod

=head1 NAME

Wetware::Test - Wetware Test::Class extensions

=head1 DESCRIPTION

This is a step towards stream lining the process of
creating and maintaining Test::Class based Test Driven Development.

Ultimately I would like to have a tool that would create a
Foo::TestSuite for all Foo Classes that are in the distribution.

This means setting the 01_test_class.t to look into blib/lib
which will help the over all process. This way any Test::Class
based TestSuite.pm module will also be installed, so that 
subclasses of FOO will be able to inherit from Foo::TestSuite.

Caveat: this now needs a fix in the Test::Compile approach
to avoid the TestSuite.pm files.

This distribution also offers the illustration of one strategy
for doing the 01_test_class.t - which runs all of the modules
in t/lib. It should be noted that Wetware::Test::Utilities is
a Functional Module, and so it inherits directly from 
Wetware::Test::Class - since there is no need for the sorts
of set_up/tear_down etc that are useful for OO testing.

=head1 INTRO TO Modules

This distribution provides five modules:

=over

=item * Wetware::Test::Class

Subclass of Test::Class that implements the INIT block that
will call Test::Class->runruntests(), so that there need only
be one t/00_test_class.t script to run all of the Test::Class
based test suite modules.

=item * Wetware::Test::Class::Load

This extends Test::Class:Load by not looking into any
directory that is a /CVS/ or /.svn/ - this will prevent
those production systems where the default behavior
of Module::Build is to copy over any pm files that
are in the CVS and .svn sub directories of lib.

=item * Wetware::Test::Suite

Inherits from Wetware::Test::Class and defines the five
basic methods to stream line creating a Test::Class based
test suite for each module to be tested.

=item * Wetware::Test::Utilities

This provides some functional methods.

=item * Wetware::Test::Mock

This is a very simple Mock Object. It uses AUTOLOAD to
create accessors. In most of my uses of a Mock Object I
just need a simple way to return some value.

=back

I am putting these in the Wetware space, because I want to get
the ideas out there, and I want to implement a Wetware::CLI that
will have an appropriate Test::Class based testing.

It also means that I do not have to rumage around for those
neat tricks.... Just put them into a distribution, and then
call the appropriate module.

=head1 OVERVIEW

When a module is started with module_starter, it provides some
nice basic starting t/ test files. 

What it will not do is teach about the difference between
unit and functional testing, and/or the utility of Test
Driven Development.

This overview I hope will help with the simple pragmatics
of setting up a Test::Class approach to development.

The simplest strategy is to have a file named TestSuite.pm
that shadows every module being created. Thus if there is
a My::Module:: in the lib/ then in t/lib/My/Module/TestSuite.pm
will be the My::Module::TestSuite.

It could begin with as simple a starting module as:

=over

 package My::Module::TestSuite;

 use strict;
 use warnings;
 use base q{Wetware::Test::Suite};

 use Test::More;
 use My::Module;

 #--------------------------------------------------

 sub class_under_test { return 'My::Module'; }

 #--------------------------------------------------

 sub test_new : Test(1) {
	my $self           = shift;
	my $object         = $self->object_under_test();
	my $expected_class = $self->class_under_test();

	Test::More::isa_ok( $object, $expected_class );
	return $self;
 }

=back

This shows that the class_under_test method overrides the
method in C<Wetware::Test::Suite>. But the C<set_up()>, 
C<tear_down> and C<object_under_test()> were just hapily
inherited in.

Add the equally simple 01_test_class.t script:

     use strict;
     use warnings;
     use FindBin qw($Bin);
     use Wetware::Test::Class::Load "$Bin/../blib/lib";

into the t/ directory, and the process can begin.

{ remember to do the perl Build.PL, since one is adding files
that were not taken account of when Build was created last. Also
remember to update the Manifest... and eat regularly... }

If there is a subclass My::Module::SubClass which inherited
from My::Module, then it's TestSuite would likewise inherit.

=over

 package My::Module::SubClass::TestSuite;

 use strict;
 use warnings;
 use base q{My::Module::TestSuite};

 use Test::More;
 use My::Module::SubClass;

 #-------------------------------------------------------

 sub class_under_test { return 'My::Module::SubClass'; }

=back

and it would inherit the first test - test_new() from 
My::Module::TestSuite. This is also an advantange that
any test that is written for the base class will be
inherited into all of the subclasses.

Since the 01_test_class.t will load and test all modules in t/lib, 
there is no need to update and maintain an additional test script.

As noted in the pod for Wetware::Test::Class, any individual
TestSuite can be run, either with prove, or through the build

 ./Build test test_files=t/lib/My/Module/SubClass/TestSuite.pm

But the general speed up that comes using the Test::Class::Load
means that the tests in general will run fast enough.

=head1 BACKGROUND

Once upon a time we were converting some legacy code, and starting
the transition from the Test::More apporach where there is one
test script in t/ for each module. 

Since there were several modules in that distribution that were
subclasses, using Test::Class was a great step forward. But there
was still one test script for each module.

The big bottle neck in the process is compiling each test script.

The Test::Class::Load module provides the lifting needed to
have a single script run all of the Test Suite Modules in t/lib.
This requires that thers is a module that inherits from  Test::Class
and implements the INIT block, like:

=over

 package OUR::Test::Class;

 use strict;
 use warnings;

 use Test::Class;
 use base 'Test::Class';
 our $VERSION = 0.01;

 INIT { Test::Class->runtests() }

=back

Which all of the modules will inherit from. Then you can call
them all with the 00_test_class.t script.

Then when we started a new project, I asked if we could have
some sort of base TestSuite module, so that everyone inherited
the same five basic methods. It would inherit from OUR::Test::Class,
and thus all of it's sub classes would run contentedly.

Now all that one needs to do when creating complex distributions
is to start with simple steps. There will need to be the 00_test_class.t
test script in t/ and now one can create the Test::Class based modules
in t/lib/Your/Space that will shadow the classes in lib/Your/Space.

=head1 CHANGE STOCK test files

There are two semi standard .t test scripts that need to
be changed to work and play well with the TestSuite approach,
since if one attempts to do the simple Test::Compile of 
any Module that inherits from a Test::Class based module 
with the INIT block, they will fail becaue 'it is too
late for INIT' - this is also true of Pod Coverage.

So the fix is to call a sub.

Modify pod-coverage.t to use:

=over

 all_non_testsuite_pod();

 #-------------------------------------------------------------

 sub all_non_testsuite_pod {

	my @modules = grep { $_ !~ m{::TestSuite$} } all_modules();
	plan tests => scalar @modules;
	foreach my $module ( @modules ) {
		pod_coverage_ok($module);
	}
	return;
 }

=back

And it will filter out the modules *::TestSuite.

The compile_pm script is about the same, except that it runs with
module file names:

=over

 all_non_testsuite_modules();

 #----------------------------------------------------------------

 sub all_non_testsuite_modules {

	my @modules = grep { $_ !~ m{/TestSuite.pm$} } all_pm_files();
	plan tests => scalar @modules;
	foreach my $module ( @modules ) {
		pm_file_ok
		($module);
	}
	return;
 }

=back

Remember that you will need to add the 'use Test::More;' so that
you have access to the plan.

=head2 TRADE OFF

I am working on Wetware::Test::CreateTestSuite that will
help with creating the right types of t files. 

So that it will be simpler to use both a Foo::TestSuite
in the lib, rather than in t/lib, so that it can be
inherited by those who wish to sub class....

But also so that there is not the loss of functionality of
having pod_coverage.t and Test::Compile tests.

That module will deliver a create_testsuite tool to help
the process of automating Test::Class based Test Driven
Development.

BUT, this will require that users opt to do the right thing.

Some of this can be solved in code, but it will also require
some rethinking about how the processes is done.


=head1 AUTHOR

"drieux", C<< <"drieux [AT]  at wetware.com"> >>

=head1 SEE ALSO

Wetware::Test::CreateTestSuite

Wetware::Test::Class

Wetware::Test::Class::Load

Wetware::Test::Suite

Wetware::Test::Utilities

Wetware::Test::Mock

Test::Class

Test::Class::Load

Test::More

Test::Differences - great eq_or_diff_text() method!

Test::Exception - because some things NEED to throw exceptions.

module-starter - the way to start a new module

=head1 ACKNOWLEDGEMENTS

A special thanks to Jeffrey Ryan Thalhammer <thaljef@cpan.org> for
helping me understand the Test::Class::Load approach. 

And a BIG thanks to Matisse Enzer for his commitment to Test Based Design.

=head1 COPYRIGHT & LICENSE

Copyright 2009 "drieux", all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Wetware::Test

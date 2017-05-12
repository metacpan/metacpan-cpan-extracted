use strict;
use warnings;

package Test::StructuredObject;
BEGIN {
  $Test::StructuredObject::AUTHORITY = 'cpan:KENTNL';
}
{
  $Test::StructuredObject::VERSION = '0.01000010';
}

# ABSTRACT: Use a structured execution-graph to create a test object which runs your tests smartly.



use Test::More ();
use Test::StructuredObject::TestSuite;
use Test::StructuredObject::SubTest;
use Test::StructuredObject::Test;
use Test::StructuredObject::NonTest;


use Sub::Exporter -setup => {
  exports => [qw( test step testsuite testgroup )],
  groups  => { default => [qw( test step testsuite testgroup )] },

};

## no critic ( ProhibitSubroutinePrototypes, RequireArgUnpacking )

sub test(&;@) {
  my $code = shift;
  return Test::StructuredObject::Test->new( code => $code ), @_;
}

sub step(&;@) {
  my $code = shift;
  return Test::StructuredObject::NonTest->new( code => $code ), @_;
}

sub testsuite(@) {
  if ( not ref $_[0] ) {
    my $name = shift;
    my $i = Test::StructuredObject::SubTest->new( name => $name, items => \@_ );
    return $i;
  }
  my $i = Test::StructuredObject::TestSuite->new( items => \@_ );
  return $i;
}

sub testgroup($@) {
  my $name  = shift;
  my @items = @_;
  return Test::StructuredObject::SubTest->new( name => $name, items => \@items );
}

1;

__END__

=pod

=head1 NAME

Test::StructuredObject - Use a structured execution-graph to create a test object which runs your tests smartly.

=head1 VERSION

version 0.01000010

=head1 SYNOPSIS

    use Test::More;
    use Test::StructuredObject;

    my $testsuite = testsuite(
        test { use_ok('Foo'); },
        test { is( Foo->value, 7, 'Magic value' },
        step { note "This is a step!"; }
        testgroup( 'This is a subtest' => (
            test { ok( 1, 'some inner test' ) },
            test { ok( 1, 'another inner test' ) },
        ))
    );

    # Employs Test::More's very recent 'subtest' call internally to do subtesting.

    $testsuite->run();

    # Flattens the subtests into a linear fashion instead, decorated with 'note''s  for older Test::More's
    $testsuite->linearize->run();

    # Prints a simplistic (non-reversable) serialisation of the testsuite or diagnostic purposes.
    print $testsuite->to_s;

=head1 DESCRIPTION

This technique has various perks:

=over 4

=item 1. No need to count tests manually

=item 2. Tests are still counted internally:

Test harness can report tests that failed to run.

=item 3. Tests are collected in a sort of state-graph of sorts:

This is almost A.S.T. like in nature, which permits various run-time permutations of the graph for
different results.

=item 4. Every C<test { }> closure is executed in an C<eval { }>:

This makes subsequent tests not get skipped if one dies.

=item 5. Internal storage of many simple sub-calls:

This allows reasonably good L<< C<Deparse>|B::Deparse >> introspection, so if need be, the entire
execution tree can easily be rewritten to be completely Test::StructuredObject free.

=back

However, it has various downsides, which for most things appear reasonable to me:

=over 4

=item 1. Due to lots of closures:

Due to this, the only present variable transience is achieved via external lexical variables.

A good solution to this I've found is just pre-declare all your needed variables and pretend
they're like CPU registers =).

=item 2. Closures break C<< ->import >> in many cases:

Due to closure techniques, code that relies on C<< ->import >> to do lexical scope mangling may not work.

That is pesky for various reasons, but on average its not a problem, as it is, existing Test
files need that C<BEGIN{  use_ok }> stuff to get around this issue anyway.

But basically, all you need to do is 'use' in your file scope in these cases, or use Fully Qualified sub
names instead.

If neither of these solutions appeals to you, YOU DON'T HAVE TO USE THIS MODULE!.

=back

=head1 EXPORTS

This module exports the following symbols by default using L<< C<Sub::Exporter> |Sub::Exporter >>, and as such,
you can tweak and use export tunings as supported by that module.

=over 4

=item C<test>

    test {  test_pragma }

This method creates a L<< C<Test>|Test::Structured::Test >> object containing the given code.
Code is run at run-time when called on the objects C<< ->run >> method.
The code is run in an C<eval> container and as such will not die. Deaths called inside the C<eval> will
merely be downgraded to warnings and passed to L<< C<carp>|Carp/carp >>. See
L<the run documentation|Test::Structured::CodeStub/run> for details.

This object type is recognised by containing types, and presence of such types increments the relevant
number of planned tests at various levels.

=item C<step>

    step { code_step }

This method is virtually identical to L<< the C<test> method|/test >> except that the returned object is
instead an L<< C<NonTest>|Test::Structured::NonTest >>, and as such, containing types won't increment the
test count when it is seen. It is advised you use this method for doing things that prepare data for the
test, but don't actually do any testing. Additionally, it is advised to keep a 1-step-per-statement ratio,
because I feel this may pay off one day when I get proper tree processing =).

=item C<testsuite>

    testsuite( Test|NonTest|SubTest, ....   )

This method is just a sugar syntax to create a L<< C<TestSuite>|Test::Structured::TestSuite >> instance.
Its parameter list comprises of a list of either L<< C<Test>|Test::Structured::Test >>,
L<< C<NonTest>|Test::Structured::NonTest >> or L<< C<SubTest>|Test::Structured::SubTest >> instances.

As a side perk, if you use the following notation instead:

    testsuite( name => (   Test | NonTest | SubTest, ...  ) )

It will behave the same as L</testgroup> does.

=item C<testgroup>

    testgroup( name => ( Test | NonTest | SubTest , ... ) )

This method creates a structural subgroup of tests (L<< C<SubTest>|Test::Structured::SubTest >>) with the given name.
When the top C<TestSuite> is executed in normal conditions, this runs each test of the C<subtest> under
L<< C<Test::More>| Test::More >>'s 'C<subtest>' function creating pretty indented test TAP output.

This object, when linearised with C<< ->linearize >> instead injects 'note' subs before and after all its
children tests in the output linear test run, particularly useful for older Test::More instances.

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

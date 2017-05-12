package Test::UniqueTestNames;

=head1 NAME

Test::UniqueTestNames - Make sure all of your tests have unique names

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

For scripts that have no plan:

  use Test::UniqueTestNames;

that's it, you don't need to do anything else.

For scripts that have a plan, like this:

  use Test::More tests => x;

change to

  use Test::More tests => x + 1;
  use Test::UniqueTestNames;

=head1 DESCRIPTION

Test names are useful in assessing the contents of a test file.  They're also useful in debugging.  And when a test breaks, it's much easier to figure out what test broke if the test names are unique.  This module checks the names of every test to make sure that they're all unique.  If there are any tests that have duplicate names, it wil give a "not ok" and diagnostics of which test names have been used for multiple tests.

Test names aren't required by most testing modules, but B<by default Test::UniqueTestNames counts tests without names as failures>.  You can change that behavior by importing C<unnamed_ok>.

Specifically, this module is useful in the situation where tests are run in a loop, such as these:

  for( @fixture_data ) {
    my( $input, $output ) = @$_;

    ok( Some::Class->method( $input ), "...and the method works"; # test name will be the same each time

    is( Some::Class->method( $input ), $output, "...and the method works with $input"; # names could be the same
                                                                                       # if there is a duplicate in $input
  }

This test is similar in most respects to L<Test::NoWarnings>.

=head1 CAVEATS

Some tests generate their own test names, and thus shouldn't be counted as failures when they have non-unique test names.  This currently only applies to Test::More's C<isa_ok>.

=cut

use warnings;
use strict;

use base 'Test::Builder::Module';
use Test::UniqueTestNames::Tracker;
use Hook::LexWrap;

my $CLASS = __PACKAGE__;

use vars qw(
    @EXPORT_OK @ISA $VERSION
    $do_end_test
    @non_unique_tests
);

$VERSION = '0.04';

#require Exporter;
#@ISA = qw( Exporter );

@EXPORT_OK = qw(
    had_unique_test_names
    unnamed_ok
);

$do_end_test = 0;

sub import {
    $do_end_test = 1;
    Test::UniqueTestNames::Tracker->unnamed_ok(1) if grep { $_ eq 'unnamed_ok' } @_;

    goto &Exporter::import;
}

# idea courtesty Schwern:
# http://www.mail-archive.com/perl-qa@perl.org/msg06368.html
wrap 'Test::Builder::ok', post => sub {
    my($self, $ok, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $package, $file, $line ) = $self->caller();

    Test::UniqueTestNames::Tracker->add_test( $name, $line );
};

# the END block must be after the "use Test::Builder" to make sure it runs
# before Test::Builder's end block
# only run the test if there have been other tests
END {
    had_unique_test_names() if $do_end_test;
}

=head1 EXPORTED FUNCTIONS

=head2 had_unique_test_names()

This checks to see that all tests had unique names.  Usually you will not call this explicitly as it is called automatically when your script finishes.

=cut

sub had_unique_test_names {
    $do_end_test = 0;

    my $builder = $CLASS->builder;

    my ( $ok, $diag );
    if( @{ Test::UniqueTestNames::Tracker->failing_tests } > 0 ) {
        $ok = 0;

        my $num_failures = scalar @{ Test::UniqueTestNames::Tracker->failing_tests };
        $diag = "The following $num_failures test name(s) were not unique:\n"
            . "Test Name                               Occurrences     Line(s)\n"
            . "----------------------------------------------------------------";

        for my $test ( @{ Test::UniqueTestNames::Tracker->failing_tests } ) {

            # add the line numbers in sorted order
            my $line_numbers = $test->line_numbers;
            my @line_number_output;
            for( sort keys %$line_numbers ) {
                if( $line_numbers->{ $_ } > 1 ){
                    push @line_number_output, $_ . sprintf( " (%d times)", $line_numbers->{ $_ } );
                }
                else {
                    push @line_number_output, $_;
                }

            }

            $diag .= sprintf(
                "\n%-43s %d           %s",
                $test->short_name,
                $test->occurrences,
                join(', ', @line_number_output),
            );
        }
    }
    else {
        $ok = 1;
    }

    # TODO this should be exportable so that we don't have to set the line number manually,
    #  but use_ok seems to be interferring.
    #$test_line_number = __LINE__ + 1;
    $builder->ok($ok, 'all test names unique') || $builder->diag($diag);
}

1;

=head1 AUTHOR

Josh Heumann, C<< <cpan at joshheumann.com> >>

=head1 BUGS

=head2 Using with Test::Exception

This module currently throws a warning when used with L<Test::Exception>.  This is due to a bug in L<Hook::LexWrap>, and a patch has been submitted to correct the problem.

Please report any bugs or feature requests to C<bug-test-uniquetestnames at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-UniqueTestNames>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

L<Test::NoWarnings>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Josh Heumann, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

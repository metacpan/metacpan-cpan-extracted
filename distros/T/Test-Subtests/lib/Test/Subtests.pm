package Test::Subtests;

use base 'Test::Builder::Module';
our @EXPORT = qw(one_of none_of some_of all_of most_of ignore);

use Test::Builder;

use 5.006;
use strict;
use warnings FATAL => 'all';

my $CLASS = __PACKAGE__;

=head1 NAME

Test::Subtests - Different kinds of subtests.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Different kinds of tests, that allow for some subtests to fail.

    use Test::More;
    use Test::Subtests;

    one_of  'one_of fail'  => sub { ok(1); ok(1); ok(0); };
    one_of  'one_of pass'  => sub { ok(1); ok(0); ok(0); };

    none_of 'none_of fail' => sub { ok(1); ok(1); ok(0); };
    none_of 'none_of pass' => sub { ok(0); ok(0); ok(0); };

    some_of 'some_of fail' => sub { ok(0); ok(0); ok(0); };
    some_of 'some_of pass' => sub { ok(1); ok(1); ok(0); };

    all_of  'all_of fail'  => sub { ok(1); ok(1); ok(0); };
    all_of  'all_of pass'  => sub { ok(1); ok(1); ok(1); };

    most_of 'most_of fail' => sub { ok(1); ok(0); ok(0); };
    most_of 'most_of pass' => sub { ok(1); ok(1); ok(0); };

    ignore  'ignore pass'  => sub { ok(0); ok(0); ok(0); };
    ignore  'ignore pass'  => sub { ok(1); ok(1); ok(0); };

=head1 EXPORT

=over 4

=item * C<one_of>

=item * C<none_of>

=item * C<some_of>

=item * C<all_of>

=item * C<most_of>

=item * C<ignore>

=back

=head1 FUNCTIONS

=cut

# Run the subtests, and check the results
sub _subtest {
    # Process arguments.
    my ($name, $code, $check) = @_;

    # Get the caller's name.
    my $caller = (caller(1))[3];
    $caller =~ s/.*:://;

    # Get the test builder.
    my $builder = $CLASS->builder;

    # Check the arguments $code and $check.
    if ('CODE' ne ref $code) {
        $builder->croak("$caller()'s second argument must be a code ref");
    }
    if ($check) {
        if ('CODE' ne ref $check) {
            $builder->croak("$caller()'s third argument must be a code ref'");
        }
    }

    my $error;
    my $child;
    my $parent = {};
    {
        # Override the level.
        local $Test::Builder::Level = $Test::Builder::Level + 1;

        # Create a child test builder, and replace the parent by it.
        $child = $builder->child($name);
        Test::Builder::_copy($builder,  $parent);
        Test::Builder::_copy($child, $builder);

        # Run the subtests and catch the errors.
        my $run_subtests = sub {
            $builder->note("$caller: $name");
            $code->();
            $builder->done_testing unless $builder->_plan_handled;
            return 1;
        };
        if (!eval { $run_subtests->() }) {
            $error = $@;
        }
    }

    # Restore the child and parent test builders.
    Test::Builder::_copy($builder,   $child);
    Test::Builder::_copy($parent, $builder);

    # Restore the parent's TODO.
    $builder->find_TODO(undef, 1, $child->{Parent_TODO});

    # Die after the parent is restored.
    die $error if $error and !eval { $error->isa('Test::Builder::Exception') };

    # Override the level.
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    # Check the results of the subtests.
    if ($check) {
        $child->no_ending(1);
        $child->is_passing(&$check($child));
    }

    # Finalize the child test builder.
    my $finalize = $child->finalize;

    # Bail out if the child test builder bailed out.
    $builder->BAIL_OUT($child->{Bailed_Out_Reason}) if $child->{Bailed_Out};

    return $finalize;
}

=head2 one_of NAME, CODE

Test that passes if exactly one subtest passes.

=cut

sub one_of {
    # Process arguments.
    my ($name, $code) = @_;

    # Define the check: only one subtest must pass.
    my $check = sub {
        my ($child) = @_;
        my $count = 0;
        foreach my $result (@{$child->{Test_Results}}) {
            $count++ if $result->{ok};
        }
        return $count == 1;
    };

    # Run the subtests.
    return _subtest($name, $code, $check);
}

=head2 none_of NAME, CODE

Test that passes if all subtests fail.

=cut

sub none_of {
    # Process arguments.
    my ($name, $code) = @_;

    # Define the check: all subtests must fail.
    my $check = sub {
        my ($child) = @_;
        my $count = 0;
        foreach my $result (@{$child->{Test_Results}}) {
            $count++ if $result->{ok};
        }
        return $count == 0;
    };

    # Run the subtests.
    return _subtest($name, $code, $check);
}

=head2 some_of NAME, CODE

Test that passes if at least one subtest passes.

=cut

sub some_of {
    # Process arguments.
    my ($name, $code) = @_;

    # Define the check: at least one subtest must pass.
    my $check = sub {
        my ($child) = @_;
        my $count = 0;
        foreach my $result (@{$child->{Test_Results}}) {
            $count++ if $result->{ok};
        }
        return $count > 0;
    };

    # Run the subtests.
    return _subtest($name, $code, $check);
}

=head2 all_of NAME, CODE

Test that passes if all subtests pass.

(Basically the same as C<subtest>.)

=cut

sub all_of {
    # Process arguments.
    my ($name, $code) = @_;

    # Define the check: all subtests must pass.
    my $check = sub {
        my ($child) = @_;
        my $count = 0;
        foreach my $result (@{$child->{Test_Results}}) {
            $count++ unless $result->{ok};
        }
        return $count == 0;
    };

    # Run the subtests.
    return _subtest($name, $code, $check);
}

=head2 most_of NAME, CODE

Test that passes if more subtests pass than fail.

=cut

sub most_of {
    # Process arguments.
    my ($name, $code) = @_;

    # Define the check: most subtests must pass.
    my $check = sub {
        my ($child) = @_;
        my $pass = 0;
        my $fail = 0;
        foreach my $result (@{$child->{Test_Results}}) {
            if ($result->{ok}) {
                $pass++;
            } else {
                $fail++;
            }
        }
        return $pass > $fail;
    };

    # Run the subtests.
    return _subtest($name, $code, $check);
}

=head2 ignore NAME, CODE

Test that ignores the results of the subtests.  It always passes.

=cut

sub ignore {
    # Process arguments.
    my ($name, $code) = @_;

    # Define the check: always pass.
    my $check = sub {
        return 1;
    };

    # Run the subtests.
    return _subtest($name, $code, $check);
}

=head1 AUTHOR

Bert Vanderbauwhede, C<< <batlock666 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-subtests at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Subtests>.  I will be
notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Subtests

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Subtests>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Subtests>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Subtests>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Subtests/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Bert Vanderbauwhede.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU Lesser General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option)
any later version.

See L<http://www.gnu.org/licenses/> for more information.

=cut

1; # End of Test::Subtests

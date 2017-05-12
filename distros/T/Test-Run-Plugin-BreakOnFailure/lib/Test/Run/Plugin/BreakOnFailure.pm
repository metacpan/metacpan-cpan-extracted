package Test::Run::Plugin::BreakOnFailure;

use warnings;
use strict;

use 5.008;

use MRO::Compat;

use Moose;

=head1 NAME

Test::Run::Plugin::BreakOnFailure - stop processing the entire test suite
upon the first failure.

=head1 VERSION

Version 0.0.5

=cut

our $VERSION = '0.0.5';

extends('Test::Run::Base');

has 'should_break_on_failure' => (isa => "Bool", is => "rw",);

=head1 SYNOPSIS

    package MyTestRun;

    use Moose

    extends(qw(Test::Run::Plugin::BreakOnFailure Test::Run::Obj);

=head1 FUNCTIONS

=head2 $self->should_break_on_failure()

A boolean flag that determines if the test suite should break after the
first failing test.

=cut

sub _run_all_tests_loop
{
    my $self = shift;

    TEST_FILES_LOOP:
    foreach my $test_file_path (@{$self->test_files()})
    {
        $self->_run_single_test({ test_file => $test_file_path});

        if ($self->should_break_on_failure()
            && (!$self->last_test_results->passing())
           )
        {
            last TEST_FILES_LOOP;
        }
    }
}

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-run-plugin-alternateinterpreters at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test::Run::Plugin::BreakOnFailure>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Run::Plugin::BreakOnFailure

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test::Run::Plugin::BreakOnFailure>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test::Run::Plugin::BreakOnFailure>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test::Run::Plugin::BreakOnFailure>

=item * MetaCPAN

L<https://metacpan.org/release/Test-Run-Plugin-BreakOnFailure>

=back

=head1 ACKNOWLEDGEMENTS

I came up with the idea for this plugin for use for working for my work
for Reask ( L<http://reask.com/> ).

=head1 SEE ALSO

L<Test::Run>, L<Test::Run::CmdLine>, L<TAP::Parser>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Shlomi Fish.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

=cut

1; # End of Test::Run::Plugin::BreakOnFailure

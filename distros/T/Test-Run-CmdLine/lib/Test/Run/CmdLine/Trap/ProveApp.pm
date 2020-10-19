package Test::Run::CmdLine::Trap::ProveApp;

use strict;
use warnings;

use vars (qw($VERSION));

$VERSION = '0.0132';

use parent 'Test::Run::Trap::Obj';

use Test::Trap qw( trap $trap :flow:stderr(systemsafe):stdout(systemsafe):warn );

sub trap_run
{
    my ($class, $args) = @_;

    my $cmdline = $args->{cmdline};

    trap {
        system(
            $^X, "-MTest::Run::CmdLine::Prove::App", "-e", "run()", "--",
            @$cmdline,
        );
    };

    return $class->new({
        ( map { $_ => $trap->$_() }
        (qw(stdout stderr die leaveby exit return warn wantarray)))
    });
}

1;

=head1 NAME

Test::Run::CmdLine::Trap::ProveApp - trap the output of a run of
L<Test::Run::CmdLine::Prove::App>.

=head1 DESCRIPTION

Testing class to trap the output of a
C<perl -MTest::Run::CmdLine::Prove::App ...> run.

=head1 METHODS

=head2 Test::Run::CmdLine::Trap::Prove->trap_run({cmdline => [@ARGS]})

Traps the output of the application with the command line args of C<@ARGS>.
Returns the object. To be used as a constructor.

=head1 AUTHORS

Shlomi Fish, L<http://www.shlomifish.org/>.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-run-cmdline@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Run-CmdLine>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Run::CmdLine::Trap::ProveApp

You can also look for information at:

=over 4

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test::Run::CmdLine>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test::Run::CmdLine>

=item * Search CPAN

L<http://search.cpan.org/dist/Test::Run::CmdLine/>

=back

=head1 SOURCE AVAILABILITY

The latest source of Test::Run::CmdLine is available from the Test::Run
BerliOS Subversion repository:

L<https://svn.berlios.de/svnroot/repos/web-cpan/Test-Harness-NG/>

=head1 ACKNOWLEDGEMENTS

=head1 SEE ALSO

L<Test::Trap>, L<Test::Run::Trap::Obj>

=head1 COPYRIGHT & LICENSE

Copyright 2005 Shlomi Fish, all rights reserved.

This program is released under the MIT X11 License.

=cut

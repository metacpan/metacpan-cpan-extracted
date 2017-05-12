package Test::Run::Plugin::ColorSummary;

use warnings;
use strict;

use 5.008;

use Moose;

use MRO::Compat;
use Term::ANSIColor;
# Needed for ->autoflush()
use IO::Handle;

extends('Test::Run::Base');

=head1 NAME

Test::Run::Plugin::ColorSummary - A Test::Run plugin that
colors the summary.

=head1 VERSION

0.0202

=cut

our $VERSION = '0.0202';

has 'summary_color_failure' => (is => "rw", isa => "Str");
has 'summary_color_success' => (is => "rw", isa => "Str");


sub _get_failure_summary_color
{
    my $self = shift;
    return $self->summary_color_failure() ||
        $self->_get_default_failure_summary_color();
}

sub _get_default_failure_summary_color
{
    return "bold red";
}

sub _get_success_summary_color
{
    my $self = shift;
    return $self->summary_color_success() ||
        $self->_get_default_success_summary_color();
}

sub _get_default_success_summary_color
{
    return "bold blue";
}

=head1 SYNOPSIS

    package MyTestRun;

    use vars qw(@ISA);

    @ISA = (qw(Test::Run::Plugin::ColorSummary Test::Run::Obj));

    my $tester = MyTestRun->new(
        {
            test_files =>
            [
                "t/sample-tests/one-ok.t",
                "t/sample-tests/several-oks.t"
            ],
        }
        );

    $tester->runtests();

=head1 EXTRA PARAMETERS TO NEW

We accept two new named parameters to the new constructor:

=head2 summary_color_success

This is the color string for coloring the success line. The string itself
conforms to the one specified in L<Term::ANSIColor>.

=head2 summary_color_failure

This is the color string for coloring the summary line in case of
failure. The string itself conforms to the one specified
in L<Term::ANSIColor>.

=head1 FUNCTIONS

=cut

sub _report_success
{
    my $self = shift;
    print color($self->_get_success_summary_color());
    $self->next::method();
    print color("reset");
}

=head2 $tester->_handle_runtests_error()

We override _handle_runtests_error() to colour the errors in red. The rest of
the documentation is the code.

=cut

sub _handle_runtests_error_text
{
    my ($self, $args) = @_;

    my $text = $args->{'text'};

    STDERR->autoflush();
    $text =~ s{\n\z}{};
    die color($self->_get_failure_summary_color()).$text.color("reset")."\n";
}

1;

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-run-plugin-colorsummary@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Run-Plugin-ColorSummary>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Run::Plugin::ColorSummary

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test::Run::Plugin::ColorSummary>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test::Run::Plugin::ColorSummary>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test::Run::Plugin::ColorSummary>

=item * Search CPAN

L<http://search.cpan.org/dist/Test::Run::Plugin::ColorSummary/>

=back

=head1 SOURCE AVAILABILITY

The latest source of Test::Run::Plugin::ColorSummary is available from the
Test::Run BerliOS Subversion repository:

L<https://svn.berlios.de/svnroot/repos/web-cpan/Test-Harness-NG/>

=head1 SEE ALSO

L<Test::Run::Obj>, L<Term::ANSIColor>,
L<Test::Run::CmdLine::Plugin::ColorSummary>.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Shlomi Fish, all rights reserved.

This program is released under the MIT X11 License.

=cut


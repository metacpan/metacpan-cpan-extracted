package Test::Run::CmdLine::Plugin::ColorSummary;

use warnings;
use strict;

=head1 NAME

Test::Run::CmdLine::Plugin::ColorSummary - Color the summary in Test::Run::CmdLine.

=cut

our $VERSION = '0.0203';

=head2 $self->private_backend_plugins()

Returns the Backend Plugins as specified by this plugin. See
L<Test::Run::CmdLine> for more information.

=cut

sub private_backend_plugins
{
    my $self = shift;

    return [qw(ColorSummary)];
}

=head2 $self->private_direct_backend_env_mapping()

Returns the HARNESS_SUMMARY_COLOR_FAIL and HARNESS_SUMMARY_COLOR_SUCCESS
environment variables.

=cut

sub private_direct_backend_env_mapping
{
    my $self = shift;
    return [
        {
            'env' => "HARNESS_SUMMARY_COLOR_SUCCESS",
            'arg' => "summary_color_success",
        },
        {
            'env' => "HARNESS_SUMMARY_COLOR_FAIL",
            'arg' => "summary_color_failure",
        },
    ];
}

=head1 SYNOPSIS

This plug-in colors the summary line in Test::Run::CmdLine.

=head1 ENVIRONMENT VARIABLES

This module accepts the followinge environment variables:

=over 4

=item HARNESS_SUMMARY_COLOR_SUCCESS

This specifies the Term::ANSIColor color for the success line.

=item HARNESS_SUMMARY_COLOR_FAIL

This specifies the Term::ANSIColor color for the failure line

=back

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-run-cmdline-plugin-colorsummary@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Run-CmdLine-Plugin-ColorSummary>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Run::CmdLine::Plugin::ColorSummary

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test::Run::CmdLine::Plugin::ColorSummary>

=item * Search CPAN

L<http://search.cpan.org/dist/Test::Run::CmdLine::Plugin::ColorSummary/>

=back

=head1 SOURCE AVAILABILITY

The latest source of Test::Run::CmdLine::Plugin::ColorSummary is available from the
Test::Run BerliOS Subversion repository:

L<https://svn.berlios.de/svnroot/repos/web-cpan/Test-Harness-NG/>

=head1 SEE ALSO

L<Test::Run::Obj>, L<Term::ANSIColor>,
L<Test::Run::Plugin::ColorSummary>.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1;

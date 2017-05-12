package Test::Run::CmdLine::Plugin::ColorFileVerdicts;

use strict;
use warnings;

=head1 NAME

Test::Run::CmdLine::Plugin::ColorFileVerdicts - Color the individual test file
verdicts in Test::Run::CmdLine.

=head1 VERSION

0.0124

=head1 METHODS

=cut

our $VERSION = '0.0124';

=head2 $self->private_backend_plugins()

Returns the Backend Plugins as specified by this plugin. See
L<Test::Run::CmdLine> for more information.

=cut

sub private_backend_plugins
{
    my $self = shift;

    return [qw(ColorFileVerdicts)];
}

=head2 $self->private_non_direct_backend_env_mapping()

Returns the non-direct Backend Environment Mappings, that will specify
the YAML information. See L<Test::Run::CmdLine> for more information.

=cut

sub private_non_direct_backend_env_mapping
{
    my $self = shift;

    return
    [
        {
            type => "varmap",
            env => "PERL_HARNESS_VERDICT_COLORS",
            arg => "individual_test_file_verdict_colors",
        },
    ];
}

=head2 $self->private_backend_args()

Makes L<Test::Run::CmdLine> process the C<PERL_HARNESS_VERDICT_COLORS>
environment variable.

=cut

sub private_backend_args
{
    my $self = shift;

    return $self->_get_file_verdicts_color_mappings();
}

=head1 ENVIRONMENT VARIABLES

=head2 PERL_HARNESS_VERDICT_COLORS

This environment variables specifies a mapping (or hash) where the keys
are the verdict types and the values are the color strings (as understood
by L<Term::ANSIColor>). So for example to specify the color "magenta" for
success and "blue" for failure use:

    export PERL_HARNESS_VERDICT_COLORS="success=magenta;failure=blue"

As you can see the key/value pairs are separated with "C<;>" and "C<=>" is
used for the assignment.

=cut

sub _get_file_verdicts_color_mappings
{
    my $self = shift;

    if (exists($ENV{PERL_HARNESS_VERDICT_COLORS}))
    {
        # FIXME
        my $mapping_string = $ENV{PERL_HARNESS_VERDICT_COLORS};

        my @assignments = split(/\s*;\s*/, $mapping_string);
        return
        [
            individual_test_file_verdict_colors =>
            {map { /\A([^=]*)=(.*)\z/ms ? ($1 => $2) : () } @assignments}
        ];
    }
    else
    {
        return [];
    }
}

=head1 SEE ALSO

L<Test::Run::CmdLine>, L<Test::Run::CmdLine::Plugin::ColorSummary>,
L<Term::ANSIColor>.

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-run-plugin-colorfileverdicts at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Run-Plugin-ColorFileVerdicts>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Run::Plugin::ColorFileVerdicts

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Run-Plugin-ColorFileVerdicts>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Run-Plugin-ColorFileVerdicts>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Run-Plugin-ColorFileVerdicts>

=item * MetaCPAN

L<http://metacpan.org/releaseTest-Run-Plugin-ColorFileVerdicts>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11

=cut


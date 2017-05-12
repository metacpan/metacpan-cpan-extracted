package Test::Run::CmdLine::Plugin::TrimDisplayedFilenames;

use strict;
use warnings;

use 5.008;

=head1 NAME

Test::Run::CmdLine::Plugin::TrimDisplayedFilenames - trim the filenames
that are displayed by the harness to make them more managable.

=head1 DESCRIPTION

This is a L<Test::Run::CmdLine> plugin that allows one to trim the
filenames that are displayed by the harness. It accepts
the parameter by using the C<'HARNESS_TRIM_FNS'>
environment variable. A few sample ones are:

    fromre:\At\z

(to match everything up to a "t" directory.)

    keep:3

(to keep only 3 components).

=head1 VERSION

Version 0.0125

=cut

our $VERSION = '0.0125';

=head1 METHODS

=cut


=head2 $self->private_backend_plugins()

Returns the Backend Plugins as specified by this plugin. See
L<Test::Run::CmdLine> for more information.

=cut

sub private_backend_plugins
{
    my $self = shift;

    return [qw(TrimDisplayedFilenames)];
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
            type => "direct",
            env => "HARNESS_TRIM_FNS",
            arg => "trim_displayed_filenames_query",
        },
    ];
}

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-run-plugin-alternateinterpreters at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test::Run::Plugin::TrimDisplayedFilenames>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Run::CmdLine::Plugin::TrimDisplayedFilenames

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test::Run::CmdLine::Plugin::TrimDisplayedFilenames>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test::Run::Plugin::TrimDisplayedFilenames>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test::Run::Plugin::TrimDisplayedFilenames>

=item * MetaCPAN

L<http://metacpan.org/release/Test-Run-Plugin-TrimDisplayedFilenames>

=back

=head1 SEE ALSO

L<Test::Run::Plugin::TrimDisplayedFilenames>, L<Test::Run>,
L<Test::Run::CmdLine>, L<TAP::Parser>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut


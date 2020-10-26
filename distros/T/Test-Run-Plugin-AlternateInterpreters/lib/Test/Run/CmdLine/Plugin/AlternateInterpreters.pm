package Test::Run::CmdLine::Plugin::AlternateInterpreters;

use strict;
use warnings;

=head1 NAME

Test::Run::CmdLine::Plugin::AlternateInterpreters - Use configurable
alternate interpreters to run the tests.

=head1 DESCRIPTION

This is a L<Test::Run::CmdLine> plugin that allows enabling alternate
interpreters. One can specify them by setting the C<'HARNESS_ALT_INTRP_FILE'>
environment variable to the path to a YAML configuration file which lists the
interpreters and their regular expressions. A sample one is:

    ---
    - cmd: '/usr/bin/ruby'
      pattern: \.rb\z
      type: regex
    - cmd: '/usr/bin/python'
      pattern: \.py\z
      type: regex

=head1 METHODS

=cut

our $VERSION = '0.0125';

=head2 $self->private_backend_plugins()

Returns the Backend Plugins as specified by this plugin. See
L<Test::Run::CmdLine> for more information.

=cut

sub private_backend_plugins
{
    my $self = shift;

    return [qw(AlternateInterpreters)];
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
            type => "yamldata",
            env => "HARNESS_ALT_INTRP_FILE",
            arg => "alternate_interpreters",
        },
    ];
}

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-run-plugin-alternateinterpreters at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test::Run::Plugin::AlternateInterpreters>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Run::CmdLine::Plugin::AlternateInterpreters

You can also look for information at:

=over 4

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test::Run::Plugin::AlternateInterpreters>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test::Run::Plugin::AlternateInterpreters>

=item * MetaCPAN

L<https://metacpan.org/release/Test-Run-Plugin-AlternateInterpreters>

=back

=head1 ACKNOWLEDGEMENTS

Curtis "Ovid" Poe ( L<https://metacpan.org/author/OVID> ) who gave the idea
of testing several tests from several interpreters in one go here:

L<http://use.perl.org/~Ovid/journal/32092>

=head1 SEE ALSO

L<Test::Run::Plugin::AlternateInterpreters>, L<Test::Run>,
L<Test::Run::CmdLine>, L<TAP::Parser>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT Expat.

=cut


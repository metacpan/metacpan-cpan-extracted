package Test::Run::CmdLine::Plugin::BreakOnFailure;

use strict;
use warnings;

use 5.008;

=head1 NAME

Test::Run::CmdLine::Plugin::BreakOnFailure - break on the first test failure.

=head1 DESCRIPTION

This is a L<Test::Run::CmdLine> plugin that terminates the test suite after
the first failing test script. This way, you can know more quickly in case
something went wrong.

To enable, add C<BreakOnFailure> to the C<HARNESS_PLUGINS> environment
variable and set the C<HARNESS_BREAK> environment variable to a true value.

=head1 METHODS

=cut

our $VERSION = '0.0.6';

=head2 $self->private_backend_plugins()

Returns the Backend Plugins as specified by this plugin. See
L<Test::Run::CmdLine> for more information.

=cut

sub private_backend_plugins
{
    my $self = shift;

    return [qw(BreakOnFailure)];
}

=head2 $self->private_direct_backend_env_mapping()

Returns the non-direct Backend Environment Mappings, that will specify
the YAML information. See L<Test::Run::CmdLine> for more information.

=cut

sub private_direct_backend_env_mapping
{
    my $self = shift;

    return
    [
        {
            env => 'HARNESS_BREAK',
            arg => 'should_break_on_failure',
        },
    ];
}

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

My work for Reask which inspired this module.

=head1 SEE ALSO

L<Test::Run::Plugin::BreakOnFailure>, L<Test::Run>,
L<Test::Run::CmdLine>, L<TAP::Parser>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Shlomi Fish.

This program is distributed under the MIT (Expat) License:
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

1;


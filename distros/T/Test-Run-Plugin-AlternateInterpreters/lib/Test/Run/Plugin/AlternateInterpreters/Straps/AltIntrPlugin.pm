package Test::Run::Plugin::AlternateInterpreters::Straps::AltIntrPlugin;

use strict;
use warnings;

=head1 NAME

Test::Run::Plugin::AlternateInterpreters::Straps::AltIntrPlugin - a plugin
for Test::Run::Straps to handle the alternative interpreters.

=head1 DESCRIPTION

This is a plugin for Test::Run::Straps to handle the alternative
interpreters.

=cut

use Moose;

use MRO::Compat;

extends('Test::Run::Base');

has 'alternate_interpreters' => (is => "rw", isa => "ArrayRef");


sub _get_command_and_switches
{
    my $self = shift;

    my $test_file = $self->file();

    if (defined(my $interpreters_ref = $self->alternate_interpreters()))
    {
        foreach my $i_ref (@$interpreters_ref)
        {
            if ($self->_does_interpreter_match($i_ref, $test_file))
            {
                return [split(/\s+/, $i_ref->{'cmd'})];
            }
        }
    }
    return $self->next::method();
}

sub _does_interpreter_match
{
    my ($self, $i_ref, $test_file) = @_;

    my $pattern = $i_ref->{pattern};
    return ($test_file =~ m{$pattern});
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

    perldoc Test::Run::Plugin::AlternateInterpreters

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

L<Test::Run>, L<Test::Run::CmdLine>, L<TAP::Parser>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1;


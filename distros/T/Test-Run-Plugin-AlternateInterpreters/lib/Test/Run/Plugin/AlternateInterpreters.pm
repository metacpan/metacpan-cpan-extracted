package Test::Run::Plugin::AlternateInterpreters;

use warnings;
use strict;

use 5.008;

use MRO::Compat;

use Moose;

=head1 NAME

Test::Run::Plugin::AlternateInterpreters - Define different interpreters for different test scripts with Test::Run.

=head1 VERSION

Version 0.0124

=cut

our $VERSION = '0.0124';

has 'alternate_interpreters' => (is => "rw", isa => "ArrayRef");

extends('Test::Run::Base');


=head1 SYNOPSIS

    package MyTestRun;

    use base 'Test::Run::Plugin::AlternateInterpreters';
    use base 'Test::Run::Obj';

=head1 FUNCTIONS

=cut


sub _init_strap
{
    my ($self, $args) = @_;
    $self->next::method($args);

    $self->Strap()->alternate_interpreters($self->alternate_interpreters());

    return;
}

=head2 $self->private_straps_plugins()

Returns the L<Test::Run::Straps> plugins required by this (L<Test::Run::Obj>)
plugin to be loaded along with it.

=cut

sub private_straps_plugins
{
    my $self = shift;

    return [ "Test::Run::Plugin::AlternateInterpreters::Straps::AltIntrPlugin" ];
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

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test::Run::Plugin::AlternateInterpreters>

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

1; # End of Test::Run::Plugin::AlternateInterpreters

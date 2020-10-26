package Test::Run::Plugin::ColorFileVerdicts::ColorBase;

use strict;
use warnings;

=head1 NAME

Test::Run::Plugin::ColorFileVerdicts::ColorBase - common functionality
that deals with the color fields for both the main object and the
CanonFailedObj.

=head1 DESCRIPTION

For internal use.

=cut

sub _get_individual_test_file_verdict_user_set_color
{
    my ($self, $event) = @_;

    return $self->individual_test_file_verdict_colors() ?
        $self->individual_test_file_verdict_colors()->{$event} :
        undef;
}

sub _get_individual_test_file_color
{
    my ($self, $event) = @_;

    return $self->_get_individual_test_file_verdict_user_set_color($event)
        || $self->_get_default_individual_test_file_verdict_color($event);

}

sub _get_default_individual_test_file_verdict_color
{
    my ($self, $event) = @_;

    my %mapping =
    (
        "success" => "green",
        "failure" => "red",
        "dubious" => "red",
    );
    return $mapping{$event};
}


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

    perldoc Test::Run::Plugin::ColorFileVerdicts::ColorBase

You can also look for information at:

=over 4

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

This program is released under the following license: MIT Expat

=cut

1;


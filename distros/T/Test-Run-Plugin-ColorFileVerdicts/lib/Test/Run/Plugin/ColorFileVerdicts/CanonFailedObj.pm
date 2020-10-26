package Test::Run::Plugin::ColorFileVerdicts::CanonFailedObj;

use strict;
use warnings;

=head1 NAME

Test::Run::Plugin::ColorFileVerdicts::CanonFailedObj - a subclass
of the ::CanonFailedObj that renders the failed line with colors.

=head1 DESCRIPTION

This is a subclass of the ::CanonFailedObj that renders the failed line
with colors.

=cut

use Moose;


extends(
    'Test::Run::Plugin::ColorFileVerdicts::ColorBase'
);

has 'individual_test_file_verdict_colors' =>
    (is => "rw", isa => "Maybe[HashRef]")
    ;

use MRO::Compat;
use Term::ANSIColor;

sub _get_failed_string
{
    my ($self, $canon) = @_;

    my $color = $self->_get_individual_test_file_color("failure");

    return color($color)
         . $self->next::method($canon)
         . color("reset")
         ;
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

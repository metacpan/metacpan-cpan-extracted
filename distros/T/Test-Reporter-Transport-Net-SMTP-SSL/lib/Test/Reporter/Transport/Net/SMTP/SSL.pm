use warnings;
use strict;
BEGIN{ if (not $] < 5.006) { require warnings; warnings->import } }
use 5.006;
package Test::Reporter::Transport::Net::SMTP::SSL;
use base 'Test::Reporter::Transport::Net::SMTP';
use vars qw/$VERSION/;

$VERSION = '0.1.2';

use Net::SMTP::SSL;


__END__

=head1 NAME

Test::Reporter::Transport::Net::SMTP::SSL - SMTP over SSL transport for Test::Reporter

=head1 SYNOPSIS

    my $report = Test::Reporter->new(
        transport => 'Net::SMTP::SSL',
        transport_args => [ %args ],
    );

=head1 DESCRIPTION

This module transmits a Test::Reporter report using Net::SMTP::SSL.

=head1 USAGE

See L<Test::Reporter> and L<Test::Reporter::Transport> for general usage
information.

=head2 Transport Arguments

    $report->transport_args( @args );

Any transport arguments are passed through to the Net::SMTP::SSL constructer.

=head1 METHODS

These methods are only for internal use by Test::Reporter.

=head2 new

    my $sender = Test::Reporter::Transport::Net::SMTP::SSL->new( 
        @args 
    );
    
The C<new> method is the object constructor.   

=head2 send

    $sender->send( $report );

The C<send> method transmits the report.  


=head1 AUTHOR

Theodore Robert Campbell Jr, C<< <trcjr at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-reporter-transport-net-smtp-ssl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Reporter-Transport-Net-SMTP-SSL>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Reporter::Transport::Net::SMTP::SSL


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Reporter-Transport-Net-SMTP-SSL>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Reporter-Transport-Net-SMTP-SSL>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Reporter-Transport-Net-SMTP-SSL>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Reporter-Transport-Net-SMTP-SSL/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Theodore Robert Campbell Jr

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Test::Reporter::Transport::Net::SMTP::SSL

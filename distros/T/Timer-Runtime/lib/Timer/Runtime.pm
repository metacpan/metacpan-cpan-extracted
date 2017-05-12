package Timer::Runtime;
use strict;


use Time::Elapse;

Time::Elapse->lapse( my $now );

BEGIN {
    print "$0 Started: " . ( scalar localtime ) . "\n";
}

END {
    print "$0 Finished: " . ( scalar localtime ) . ", elapsed time = $now\n";
}



=head1 NAME

Timer::Runtime - time a programs runtime

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

Timer::Runtime wraps a program with START and END blocks used to get the
start/stop times and caculate the runtime duration.  This information is printed
to STDOUT.  Note that if the program exists using 'exec', then the stop time
won't be seen due to the END block in Timer::Runtime not being called.

    use Timer::Runtime;

    #  output
    > <script_name> Started: Thu Aug 12 20:34:49 2010
    > <script_name> Finished: Thu Aug 12 20:34:49 2010, elapsed time = 00:00:00.000114

=head1 AUTHOR

Adam H Wohld, C<< <adam at radarlabs.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-timer-runtime at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Timer-Runtime>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc Timer::Runtime


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Timer-Runtime>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Timer-Runtime>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Timer-Runtime>

=item * Search CPAN

L<http://search.cpan.org/dist/Timer-Runtime/>

=back


=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Adam Wohld.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Timer::Runtime

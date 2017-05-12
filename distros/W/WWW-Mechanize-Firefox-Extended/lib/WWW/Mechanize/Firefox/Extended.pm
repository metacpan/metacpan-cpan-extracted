package WWW::Mechanize::Firefox::Extended;

use 5.006;
use strict;
use warnings FATAL => 'all';
use parent 'WWW::Mechanize::Firefox';

use Time::HiRes qw/usleep/;
my $USLEEP_INTERVAL = 200000;   # 200 milliseconds

=head1 NAME

WWW::Mechanize::Firefox::Extended - Adds handy functions to WWW::Mechanize::Firefox

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

Module provides handy functions to check existence of selectors on a page and
to wait for selectors to come into existence.

    use WWW::Mechanize::Firefox::Extended;

    my $mech = WWW::Mechanize::Firefox::Extended->new();
    $mech->get('https://www.example.com/');

    $mech->hasAll('#username', '#password', '#Image1');

    $mech->hasAny('.close-button', '.exit-button', '.out-button');

    $mech->waitAll(5, '#slow-loading-element')
        or die "Expected element not found";

    $mech->waitAny(5, '#slow-loading-element', '#another-element')
        or die "Expected element not found";

=head1 SUBROUTINES/METHODS

=head2 hasAll( $mech, @selectors )

Returns true if all selectors exists. False otherwise.

=cut
sub hasAll {
    my $m = shift;
    for (@_) {
        return 0 if scalar ($m->selector($_,all=>1)) == 0;  # short-circuit
    }
    return 1;
}

=head2 hasAny( $mech, @selectors )

Returns true if any selector exists. False if none exists.

=cut
sub hasAny {
    my $m = shift;
    for (@_) {
        return 1 if scalar ($m->selector($_,all=>1)) > 0;  # short-circuit
    }
    return 0;
}

=head2 waitAll( $mech, $max_wait_seconds, @selectors )

Wait until all selectors are present or the wait times out.
Returns true if all selectors found or false if none found 
within the timeout period.

Uses Time::HiRes

=cut
sub waitAll {
    my ($m, $timeout, @selectors) = @_;
    my ($slept, $max_sleep) = (0, $timeout * 1000000); # microseconds
    while ($slept < $max_sleep) {
        return 1 if (hasAll($m, @selectors));
        usleep($USLEEP_INTERVAL);    # sleep 200 milliseconds
        $slept += $USLEEP_INTERVAL;
    }
    return 0;
}

=head2 waitAny( $mech, $max_wait_seconds, @selectors )

Wait until any selectors are present or the wait times out.
Returns true if any selectors are or false if none found 
within the timeout period.

Uses Time::HiRes

=cut
sub waitAny {
    my ($m, $timeout, @selectors) = @_;
    my ($slept, $max_sleep) = (0, $timeout * 1000000); # microseconds
    while ($slept < $max_sleep) {
        return 1 if (hasAny($m, @selectors));
        usleep($USLEEP_INTERVAL);    # sleep 200 milliseconds
        $slept += $USLEEP_INTERVAL;
    }
    return 0;
}



=head1 AUTHOR

Hoe-Kit Chew, C<< <hoekit at gmail dot com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-mechanize-firefox-extended at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Mechanize-Firefox-Extended>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Mechanize::Firefox::Extended


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Mechanize-Firefox-Extended>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Mechanize-Firefox-Extended>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Mechanize-Firefox-Extended>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Mechanize-Firefox-Extended/>

=back

=head1 REPOSITORY AND PULL REQUESTS

This module is available on GitHub at
L<https://github.com/hoekit/www-mechanize-firefox-extended/>. 

Pull requests welcomed.

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Hoe-Kit Chew.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.10.0 or, at
your option, any later version of Perl 5 you may have available.

=cut

1; # End of WWW::Mechanize::Firefox::Extended

package WWW::ClickSource::Request;

use strict;
use warnings;

=head1 NAME

WWW::ClickSource::Request - Generic Request object that contains the info we need about the request

=head1 DESCRIPTION

Simple object that contains the data we need in order to dectect where the user came from

=head1 METHODS

=head2 new

Creates a new C<WWW::ClickSource::Request> object

=cut
sub new {
    my ($class,$request)  = @_;
    
    if (ref($request) eq "Catalyst::Request") {
        require WWW::ClickSource::Request::CatalystRequest;
        return WWW::ClickSource::Request::CatalystRequest->new($request);
    }
    else {
        my $self = {
            host => $request->{host},
            params => $request->{params},
            referer => $request->{referer} ? URI->new($request->{referer}) : undef,
        };
        
        bless $self, $class;
        
        return $self;
    }
}

1;

=head1 AUTHOR

Gligan Calin Horea, C<< <gliganh at gmail.com> >>

=head1 REPOSITORY

L<https://github.com/gliganh/WWW-ClickSource>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-session at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-ClickSource>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::ClickSource::Request


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-ClickSource>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-ClickSource>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-ClickSource>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-ClickSource>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Gligan Calin Horea.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

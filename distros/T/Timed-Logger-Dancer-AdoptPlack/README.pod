package Timed::Logger::Dancer::AdoptPlack;

use 5.16.0;
use strict;
use warnings;

use Moose;
use Plack::Middleware::Timed::Logger;
use Dancer qw();

=head1 NAME

Timed::Logger::Dancer::AdoptPlack - Use Plack Timed::Logger Middleware with Dancer

=head1 VERSION

Version 0.0.5

=cut

our $VERSION = '0.0.5';

=head1 SYNOPSIS

    use Timed::Logger::Dancer::AdoptPlack;

    my $logger = Timed::Logger::Dancer::AdoptPlack->logger;
    my $log_entry = $logger->start('DB');
    ...

=head1 DESCRIPTION

This module bridges L<Plack> middleware L<Plack::Middleware::Timed::Logger> with
L<Dancer> application.  It provides method of getting and instance of L<Timed::Logger>
to log events.  Those events can be later displayed by L<Plack::Middleware::Debug::Timed::Logger>
debug panel.

This module was inspired by L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog::AdoptPlack>.

=head1 SUBROUTINES

=head2 logger

Static method to get a L<Timed::Logger> instance.

=cut

sub logger {
  my $request = Dancer->request;
  return Plack::Middleware::Timed::Logger->get_logger_from_env($request ? $request->env : {});
}

=head1 SEE ALSO

L<Timed::Logger>, L<Plack::Middleware::Timed::Logger>,
L<Plack::Middleware::Debug::Timed::Logger>, L<Plack::Middleware::Debug>

=head1 AUTHOR

Nikolay Martynov, C<< <kolya at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-timed-logger-dancer-adoptplack at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Timed-Logger-Dancer-AdoptPlack>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Timed::Logger::Dancer::AdoptPlack


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Timed-Logger-Dancer-AdoptPlack>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Timed-Logger-Dancer-AdoptPlack>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Timed-Logger-Dancer-AdoptPlack>

=item * Search CPAN

L<http://search.cpan.org/dist/Timed-Logger-Dancer-AdoptPlack/>

=back


=head1 ACKNOWLEDGEMENTS

Logan Bell and Belden Lyman.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Nikolay Martynov and Shutterstock Inc (http://shutterstock.com). All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Timed::Logger::Dancer::AdoptPlack

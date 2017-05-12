package WWW::Opentracker::Stats::UserAgent;

use strict;
use warnings;

use LWP::UserAgent;

=head1 NAME

WWW::Opentracker::Stats::UserAgent - Factory package for creating a user agents

=head1 DESCRIPTION

A factory package with helper methods for creating user agents for use with
opentracker statistics.

=head1 METHODS

=head2 default

Returns a default user agent object.

This creates a new L<LWP::UserAgent> object, sets the timeout to 5 seconds,
uses any proxy settings from the environment and sets a custom agent name.

=cut

sub default {
    my $ua = LWP::UserAgent->new;

    $ua->timeout(5);
    $ua->env_proxy;
    $ua->agent('Opentracker Stats/1.0 ');

    return $ua;
}


=head1 SEE ALSO

L<LWP::UserAgent>


=head1 AUTHOR

Knut-Olav Hoven, E<lt>knutolav@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Knut-Olav Hoven

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;

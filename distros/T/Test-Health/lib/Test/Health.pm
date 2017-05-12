package Test::Health;
use strict;
use warnings;
our $VERSION = '0.003'; # VERSION

=head1 NAME

Test::Health - Perl API to process tests and send an e-mail report in case of failures

=head1 SYNOPSIS

This module is only Pod.

See the Pod of health_check.pl script for details of usage.

For information regarding extending this distribution, check the other Pods available.

=head1 DESCRIPTION

Test-Health is a Perl distribution created to implement a "poor's man" health check API.

By using standard test modules like Test-Simple, you can implement your tests and use Test-Health
to run those tests, collect results and send an e-mail in the case any test fails.

This is usefull if you want to implement a simple health check on your system, but don't have a monitoring system
like Nagios (or don't want to use one). Once you have the test files, it is pretty straighforward to send an e-mail
in case of problems.

Be sure to check the Pod documentation include in this distribution for more details.

=head1 SEE ALSO

=over

=item *

L<Test::Health::Email>

=item *

L<Test::Health::Harness>

=back

Test-Health also relies on good modules from CPAN like:

=over

=item *

L<Moo>

=item *

L<Email::Stuffer>

=item *

L<TAP::Formatter::HTML>

=item *

L<Email::Sender::Transport::SMTP>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

This file is part of Test-Health distribution.

Test-Health is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Test-Health is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Test-Health. If not, see <http://www.gnu.org/licenses/>.

=cut

1;

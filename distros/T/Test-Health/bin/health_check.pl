#!perl

use warnings;
use strict;
use Getopt::Std;
use Pod::Usage;
use Test::Health::Harness;
use Test::Health::Email;

our $VERSION = '0.004'; # VERSION

my %opts;
getopts( 'a:d:t:f:s:h', \%opts );
pod2usage( -exitstatus => 1, -verbose => 0 );

foreach my $param (qw(a d t f)) {
    die "must have a defined value for $param parameter"
      unless ( ( exists( $opts{$param} ) ) and ( defined( $opts{$param} ) ) );
}

my $test = Test::Health::Harness->new( { dir => $opts{d} } );
my ( $test_name, $attachment ) = $test->test_health();

if ( ( defined($test_name) ) and ( defined($attachment) ) ) {
    my $sender;

    if ( exists( $opts{s} ) ) {
        Test::Health::Email->new(
            { to => $opts{t}, from => $opts{f}, host => $opts{s} } );
    }
    else {
        Test::Health::Email->new( { to => $opts{t}, from => $opts{f} } );
    }
    $sender->send_email( $test_name, $attachment, $opts{a} );
}

__END__

=head1 NAME

health_check.pl - command line script to execute tests and send an e-mail in case of failures

=head1 SYNOPSIS

    health_check.pl [options]

    Options:

      -a: application name being tested (will be included in the e-mail subject). Required.
      -d: directory containing the test files. Required.
      -t: e-mail address to send the report in case of failures. Required.
      -f: e-mail address of the sender. Required.
      -s: SMTP server hostname. Optional, defaults to localhost.
      -h: this help message

=head1 DESCRIPTION

This script will execute all tests inside the directory specificed by the C<-d> parameter. Assuming
that all the tests are working properly, it will check the results of the tests after execution.

If any failure is detected, an HTML report will be created and send by e-mail.

=head1 REQUIREMENTS

Tests must procude TAP output. See Test::Harness.

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


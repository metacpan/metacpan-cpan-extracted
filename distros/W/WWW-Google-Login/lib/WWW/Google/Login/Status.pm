package WWW::Google::Login::Status;
use strict;
use Moo 2;

use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.01';

has wrong_password => ( is => 'ro' );
has logged_in      => ( is => 'ro' );

=head1 NAME

WWW::Google::Login::Status - status value for WWW::Google::Login

=head1 SYNOPSIS

    if( $status->logged_in ) {
        print "yay\n";
    } elsif( $status->wrong_password ) {
        print "wrong password!\n";
    } else {
        print "unknown error\n";
    }

This module isn't intended for direct usage

=cut

1;

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/WWW-Google-Login>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2016-2018 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut

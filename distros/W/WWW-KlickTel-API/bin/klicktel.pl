#!/usr/bin/perl

use strict;
use warnings;
use feature 'say';

=head1 NAME

klicktel.pl - A program for demonstrating the KlickTel API module

=head1 VERSION

Version: $Revision: 31 $
$Id: klicktel.pl 31 2013-03-11 17:08:06Z sysdef $

=cut

my ($VERSION) = ( q$Revision: 31 $ =~ /(\d+)/ );

=head1 SYNOPSIS

    klicktel.pl {[-h] | [-v]}
    klicktel.pl [test] [invers <phone number>]

    Options:
      -h      help
      -v      version

    Commands:
      Command  | Description
      -----------------------------------------------
      test     | internal module tests
      invers   | reverse lookup <phone number>

=head1 SETTINGS

Get an API key at http://openapi.klicktel.de/login/register

  my $API_KEY = '1234567890123456789013456789012';

-OR- put to ~/.klicktel/api_key.txt

=cut

my $API_KEY = '';

=head1 DEPENDENCIES

    WWW::KlickTel::API

=cut

use Data::Dumper;

# load local module(s)
use WWW::KlickTel::API;

# process options and parameter $ARGV[0]
my $method   = $ARGV[0];
my $option_0 = q{};
$option_0 = $ARGV[1] if $ARGV[1];

# no option or command
if ( !defined $method ) {
    say 'Usage: klicktel.pl {[-h] | [-v] | [option <value>]}';
    say '       use "klicktel.pl -h" for help.';
}

# help request
elsif ( $method eq '-h' ) {
    use Pod::Usage;
    pod2usage(1);
}

# version request
elsif ( $method eq '-v' ) {
    say "Version $VERSION";
}

# test for existing method
elsif ( exists &{ 'WWW::KlickTel::API::' . $method } ) {

    # create object
    my $klicktel = WWW::KlickTel::API->new(
        api_key => $API_KEY,    # required
           # protocol    => 'http' or 'https',                      # optional
           # cache_path  => '/var/cache/www-klicktel-api/',         # optional
           # uri_invers  => 'openapi.klicktel.de/searchapi/invers', # optional
    );

    if ( $method eq 'test' ) {

        # run selftest
        my $error_count;
        $error_count = $klicktel->test();
        say 'Module test: '
            . ( $error_count ? "FAILED. $error_count error(s)" : 'OK' );
    }
    elsif ( $method eq 'invers' ) {

        # invers - reverse lookup numbers
        if ( $option_0 !~ /^[0-9]+\z/ ) {
            say "Usage: $0 invers <phone number>";
            if ($option_0) {
                say "   '$option_0' is not a valid phone number.\n"
                    . "   Example: $0 invers 0401234567";
            }
            exit;
        }

        # print the hash dump
        say Dumper( $klicktel->invers($option_0) );
    }
}
else {
    # we didn't get a valid method or a command
    say 'None such method "' . $method . '".\nTry "' . $0 . ' -h".';
}

=head1 AUTHOR

Juergen Heine, C<< < sysdef AT cpan D0T org > >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-klicktel-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-KlickTel-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::KlickTel::API

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-KlickTel-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-KlickTel-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-KlickTel-API>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-KlickTel-API/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Juergen Heine ( sysdef AT cpan D0T org ).

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;

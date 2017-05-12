package WWW::KlickTel::API;

use 5.008001;  # perl 5.8.1
use strict;
use warnings FATAL => 'all';
use Carp qw(croak carp);
use feature 'say';

use REST::Client;
use JSON::XS;
use DB_File;
use Fcntl;

=head1 NAME

WWW::KlickTel::API - A module to use openapi.klicktel.de (Linux only)

=head1 VERSION

Version $Revision: 34 $

$Id: API.pm 34 2013-03-14 14:51:02Z sysdef $

=cut

our ($VERSION) = ( q$Revision: 34 $ =~ /(\d+)/ );

=head1 SYNOPSIS

This module provides a basic access to the KlickTel API
http://openapi.klicktel.de

NOTE: This POC version supports reverse lookups only.

Get an API key at http://openapi.klicktel.de/login/register

  #!/usr/bin/perl
  use strict;
  use warnings;
  use WWW::KlickTel::API;

  my $klicktel = WWW::KlickTel::API->new(
      api_key       => '1234567890123456789013456789012',
  );

  #     -OR-
  # create a key file at ~/.klicktel/api_key.txt and run

  my $klicktel = WWW::KlickTel::API->new();

=cut

# --- GLOBAL VARIABLES ---
my %cache_invers = ();

# system username
my $username = $ENV{LOGNAME} || $ENV{USER} || getpwuid($<);

=head1 METHODS

=head2 new

Create the object. All parameter are optional.

  my $klicktel = WWW::KlickTel::API->new(
      api_key     => '01234567890abcdef01234567890abcd',
      protocol    => 'https',           # or 'http' (http is default)
      cache_path  => '/var/cache/www-klicktel-api/',
      uri_invers  => 'openapi.klicktel.de/searchapi/invers',
      timeout     => 10,                # ( 1- 600 seconds)
      ca_file     => '/path/to/ca.file',
      client_auth => {
          'cert'      => '/path/to/ssl.crt',
          'key'       => '/path/to/ssl.key',
      },
      proxy_url       => 'http://proxy.example.com',
  );

=cut

sub new {
    my $class = shift;
    croak 'Odd number of elements passed when even was expected' if @_ % 2;
    my %args = @_;

    my $self = {
        PROTOCOL     => $args{protocol}
            || 'http',
        CACHE_PATH   => $args{'cache_path'}
            || '/var/cache/www-klicktel-api/',
        URI_INVERS   => $args{'uri_invers'}
            || 'openapi.klicktel.de/searchapi/invers',
        REST_TIMEOUT => $args{'timeout'}
            || 10,
        REST_CA_FILE => $args{'ca_file'}
            || q{},
        CLIENT_CERT  => $args{'client_auth'}{'cert'}
            || q{},
        CLIENT_KEY   => $args{'client_auth'}{'key'}
            || q{},
        PROXY_URL    => $args{'proxy_url'}
            || q{},
    };

    $self->{API_KEY} = $args{'api_key'};
    if ( !$self->{API_KEY} ) {

        # checking for user's API Key
        $self->{API_KEY_FILE} = '/home/' . $username . '/.klicktel/api_key.txt';
        if ( -r $self->{API_KEY_FILE} ) {

            # loading user's api key
            my $api_key_fh;
            open $api_key_fh, "<", $self->{API_KEY_FILE};
            binmode $api_key_fh;
            read $api_key_fh, $self->{API_KEY}, 32;
        }
        else {
            say 'Hint: You can save your API Key at ' . $self->{API_KEY_FILE};
            die('FATAL ERROR: No API Key was given.');
        }
    }

    $self->{CACHE_FILE_INVERS} = $self->{CACHE_PATH} . $username . '.invers.dat';

    # invers phone number cache
    if ( ref $cache_invers{$self->{CACHE_PATH}} ne 'HASH' ) {
        tie %{$cache_invers{$self->{CACHE_PATH}}}, 'DB_File',
          $self->{CACHE_FILE_INVERS}, O_CREAT | O_RDWR, 0666
          or die "Can't initialize DB_File file ("
            . $self->{CACHE_FILE_INVERS}
            . " ): $!\n";
    }

    bless $self, $class;

    return $self;
}

=head2 test

Run selftest

  # run selftest
  my $error_count;
  $error_count = $klicktel->test();
  print 'Module test: ' . ( $error_count ? "FAILED. $error_count error(s)\n" : "OK\n" );

=cut

sub test {
    my ( $self, $number ) = @_;
    my $error_count = 0;

    eval "use Test::Simple tests => 6; 1";

    ok(
        ( defined $self->{API_KEY}
            and $self->{API_KEY} =~ m/^[0-9a-f]{32}\z/ ) == 1,
        'API Key format'
    ) or $error_count++;

    ok( ( $self->{REST_TIMEOUT} gt 0 ) and ( $self->{REST_TIMEOUT} lt 600 ),
        'Network Timeout 1-600 seconds' )
        or $error_count++;

    ok( -W $self->{CACHE_PATH}, 'writable cachedir (' . $self->{CACHE_PATH} . ')' )
        or $error_count++;

    ok( -W $self->{CACHE_FILE_INVERS}, 'writable invers cache' )
        or $error_count++;

    $cache_invers{$self->{CACHE_PATH}}{'test'} = 'test ok';
    ok( $cache_invers{$self->{CACHE_PATH}}{'test'}
        eq 'test ok', 'phone number cache connected' )
            or $error_count++;
    delete $cache_invers{$self->{CACHE_PATH}}{'test'};

    delete $cache_invers{$self->{CACHE_PATH}}{'110'};
    my $result_hash_ref = invers($self, '110');
    if ( ref $result_hash_ref->{'response'}{'error'} eq 'HASH' ) {
        warn( "API ERROR MESSAGE: "
            . $result_hash_ref->{'response'}{'error'}{'message'} );
    }
    ok(
        eval {
            $result_hash_ref->{'response'}{'results'}[0]{'total'} gt 5000;
        },
        'more than 5000 hits for "Notruf" in reverse lookup for number "110"'
    ) or $error_count++;

    return $error_count;
}

=head2 invers

Do reverse lookups of phone numbers

  # reverse lookup phone numbers
  use Data::Dumper qw(Dumper);
  my $result = $klicktel->invers($phone_number);
  print Dumper($result);

=cut

sub invers {
    my ( $self, $number ) = @_;

    my $result = ();

    if ( $cache_invers{$self->{CACHE_PATH}}{$number} ) {

        # number is cached

        my $result_json = $cache_invers{$self->{CACHE_PATH}}{$number};
        $result = decode_json $result_json;
    }
    else {

        # number is not cached

        # create and configure REST API connection
        my $rest_connect = _REST_connect();

        # get data
        $rest_connect->GET(
                $self->{PROTOCOL} . '://'
                . $self->{URI_INVERS} . '?' . 'key='
                . $self->{API_KEY}
                . '&number='
                . $number
                . '&parents_only=1'
        );

        my $result_json = $rest_connect->responseContent();

        # save result
        $cache_invers{$self->{CACHE_PATH}}{$number} = $result_json;

        # decode json construct to hash
        $result = decode_json $result_json;

        undef $rest_connect;

    }

    return $result;
}

=head1 SUBROUTINES (for internal use only)

=head2 _REST_connect

Create and configure REST API connection

  _REST_connect();

=cut

sub _REST_connect {
    my $self = shift;

    # create object
    my $rest_connect = REST::Client->new();

    # proxy support
    if ($self->{PROXY_URL}) {
        $rest_connect->getUseragent()->proxy( ['http'], $self->{PROXY_URL} );
    }

    # X509 client authentication
    if ( $self->{CLIENT_CERT} and $self->{CLIENT_KEY} ) {
        $rest_connect->setCert($self->{CLIENT_CERT});
        $rest_connect->setKey($self->{CLIENT_KEY});
    }

    # add a CA to verify server certificates
    if ($self->{REST_CA_FILE}) {
        $rest_connect->setCa($self->{REST_CA_FILE});
    }

    # timeout on requests, in seconds
    $rest_connect->setTimeout($self->{REST_TIMEOUT});

    return $rest_connect;
}

sub DESTROY {
    my $self = shift;

    untie %{$cache_invers{$self->{CACHE_PATH}}}
        or die "cannot untie inverse cache in " . $self->{CACHE_PATH};

    return;
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

package WWW::Datafinder;

use 5.010;
use strict;
use warnings;

=head1 NAME

WWW::Datafinder - Perl API for Datafinder L<< http://datafinder.com >> API for marketing data append

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use Carp qw(cluck);
use Data::Dumper;
use REST::Client;
use JSON::XS;
use URI;
use Scalar::Util qw(blessed reftype);
use Readonly;
use Exporter 'import';
use File::Path qw(make_path);
use File::Spec::Functions qw(catfile catdir splitpath);
use Digest::MD5 qw(md5 md5_hex);
use Storable qw(nstore retrieve dclone);

use Mouse;

#** @attr public String $api_key API access key
#*
has api_key => ( isa => 'Str', is => 'rw', required => 1 );

#** @attr public Int $cache_time How long locally cached results are valid
#*
has cache_time => ( isa => 'Int', is => 'rw', default => 0 );

#** @attr public Int $cache_dir Whether to store locally cached results
#*
has cache_dir => ( isa => 'Str', is => 'rw', default => '/var/tmp/datafinder-cache' );

#** @attr public Int $retries How many times retry upon timeout
#*
has retries => ( isa => 'Int', is => 'rw', default => 5 );

#** @attr protected String $base_url Base REST URL
#*
has base_url => (
    isa     => 'Str',
    is      => 'rw',
    default => 'http://api.datafinder.com/qdf.php'
);

#** @attr protected CodeRef $ua Reference to the REST UA
#*
has ua => (
    isa      => 'Object',
    is       => 'rw',
    lazy     => 1,
    init_arg => undef,
    default  => sub {
        return REST::Client->new();
    }
);

#** @attr public String $error_message Error message regarding the last failed operation
#*
has error_message =>
  ( isa => 'Str', is => 'rw', init_arg => undef, default => '' );

sub _url {
    my ( $self, $query_params ) = @_;

    $query_params //= {};
    my $uri = URI->new( $self->base_url, 'http' );
    $uri->query_form($query_params);
    #print "URL=".$uri->as_string;
    return $uri->as_string;
}

sub _process_response {
    my ( $self, $response ) = @_;

    if ($@) {
        $self->error_message("Error $@");
        return undef;
    } elsif ( !blessed($response) ) {
        $self->error_message(
            "Unknown response $response from the REST client instead of object"
        );
        return undef;
    }
    print "Got response:"
      . Dumper( $response->responseCode() ) . "/"
      . Dumper( $response->responseContent() ) . "\n"
      if $ENV{DEBUG};
    my $code = $response->responseCode();
    my $parsed_content = eval { decode_json( $response->responseContent() ) };
    if ($@) {
        cluck(  "Cannot parse response content "
              . $response->responseContent()
              . ", error msg: $@. Is this JSON?" );
        $parsed_content = {};
    }
    print "parsed " . Dumper($parsed_content) if $ENV{DEBUG};
    if ( $code ne '200' && $code ne '201' ) {
        my $err = "Received error code $code from the server instead of "
          . 'expected 200/201';
        if ( reftype($parsed_content) eq 'HASH'
            && $parsed_content->{message} )
        {
            $err .=
                "\nError message from server: "
              . $parsed_content->{message}
              . (
                $parsed_content->{error_code}
                ? ' (' . $parsed_content->{error_code} . ')'
                : q{}
              );

            $self->error_message($err);
        }
        return undef;
    }

    $self->error_message(q{});
    if (reftype($parsed_content) eq 'HASH' && $parsed_content->{datafinder}) {
        return $parsed_content->{datafinder};
    }
    return $parsed_content;
}

sub _cache_file_name {
    my ( $self, $query_params, $data ) = @_;
    
    my $md5 = md5_hex(Dumper($query_params).Dumper($data));
    my $fname = catdir($self->cache_dir, 
                       substr($md5, 0, 2),
                       substr($md5, 2, 2));
    unless ( -d $fname ) {
        my $err;
        unless (
            make_path(
                $fname,
                {
                    mode  => 0700,
                    error => \$err
                   }
               )
           )
          {
              warn(
                  "Cannot create cache directory : $fname ($err),".
                    " caching turned off");
              $self->cache_time(0);
          }
    }
    
    $fname = catfile($fname, "$md5.stor");
    return $fname;
}

sub _transaction {
    my ( $self, $query_params, $data ) = @_;

    $data //= {};
    $query_params->{k2} = $self->api_key unless $query_params->{k2};
    my $url = $self->_url($query_params);
    my $headers = { 'Content-Type' => 'application/json' };
    my $response;
    #    print "JSON data ".encode_json($data);

    my $f = $self->_cache_file_name($query_params, $data);
    if ($self->cache_time && -s $f) {
        # there is a cache file!
        my $t = (stat($f))[9];
        if ($t + $self->cache_time > time()) {
            # recent enough
            my $data = eval { retrieve($f); };
            if (!$@ && $data) {
                if ($data->{errors} || $data->{datafinder}->{errors}) {
                    print "Cached object $f contains error response - removing\n" if $ENV{DEBUG};
                    unlink($f);
                } else {
                    print "Retrieved ".Dumper($query_params).Dumper($data)." from cache $f\n" if $ENV{DEBUG};
                    $data->{cached} = $t;
                    $data->{cache_object} = $f;
                    return $data;
                }
            }
        } else {
            # too old
            print "Cached object $f is too old - removing\n" if $ENV{DEBUG};
            unlink($f);
        }
    }

    for my $try ( 1 .. $self->retries ) {
        $response =
          eval { 
              print "Sent request to $url\n".
                "Headers: ".
                JSON::XS->new->pretty(1)->encode($headers)."\n".
                    "Post data: ".
                      JSON::XS->new->pretty(1)->encode($data) if $ENV{DEBUG};
              $self->ua->POST( $url, encode_json($data), $headers );
          };
        if ($@) {
            cluck($@);
            sleep( int( 1 + rand() * 3 ) * $try );
        } else {
            last;
        }
    }
    
    my $res = $self->_process_response($response);

    # all is good, perhaps we should cache it?
    if ($res && $self->cache_time) {

        unless ($res->{erros}) {
            nstore($res, $f);
            print "Stored result in cache file $f\n" if $ENV{DEBUG};
        }
    }

    return $res;
}

=head1 SYNOPSIS

    use WWW::Datafinder;
    use Text::CSV_XS;
    use Data::Dumper;

    my $csv = Text::CSV_XS->new;
    my $df  = WWW::Datafinder->new( {
          api_key    => '456', # place a real API key here
          cache_dir  => '/var/tmp/datafinder',
          cache_time => 3600 * 24 * 14
    }) or die 'Cannot create Datafinder object';

    # process a CSV file with 6 columns:
    # First Name, Last Name, Address, City, State, ZIP
    while(<>) {
      chomp;
      my $status = $csv->parse($_);
      unless ($status) {
          warn qq{Cannot parse '$_':}.$csv->error_diag();
          next;
      }
      my ($name, $surname, $addr, $city, $state, $zip) = $csv->fields();
      my $data = {
            d_first    => $name,
            d_last     => $surname,
            d_fulladdr => $addr,
            d_city     => $city,
            d_state    => $state,
            d_zip      => $zip
      };
      my $res = $df->append_email($data);
      if ($res) {
        if ( $res->{'num-results'} ) {
            # there is a match!
            print "Got a match for $name $surname: " . Dumper( $res->{results} );
        }
      }
    }
 
=head1 CONSTRUCTOR

=head2 new( hashref )

Creates a new object, acceptable parameters are:

=over 16

=item C<api_key> - (required) the key to be used for read operations

=item C<retries> - how many times retry the request upon error (e.g. timeout). Default is 5.

=item C<cache_time> - for how long the cached result is valid(in seconds). 0 (default) turns caching off.

=item C<cache_dir> - directory where cache files are stored, default is /var/tmp/datafinder-cache

=back

=head1 METHODS

=head2 append_email( $data )

Attempts to append customer's email based on his/her name and address (or phone
number). Please see L<< https://datafinder.com/api/docs-demo >> for more
info regarding the parameter names and format of their values in C<$data>.
Returns a reference to a hash, which contains the response
received from the server.
Returns C<undef> on failure, application then may call
C<error_message()> method to get the detailed info about the error.

    my $res = $df->append_email(
        {
            d_fulladdr => $cust->{Address},
            d_city     => $cust->{City},
            d_state    => $cust->{State},
            d_zip      => $cust->{ZIP},
            d_first    => $cust->{Name},
            d_last     => $cust->{Surname}
        }
    );
    if ( $res ) {
        if ( $res->{'num-results'} ) {
            # there is a match!
            print "Got a match: " . Dumper( $res->{results} );
        }
    } else {
        warn 'Something went wrong ' . $df->error_message();
    }

=cut

sub append_email {
    my ( $self, $data ) = @_;
    $data->{service} = 'email';

    return $self->_transaction( $data, {} );
}

=head2 append_phone( $data )

Attempts to append customer's phone number based on his/her name and address
Please see L<< https://datafinder.com/api/docs-demo >> for more
info regarding the parameter names and format of their values in C<$data>.
Returns a reference to a hash, which contains the response
received from the server.
Returns C<undef> on failure, application then may call
C<error_message()> method to get the detailed info about the error.

    my $res = $df->append_phone(
        {
            d_fulladdr => $cust->{Address},
            d_city     => $cust->{City},
            d_state    => $cust->{State},
            d_zip      => $cust->{ZIP},
            d_first    => $cust->{Name},
            d_last     => $cust->{Surname}
        }
    );
    if ( $res ) {
        if ( $res->{'num-results'} ) {
            # there is a match!
            print "Got a match: " . Dumper( $res->{results} );
        }
    } else {
        warn 'Something went wrong ' . $df->error_message();
    }

=cut

sub append_phone {
    my ( $self, $data ) = @_;
    $data->{service} = 'phone';

    return $self->_transaction( $data, {} );
}

=head2 append_demograph( $data )

Attempts to append customer's demographic data on his/her name and address
Please see L<< https://datafinder.com/api/docs-demo >> for more
info regarding the parameter names and format of their values in C<$data>.
Returns a reference to a hash, which contains the response
received from the server.
Returns C<undef> on failure, application then may call
C<error_message()> method to get the detailed info about the error.

    my $res = $df->append_demograph(
        {
            d_fulladdr => $cust->{Address},
            d_city     => $cust->{City},
            d_state    => $cust->{State},
            d_zip      => $cust->{ZIP},
            d_first    => $cust->{Name},
            d_last     => $cust->{Surname}
        }
    );
    if ( $res ) {
        if ( $res->{'num-results'} ) {
            # there is a match!
            print "Got a match: " . Dumper( $res->{results} );
        }
    } else {
        warn 'Something went wrong ' . $df->error_message();
    }

=cut

sub append_demograph {
    my ( $self, $data ) = @_;
    $data->{service} = 'demograph';

    return $self->_transaction( $data, {} );
}


=head2 error_message()

Returns the detailed explanation of the last error. Empty string if
everything went fine.

    my $res = $df->append_email($cust_data);
    unless ($res) {
        warn 'Something went wrong '.$df->error_message();
    }

If you want to troubleshoot the data being sent between the client and the
server - set environment variable DEBUG to a positive value.

=cut

=head1 CACHING

The returned results can be cached in a local file, so the next time you
want to retrieve the data for the same person, you get a faster response and
do not have to spend money. Negative results (no match) are cached as well
to speed things up.

The hash key for a request is calculated as MD5 of all request parameters
(including API key). The result is stored in a file (via Storable).
Files are organized in the two-level directory structure (so
fea5ffd3d65ee4d8bdf630677c0c5ff6.stor goes into /var/tmp/datafinder-cache/fe/a5/)
to accommodate potentially large amount of files.

When a result is returned from the cache instead of the real server, it has
the C< cached > key set to the timestamp of the original data retrieval and
C< cache_object > set to the filename of the cache file.

=head1 AUTHOR

Andrew Zhilenko, C<< <perl at putinhuylo.org> >>
(c) Putin Huylo LLC, 2017

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-datafinder at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Datafinder>. 
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Datafinder


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Datafinder>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Datafinder>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Putin Huylo LLC

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

__PACKAGE__->meta->make_immutable;

1;    # End of WWW::Datafinder

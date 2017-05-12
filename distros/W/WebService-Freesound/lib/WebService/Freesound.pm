package WebService::Freesound;
use strict;
use warnings;

use 5.008;

use LWP::Simple;
use LWP::UserAgent;
use Carp;

use JSON qw(decode_json);

# Freesound.org urls.
#
our %urls = (
    'base'         => 'https://www.freesound.org/apiv2',
    'code'         => '/oauth2/authorize/',
    'access_token' => '/oauth2/access_token/',
    'search'       => '/search/text/?',
    'download'     => '/sounds/_ID_/download/',
    'me'           => '/me/',
);

=pod

=head1 NAME

WebService::Freesound - Perl wrapper around Freesound OAuth2 API!

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    #!/usr/bin/perl
    use WebService::Freesound;
    
    my %args = (
       client_id     => '03bbed9a541baf763526',
       client_secret => 'abcde1234598765fedcba78629091899aef32101',
       session_file  => '/var/www/myapp/freesoundrc',
    );

    my $freesound = WebService::Freesound->new (%args);

    # Freesound 3-Step OAuth process:
    #
    # Step 1.
    # Get authorisation URL
    #
    my $authorization_url = $freesound->get_authorization_url();

    # Step 2.
    # Redirect the user to authorization url, or paste into browser.
    # Or pop up an <iframe> with this URL as src.
    #
    use CGI;
    my $q = new CGI;
    $q->redirect($authorization_url);

    # OR in Toolkit::Template : Will put the Freesound.org's authentication
    # window on your site, with Approve or Deny buttons.
    #
    <iframe src=[% authorization_url %]>No iframe support</iframe>

    # Step 3.
    # A 'code' will be made available from the authorization_url from Freesound.
    # Use it here to get access_token, refresh_token and expiry times. These are
    # stored internally to the object and on disk. In theory, you should not need
    # to see them, but are accessible via their respective accessors.
    #
    my $rc = $freesound->get_new_oauth_tokens ($code));
    if ($rc) {
       print $freesound->error;
    }

    # At any time you can call check_authority to see if you are still authorised,
    # and this will return 1 or undef/$freesound->error.  It will refresh the tokens
    # if refresh_if_expired is set.
    #
    my $rc = $freesound->check_authority (refresh_if_expired => 1/undef);
    if ($rc) {
       print $freesound->error;
    }

    # All done with OAuth2 now it ..should.. just work forever (or until you revoke
    # the authorization at L<https://www.freesound.org/home/app_permissions/>, when
    # logged in, or set refresh_if_expired to undef).
    #
    # Get Freesound data, see L<https://www.freesound.org/docs/api/resources_apiv2.html>
    # Returns a L<HTTP::Response> or undef and $freesound->error.
    #
    my $rc = $freesound->check_authority (refresh_if_expired => 1);
    if ($rc) {
       my $response = $freesound->query ("query..." or "filter..." etc) # no query question mark required.
    }

    # Download the sample from a Freesound id into the specified directory with a
    # progress update in counter_file - for web apps get javascript to fire an Ajax call
    # to read this file until 100% complete.  Returns the path to the sample or undef
    # and $freesound->error.
    #
    my $rc = $freesound->check_authority (refresh_if_expired => 1);
    if ($rc) {
       my $file = $freesound->download ($id, '/var/www/myapp/downloads/', $counter_file);
    }

=head1 DESCRIPTION

This module provides a Perl wrapper around the L<https://Freesound.org> RESTful API.

Freesound is a collaborative database of Creative Commons Licensed sounds. It allows
you to browse, download and share sounds.  This Perl wrapper at present allows you
'read-only' access to Freesound, ie browse and download.  Upcoming versions could provide
upload, describe and edit your own sounds (though I expect it might just be easier to use
their website for this).

The complete Freesound API is documented at L<https://www.freesound.org/docs/api/index.html>

In order to use this Perl module you will need get an account at Freesound
(L<https://www.freesound.org/home/register/>) and then to register your application with them
at L<https://www.freesound.org/apiv2/apply>. Your application will then be given a client ID and
a client secret which you will need to use to get OAuth2 authorisation.

The OAuth2 Dance is described at Freesound, L<https://www.freesound.org/docs/api/authentication.html>
and officially at L<RFC6749|http://tools.ietf.org/html/rfc6749>.  It is a three step process as 
suggested above.

This module should look after the authorisation once done, ie when the expiry time arrives
it can automatically refresh the tokens.  The auth tokens are therefore kept as a file specified by
"I<session_file>", which should be read-only by you/www-data only.

When downloading a sound sample from Freesound a progress meter is available in "I<counter_file>"
which is useful in web contexts as a progress bar.  Format of the file is :

<bytes-written>:<byes-total>:<percentage>
# for example "10943051:12578220:87", ie 87% of 12578220 bytes written.

This is optional.

Also the download will download the sample file as its name and type suffix (some Freesound names have 
suffixes, some don't), so something like "/var/www/myapp/downloads/Pretty tune on piano.wav", 
".../violin tremolo G5.aif" etc.

The query method allows you to put any text string into its parameter so that you have the full
capabilities of Freesound search, filter, sort etc, as described here :
L<https://www.freesound.org/docs/api/resources_apiv2.html>

If used as part of a web app, then the process could be : 

=over 4

=item * Check for I<session_file>. If none then put up an iframe with the src set to output
of C<$freesound->get_authorization_url();>

=item * User clicks Authorise with a callback run (set in Freesound API credentials :
L<https://www.freesound.org/apiv2/apply> (ie https://localhost/cgi-bin/mayapp/do_auth.cgi)
which calls C<$freesound->get_oauth_tokens ($code))> - the code will be a parameter in
the CGI (ie C<$q->param ('code')>).  

=item * Text search box on main webpage can then be used as inputs to C<$freesound->query> -
the output formatted into HTML (from XML or json) as you
wish.  With Freesound you get a picture of the waveform and a low quality sound preview so you can engineer
your website to show the waveform and have start/stop/pause buttons.  Best not to replicate the entire
Freesound website, as this might contravene their terms and conditions.

=item * A Freesound sample will have an id. This can be used in C<$freesound->download ($id, $dir, $counter_file)>.  

=item * Show download progress bar by continually polling the contents
of I<counter_file> (with an Ajax call) and drawing a CSS bar.  Actually downloads to your server, not the
web-browser users Downloads directory.

=back

=head2 METHODS

=over 4

=item new ( I<client_id>, I<client_secret> and I<session_file> )

Creates a new Freesound object for authorisation, queries and downloads.
I<client_id>, I<client_secret> and I<session_file> are required.

=cut

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;

    $self->{client_id} = $args{client_id}
        || croak('client_id is required');
    $self->{client_secret} = $args{client_secret}
        || croak('client_secret is required');
    $self->{session_file} = $args{session_file}
        || croak('session_file is required');

    # State.
    #
    $self->{ua}            = LWP::UserAgent->new();
    $self->{error}         = "";
    $self->{access_token}  = "";
    $self->{refresh_token} = "";
    $self->{expires_in}    = "";

    return $self;
}

=item client_id

Accessor for the Client ID that was provided when you registered your
application with Freesound.org.

=cut

sub client_id {
    my ( $self, $client_id ) = @_;

    if ( defined $client_id ) {
        $self->{client_id} = $client_id;
    }

    return $self->{client_id};
}

=item client_secret

Accessor for the client secret that was provided when you registered your
application with Freesound.org.

=cut

sub client_secret {
    my ( $self, $client_secret ) = @_;

    if ( defined $client_secret ) {
        $self->{client_secret} = $client_secret;
    }

    return $self->{client_secret};
}

=item session_file

Accessor for the session file that stores the authorisation codes.

=cut

sub session_file {
    my ( $self, $session_file ) = @_;

    if ( defined $session_file ) {
        $self->{session_file} = $session_file;
    }

    return $self->{session_file};
}

=item ua

Accessor for the User Agent.

=cut

sub ua {
    my ( $self, $ua ) = @_;

    if ( defined $ua ) {
        $self->{ua} = $ua;
    }

    return $self->{ua};
}

=item error

Accessor for the error messages that may occur.

=cut

sub error {
    my ( $self, $error ) = @_;

    if ( defined $error ) {
        $self->{error} = $error;
    }

    return $self->{error};
}

=item access_token

Accessor for the OAuth2 access_token.

=cut

sub access_token {
    my ( $self, $access_token ) = @_;

    if ( defined $access_token ) {
        $self->{access_token} = $access_token;
    }

    return $self->{access_token};
}

=item refresh_token

Accessor for the OAuth2 refresh_token.

=cut

sub refresh_token {
    my ( $self, $refresh_token ) = @_;

    if ( defined $refresh_token ) {
        $self->{refresh_token} = $refresh_token;
    }

    return $self->{refresh_token};
}

=item expires_in

Accessor for the OAuth2 expiry time.

=cut

sub expires_in {
    my ( $self, $expires_in ) = @_;

    if ( defined $expires_in ) {
        $self->{expires_in} = $expires_in;
    }

    return $self->{expires_in};
}

=item get_authorization_url

This returns the URL to start with when no auth is offered or accepted. Use it in an
iframe if using this in a CGI environment (ie send to L<Template::Toolkit>).

=cut

sub get_authorization_url {
    my $self = shift;
    my $auth_url
        = $urls{'base'}
        . $urls{'code'}
        . '?client_id='
        . $self->client_id
        . '&response_type=code'
        . '&state=xyz';
    return $auth_url;
}

=item get_new_oauth_tokens ( I<code> )

Takes the resultant 'code' displayed when the user authorises this app on Freesound.org and 
then sets the internal OAuth tokens, along with expiry time.  This method seriailises
this in the session_file for later use.  This is Step 3 in the process as described in
L<https://www.freesound.org/docs/api/authentication.html>.
Returns 1 if succesful, undef and $freesound->error if not.

=cut

sub get_new_oauth_tokens {

    my $self = shift;
    my $code = shift || croak "Need the code from Freesound authorisation";
    my $rc   = 1;
    $self->error("");

    my $url  = $urls{'base'} . $urls{'access_token'};
    my %form = (
        client_id     => $self->client_id,
        client_secret => $self->client_secret,
        grant_type    => 'authorization_code',
        code          => $code,
    );
    $rc = $self->_post_request( $url, \%form );

    return $rc;
}

=item check_authority

Checks the session file exists, has a current token.  If no session file, then
returns URI to get the initial code from. If session file exists and and has not
expired then it checks with Freesound.org for existing authority.  If the tokens
need refreshing and refresh_if_expired is set, it attempts a refresh.  If that's
successful, then updates the session file with new oauth tokens.  Return error if
the refresh didn't work (or refreshable but not asked to) - maybe because the
authority has been revoked.  See L<https://www.freesound.org/home/app_permissions/>
when logged into Freesound.org.  Return error if there is no authorisation at 
Freesound.org.

=cut

sub check_authority {

    my $self = shift;
    my %args = (
        refresh_if_expired => undef,
        @_
    );
    $self->error("");
    my $rc = 1;

    # Check file exists.
    #
    if ( -s $self->session_file ) {

        # Read the session file and get its json auth tokens.
        #
        open my $fh, '<', $self->session_file
            or croak
            "Cannot read provided session_file for reading, though it does exist : $!";
        my $oauth_tokens_string = "";
        while ( my $line = <$fh> ) {
            $oauth_tokens_string .= $line;
        }
        close $fh;

        my $oauth_tokens;
        eval { $oauth_tokens = decode_json($oauth_tokens_string); };

        if ($oauth_tokens) {

            # Load them into the object for use when getting
            # anything from Freesound. Encapsulate.
            #
            foreach ( keys %$oauth_tokens ) {
                $self->{$_} = $oauth_tokens->{$_};
            }

            # Check expiry by file timestamp, expires_in and now.
            #
            my $timestamp = ( stat( $self->session_file ) )[9];
            my $expired;
            $expired++
                if ( ( $timestamp + $oauth_tokens->{'expires_in'} ) < time );

            if ( defined $args{'refresh_if_expired'} && $expired ) {

                # Expired, refresh tokens.
                #
                my $url  = $urls{'base'} . $urls{'access_token'};
                my %form = (
                    client_id     => $self->client_id,
                    client_secret => $self->client_secret,
                    grant_type    => 'refresh_token',
                    refresh_token => $oauth_tokens->{'refresh_token'},
                );

                # $freesound->error will be filled in if an error.
                #
                unless ( $self->_post_request( $url, \%form ) ) {
                    $rc = undef;
                }

            }
            elsif ($expired) {
                $rc = undef;
                $self->error("Authority has expired");
            }
        }
        else {
            $self->error(
                "OAuth tokens from the specified session_file appears to be not JSON"
            );
            $rc = undef;
        }
    }
    else {

        # No session file,
        #
        $self->error( 'Need to re-authorise with Freesound, '
                . 'use get_authorization_url then get_oauth_tokens '
                . 'with the returned code from Freesound' );
        $rc = undef;
    }

    # Finally, if we're all ok our end, check with Freesound.org.
    #
    if ($rc) {
        my $url         = $urls{'base'} . $urls{'me'};
        my $auth_String = "Bearer " . $self->access_token;
        $self->ua->default_header( 'Authorization' => "$auth_String" );
        my $response = $self->ua->get($url);
        unless ( $response->is_success ) {
            $rc = undef;
            $self->error(
                "Not authorised with Freesound : " . $response->status_line );
        }

    }
    return $rc;
}

=item query ( I<query-string> )

Does the querying of the Freesound database, see 
L<https://www.freesound.org/docs/api/resources_apiv2.html>
Should just let any string go into the query like filter, tag, sort, geotag etc.  Just a string. 
Returns whatever Freesound returns in an L<HTTP::Response>.

=cut

sub query {

    my $self = shift;
    my $query = shift || croak "Need a Freesound query string";
    $self->error("");

    my $auth_String = "Bearer " . $self->access_token;
    $self->ua->default_header( 'Authorization' => "$auth_String" );
    my $url      = $urls{'base'} . $urls{'search'} . $query;
    my $response = $self->ua->get($url);
    $self->error( $response->status_line ) unless $response->is_success;
    return $response;
}

=item download ( I<sample-id>, I<download-directory>, {I<counter-file>} )

The I<sample-id> is unique to a sample on Freesound, use C<$freesound->query>. The I<download-directory>
is where the downloaded file should go, the actual sound file will be named after its name on Freesound
and will have the correct extension (wav, mp3, aif etc).  The I<counter_file> is optional - it keeps
a running count of the download progress .  In a web environment a Javascript Ajax call can read
this in real-time to give a progress bar.  I<counter_file> probably needs to be named with a session id
of some sort. Returns the path of the file or undef (then see C<$freesound->error>).

=cut

sub download {
    my $self = shift;
    my $id   = shift || croak "download needs a Freesound id";
    my $to   = shift || croak "download needs a destination directory id";
    my $counter_file = shift;
    my $rc           = 1;
    $self->error("");

    # Download needs OAuth.
    #
    $self->ua->default_header(
        'Authorization' => 'Bearer ' . $self->access_token );

    # Download url has an ID in the midle of it.
    #
    my $url = $urls{'base'} . $urls{'download'};
    $url =~ s/_ID_/$id/;

    # Get the name of the sample (ie BASS01.wav) from Freesound.org.
    #
    my $filename
        = $self->get_filename_from_id($id);    # error to $freesound->error

    my $fqp;
    if ($filename) {

        open my $download_fh, '>', "$to/$filename"
            or croak "Cannot open $filename for writing : $!";

        # Use a callback sub to keep count of the number of bytes
        # written to the sample file, in a counter file.
        #
        my $received_size = 0;
        my $response      = $self->ua->get(
            $url,
            ':read_size_hint' => 8192,
            ':content_cb'     => sub {

                # This is handily provided by User::Agent in the callback.
                #
                my ( $data, $response, $protocol ) = @_;

                # Write this chunk of data to the download file.
                #
                print $download_fh $data;

                # Ony actually update download progress if requested.
                #
                if ( defined $counter_file ) {

                    # Calculate progress.
                    #
                    my $total_size = $response->header('Content-Length');
                    $received_size += length $data;
                    my $percentage_complete = sprintf( "%d",
                        ( $received_size / $total_size ) * 100 );

                    # Progress bar info : "10943051:12578220:87",
                    # ie 87% of 12578220 bytes written.
                    #
                    open my $counter_fh, '>', $counter_file
                        or croak "Cannot open $counter_file for writing : $!";
                    print $counter_fh
                        "$received_size:$total_size:$percentage_complete";
                    close $counter_fh;
                }
            }
        );
        close $download_fh;
        $fqp = $to . '/' . $filename;
    }
    return $fqp;
}

=item get_filename_from_id ( I<id> )

Does a query to get two fields - name and type (wav, mp3, aif etc) from the Freesound I<id> of the sample.
Returns undef and $freesound->error if can't find a name/type for this id.

=cut

sub get_filename_from_id {

    my $self = shift;
    my $id   = shift;
    $self->error("");

    # Query Freesound for the filename from its id, return name and type
    # in json.
    #
    my $response = $self->query("filter=id:$id&fields=name,type&format=json");

    my $filename;
    my $type;
    if ( $response->is_success ) {

        my $details;
        eval { $details = decode_json( $response->decoded_content ); };

        # {
        #   'count' => 1,
        #   'results' => [
        #                  {
        #                    'type' => 'wav',
        #                    'name' => 'bass 16b.wav'
        #                  }
        #                ],
        #   'previous' => undef,
        #   'next' => undef
        # };
        if (   defined $details
            && defined $details->{'results'}->[0]->{'name'}
            && defined $details->{'results'}->[0]->{'type'} )
        {

            my $name = $details->{'results'}->[0]->{'name'};
            my $type = $details->{'results'}->[0]->{'type'};

            # Could be "bass 16b.mp3.wav" if user hasn't named it
            # properly.
            #
            $filename = "$name.$type";

            # Override if extension is actually correct.
            #
            $filename = $name if $name =~ /\.$type\s*$/;

        }
        else {
            $self->error("Cannot find a name or type for Freesound id $id");
        }

    }
    else {
        $self->error( $response->status_line );
    }
    return $filename;
}

=back

=head1 INTERNAL SUBROUTINES/METHODS

Please don't use these as they may change on a whim.

=over 4

=item _post_request

Updates the objects oauth tokens and session file from User Agent response. Returns
1 or undef and $freesound->error.

=cut

sub _post_request {

    my $self      = shift;
    my $url       = shift;
    my $post_args = shift;
    my $rc        = 1;
    $self->error("");

    my $response = $self->ua->post( $url, $post_args );

    if ( $response->is_success ) {

        my $oauth_tokens_string = $response->decoded_content;

        # Extract the data into the object and save it too.
        #
        #   "access_token", "token_type", "Bearer", "expires_in",
        #   "refresh_token", "scope"
        #
        my $oauth_tokens;
        eval { $oauth_tokens = decode_json($oauth_tokens_string) };

        # todo - need to use JSON properly.

        if ($oauth_tokens) {

            # Save to session_file.
            #
            open my $counter_fh, '>', $self->session_file
                or croak "Cannot open provided session_file for writing : $!";
            print $counter_fh $oauth_tokens_string;
            close $counter_fh;

            # Encapsulate.
            #
            foreach ( keys %$oauth_tokens ) {
                $self->{$_} = $oauth_tokens->{$_};
            }

        }
        else {
            $self->error("Response from user agent appears not to be JSON");
            $rc = undef;
        }

    }
    else {
        $self->error( $response->status_line );
        $rc = undef;
    }
    return $rc;

}

=back

=head1 AUTHOR

Andy Cragg, C<< <andyc at caesuramedia.org> >>

=head1 BUGS

This is beta code and may contain bugs - please feel free to fix them and send patches.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Freesound

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Freesound>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Freesound>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Freesound>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Freesound/>

=back

=head1 ACKNOWLEDGEMENTS

I had a look at L<WebService::Soundlcoud> by Mohan Prasad Gutta, L<http://search.cpan.org/~mpgutta/> for some ideas.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Andy Cragg.

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

1;    # End of WebService::Freesound


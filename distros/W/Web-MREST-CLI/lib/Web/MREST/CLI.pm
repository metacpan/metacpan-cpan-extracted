# ************************************************************************* 
# Copyright (c) 2014-2015, SUSE LLC
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ************************************************************************* 

# ------------------------
# Model module
# ------------------------

package Web::MREST::CLI;

use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL $log $site $meta );
use App::CELL::Test qw( _touch );
use Carp qw( confess );
use Data::Dumper;
use Encode;
use Exporter qw( import );  # Exporter was first released with perl 5
use File::HomeDir;    # File::HomeDir was not in CORE (or so I think)
use File::Spec;       # File::Spec was first released with perl 5.00405
use HTTP::Request::Common qw( GET PUT POST DELETE );
use JSON;
use Log::Any::Adapter;
use LWP::UserAgent;
use LWP::Protocol::https;
#print "LWP::UserAgent: ".LWP::UserAgent->VERSION,"\n";
#print "LWP::Protocol::https: ".LWP::Protocol::https->VERSION,"\n";
use Params::Validate qw( :all );
use URI::Escape;




=head1 NAME

Web::MREST::CLI - CLI components for Web::MEST-based applications




=head1 VERSION

Version 0.283

=cut

our $VERSION = '0.283';




=head1 DESCRIPTION

Top-level module of the L<Web::MREST::CLI> distribution. Exports some
"generalized" functions that are used internally and might also be useful for
writing CLI clients in general.

=cut



=head1 EXPORTS

=cut

our @EXPORT_OK = qw( init_cli_client normalize_filespec send_req );




=head1 PACKAGE VARIABLES

=cut

# user agent
my $ua = LWP::UserAgent->new( 
    ssl_opts => { 
        verify_hostname => 1, 
    }
);

# dispatch table with references to HTTP::Request::Common functions
my %methods = ( 
    GET => \&GET,
    PUT => \&PUT,
    POST => \&POST,
    DELETE => \&DELETE,
);

my %sh;
our $JSON = JSON->new->allow_nonref->convert_blessed->utf8->pretty;




=head1 FUNCTIONS


=head2 init_cli_client

Takes PARAMHASH containing possible parameters C<distro>, C<sitedir>,
and C<debug_mode>. Initializes CLI client and returns a status object.

The C<distro> string should use hyphens instead of double-colons, i.e.
C<Foo-Bar> instead of C<Foo::Bar>.

=cut

sub init_cli_client {
    my ( %ARGS ) = validate( @_, {
        distro => { type => SCALAR },
        sitedir => { type => ARRAYREF|SCALAR|UNDEF, optional => 1 },
        early_debug => { type => SCALAR|UNDEF, optional => 1 },
    } );

    my $tf = $ARGS{'early_debug'};
    if ( $tf ) {
        _touch $tf;
        if ( -r $tf and -w $tf ) {
            unlink $tf;
            Log::Any::Adapter->set( 'File', $tf );
            $log->debug( __PACKAGE__ . "::init_cli_client activating early debug logging to $tf" );
        } else {
            print "Given unreadable/unwritable early debugging filespec $tf\n";
        }
    }

    my @targets;
    if ( defined( $ARGS{'sitedir'} ) ) {
        if ( ref( $ARGS{'sitedir'} ) eq 'ARRAY' ) {
            @targets = @{ $ARGS{'sitedir'} };
        }
        if ( ref( $ARGS{'sitedir'} ) eq '' ) {
            @targets = ( $ARGS{'sitedir'} );
        }
    }
    my $target = File::ShareDir::dist_dir( $ARGS{'distro'} );
    my $status = $CELL->load( verbose => 1, sitedir => $target );
    die $status->text unless $status->ok;
    foreach my $target ( @targets ) {
        print "Loading configuration files from $target\n";
        $status = $CELL->load( verbose => 1, sitedir => $target );
        print "WARNING: " . $status->text . "\n" unless $status->ok;
    }

    # initialize the LWP::UserAgent object
    init_ua();

    return $CELL->status_ok( 'MREST_CLI_INIT_OK' ); 
}


=head2 normalize_filespec

Given a filename (path) which might be relative or absolute, return an absolute
version. If the path was relative, it will be anchored to the home directory of
the user we are running as.

=cut

sub normalize_filespec {
    my $fs = shift;
    confess "normalize_filespec(): missing argument!" unless $fs;
    my $is_absolute = File::Spec->file_name_is_absolute( $fs );
    if ( $is_absolute ) {
        return $fs;
    }
    return File::Spec->catfile( File::HomeDir->my_home, $fs );
}


=head2 init_ua

Initialize the LWP::UserAgent singleton object.

=cut

sub init_ua {
    my $cookie_jar = $site->MREST_CLI_COOKIE_JAR;
    if ( $cookie_jar ) {
        $cookie_jar = normalize_filespec( $cookie_jar );
        print( "Cookie jar: $cookie_jar\n" );
    } else {
        die "UFGaRAL! MREST_CLI_COOKIE_JAR site param undefined!";
    }
    $ua->cookie_jar( { file => $cookie_jar } );
    return;
}


=head2 cookie_jar

Return the cookie_jar associated with our user agent.

=cut

sub cookie_jar { $ua->cookie_jar };


=head2 send_req

Send a request to the server, get the response, convert it from JSON, and
return it to caller. Die on unexpected errors.

=cut

sub send_req {
    no strict 'refs';
    # process arguments
    my ( $method, $path, $body_data ) = validate_pos( @_,
        { type => SCALAR },
        { type => SCALAR },
        { type => SCALAR|UNDEF, optional => 1 },
    );
    $log->debug( "Entering " . __PACKAGE__ . "::send_req with $method $path" );
    if ( ! defined( $body_data ) ) {
        # HTTP::Message 6.10 complains if request content is undefined
        $log->debug( "No request content given; setting to empty string" );
        $body_data = '';
    }

    # initialize suppressed headers hash %sh
    map { 
        $log->debug( "Suppressing header $_" );
        $sh{ lc $_ } = ''; 
    } @{ $site->MREST_CLI_SUPPRESSED_HEADERS } unless %sh;

    $path = "/$path" unless $path =~ m/^\//;
    $log->debug("send_req: path is $path");

    # convert body data to UTF-8
    my $encoded_body_data = encode( "UTF-8", $body_data );

    # assemble request
    my $url = $meta->MREST_CLI_URI_BASE || 'http://localhost:5000';
    $url .= uri_escape( $path, '%' );
    $log->debug( "Encoded URI is $url" );
    my $r = $methods{$method}->( 
        $url,
        Accept => 'application/json',
        Content_Type => 'application/json',
        Content => $body_data,
    );

    # add basic auth
    my $user = $meta->CURRENT_EMPLOYEE_NICK || 'demo';
    my $password = $meta->CURRENT_EMPLOYEE_PASSWORD || 'demo';
    $log->debug( "send_req: basic auth user $user / pass $password" );
    $r->authorization_basic( $user, $password );

    # send request, get response
    my $response = $ua->request( $r );
    $log->debug( "Response is " . Dumper( $response ) );
    my $code = $response->code;

    # process response entity
    my $status;
    my $content = $response->content;
    #$log->debug( "Response entity is " . Dumper( $content ) );
    if ( $content ) {
        #my $unicode_content = decode( "UTF-8", $content );

        # if the content is a bare string, enclose it in double quotes
        if ( $content =~ m/^[^\{].*[^\}]$/s ) {
            $content =~ s/\n//g;
            $log->debug( "Adding double quotes to bare JSON string" );
            $content = '"' . $content . '"';
        }

        my $perl_scalar = $JSON->decode( $content );

        if ( ref( $perl_scalar ) ) {
            # if it's a hash, we have faith that it will bless into a status object
            $status = bless $perl_scalar, 'App::CELL::Status';
        } elsif ( $perl_scalar eq 'Unauthorized' ) { 
            $status = $CELL->status_err( 
                'MREST_CLI_UNAUTHORIZED', 
                payload => $response->code . ' ' . $response->message
            );
            $log->error("Unauthorized");
        } else {
            $status = $CELL->status_err( 'MREST_OTHER_ERROR_REPORT_THIS_AS_A_BUG', payload => $perl_scalar );
            $log->error("Unexpected HTTP response ->$perl_scalar<-" );
        }
    } else {
        $status = $CELL->status_warn( 'MREST_CLI_HTTP_REQUEST_OK_NODATA' );
    }
    $status->{'http_status'} = $response->code . ' ' . $response->message;

    # load up headers
    $status->{'headers'} = {};
    $response->headers->scan( sub {
        my ( $h, $v ) = @_;
        $status->{'headers'}->{$h} = $v unless exists $sh{ lc $h };
    } );
    return $status;
}

1;

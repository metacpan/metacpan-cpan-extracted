package WebService::FileCloud;

use strict;
use warnings;

use JSON;
use LWP::UserAgent;
use HTTP::Request::Common qw( $DYNAMIC_FILE_UPLOAD );

our $VERSION = '0.3';

use constant BASE_URI => 'http://api.filecloud.io/';
use constant FETCH_APIKEY_URI => 'https://secure.filecloud.io/api-fetch_apikey.api';
use constant FETCH_ACCOUNT_DETAILS_URI => BASE_URI . 'api-fetch_account_details.api';
use constant PING_URI => BASE_URI . 'api-ping.api';
use constant FETCH_UPLOAD_URL_URI => BASE_URI . 'api-fetch_upload_url.api';
use constant CHECK_FILE_URI => BASE_URI . 'api-check_file.api';
use constant FETCH_FILE_DETAILS_URI => BASE_URI . 'api-fetch_file_details.api';
use constant FETCH_DOWNLOAD_URL_URI => BASE_URI . 'api-fetch_download_url.api';
use constant FETCH_TAG_DETAILS_URI => BASE_URI . 'api-fetch_tag_details.api';

sub new {

    my $caller = shift;

    my $class = ref( $caller );
    $class = $caller if ( !$class );

    my $self = {'akey' => undef,
		'username' => undef,
		'password' => undef,
		'timeout' => undef,
		'error' => '',
		@_};

    $self->{'ua'} = LWP::UserAgent->new( timeout => $self->{'timeout'} );
    $self->{'json'} = JSON->new();

    bless( $self, $class );

    return $self;
}

sub fetch_apikey {

    my ( $self, %args ) = @_;

    my $username = $self->{'username'};
    my $password = $self->{'password'};

    # make sure they provided username and password arguments
    if ( !defined( $username ) ||
	 !defined( $password ) ) {
	
        $self->{'error'} = "username and password arguments must be provided in constructor";
        return;
    }
    
    my $response = $self->{'ua'}->post( FETCH_APIKEY_URI,
                                        {'username' => $username,
					 'password' => $password} );

    # detect request error
    if ( !$response->is_success() ) {

        $self->{'error'} = $response->status_line();
        return;
    }

    return $self->{'json'}->decode( $response->decoded_content() );
}

sub fetch_account_details {

    my ( $self, %args ) = @_;

    # make sure they provided an akey in the constuctor
    if ( !defined( $self->{'akey'} ) ) {

	$self->{'error'} = "akey must be provided in constructor";
	return;
    }

    my $response = $self->{'ua'}->post( FETCH_ACCOUNT_DETAILS_URI,
                                        {'akey' => $self->{'akey'}} );

    # detect request error
    if ( !$response->is_success() ) {

        $self->{'error'} = $response->status_line();
        return;
    }

    return $self->{'json'}->decode( $response->decoded_content() );
}

sub ping {

    my ( $self ) = @_;

    my $response = $self->{'ua'}->post( PING_URI );

    # detect request error
    if ( !$response->is_success() ) {

	$self->{'error'} = $response->status_line();
	return;
    }

    return $self->{'json'}->decode( $response->decoded_content() );
}

sub fetch_upload_url {

    my ( $self ) = @_;

    my $response = $self->{'ua'}->post( FETCH_UPLOAD_URL_URI );

    # detect request error
    if ( !$response->is_success() ) {

        $self->{'error'} = $response->status_line();
        return;
    }

    return $self->{'json'}->decode( $response->decoded_content() );
}

sub check_file {

    my ( $self, %args ) = @_;
    
    my $ukey = $args{'ukey'};

    # make sure they provided the ukey argument
    if ( !defined( $ukey ) ) {

	$self->{'error'} = "ukey argument required";
	return;
    }

    my $response = $self->{'ua'}->post( CHECK_FILE_URI,
					{'ukey' => $ukey} );

    # detect request error
    if ( !$response->is_success() ) {

        $self->{'error'} = $response->status_line();
        return;
    }

    return $self->{'json'}->decode( $response->decoded_content() );
}

sub fetch_file_details {

    my ( $self, %args ) = @_;

    my $ukey = $args{'ukey'};

    # make sure they provided an akey in the constuctor
    if ( !defined( $self->{'akey'} ) ) {

	$self->{'error'} = "akey must be provided in constructor";
	return;
    }

    # make sure they provided the ukey argument
    if ( !defined( $ukey ) ) {

        $self->{'error'} = "ukey argument required";
        return;
    }

    my $response = $self->{'ua'}->post( FETCH_FILE_DETAILS_URI,
                                        {'akey' => $self->{'akey'},
					 'ukey' => $ukey} );

    # detect request error
    if ( !$response->is_success() ) {

        $self->{'error'} = $response->status_line();
        return;
    }

    return $self->{'json'}->decode( $response->decoded_content() );
}

sub fetch_download_url {

    my ( $self, %args ) = @_;

    my $ukey = $args{'ukey'};

    # make sure they provided an akey in the constuctor
    if ( !defined( $self->{'akey'} ) ) {

	$self->{'error'} = "akey must be provided in constructor";
	return;
    }

    # make sure they provided the ukey argument
    if ( !defined( $ukey ) ) {

	$self->{'error'} = "ukey argument required";
	return;
    }

    my $response = $self->{'ua'}->post( FETCH_DOWNLOAD_URL_URI,
                                        {'akey' => $self->{'akey'},
                                         'ukey' => $ukey} );

    # detect request error
    if ( !$response->is_success() ) {

        $self->{'error'} = $response->status_line();
        return;
    }

    return $self->{'json'}->decode( $response->decoded_content() );
}

sub upload_file {

    my ( $self, %args ) = @_;

    my $filename = $args{'filename'};
    my $url = $args{'url'};

    # make sure they provided the filename & url arguments
    if ( !defined( $filename ) ||
	 !defined( $url ) ) {

        $self->{'error'} = "filename and url arguments required";
        return;
    }

    # make sure the filename exist
    if ( ! -e $filename ) {

	$self->{'error'} = "file $filename does not exist";
	return;
    }

    # avoid reading entire file into memory when uploading
    local $HTTP::Request::Common::DYNAMIC_FILE_UPLOAD = 1;

    my $response = $self->{'ua'}->post( $url,
					Content_Type => 'form-data',
					Content => ['Filedata' => [$filename],
						    'akey' => $self->{'akey'}] );
					
    # detect request error
    if ( !$response->is_success() ) {

        $self->{'error'} = $response->status_line();
        return;
    }

    return $self->{'json'}->decode( $response->decoded_content() );    
}

sub fetch_tag_details {

    my ( $self, %args ) = @_;

    my $tkey = $args{'tkey'};

    # make sure they provided an akey in the constuctor
    if ( !defined( $self->{'akey'} ) ) {

	$self->{'error'} = "akey must be provided in constructor";
	return;
    }

    # make sure they provided the tkey argument
    if ( !defined( $tkey ) ) {

	$self->{'error'} = "tkey argument required";
	return;
    }

    my $response = $self->{'ua'}->post( FETCH_TAG_DETAILS_URI,
                                        {'akey' => $self->{'akey'},
                                         'tkey' => $tkey} );

    # detect request error
    if ( !$response->is_success() ) {

        $self->{'error'} = $response->status_line();
        return;
    }

    return $self->{'json'}->decode( $response->decoded_content() );
}

sub error {

    my ( $self ) = @_;

    return $self->{'error'};
}

1;

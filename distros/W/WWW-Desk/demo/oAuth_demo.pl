use Dancer ':syntax';

# Import WWW::Desk::Auth::oAuth Client
use WWW::Desk::Auth::oAuth;
use Data::Dumper;

# Set logger
set log      => "core";
set logger   => "console";
set warnings => 1;

# Before Request build WWW::Desk::Auth::oAuth Object
hook 'before' => sub {
    if ( !vars->{auth_client} ) {
        var auth_client => WWW::Desk::Auth::oAuth->new(
            'desk_url'     => 'https://your.desk.com',
            'callback_url' => uri_for('/auth/desk/callback'),
            'api_key'      => 'api key',
            'secret_key'   => 'secret key'
        );
    }
};

# Send user to authorize with desk.com
get '/' => sub {
    redirect vars->{auth_client}->authorization_url;
};

# User has returned with token and verifier appended to the URL.
get '/auth/desk/callback' => sub {

    # Use the auth token and verifier to fetch the access token
    my $access_token =
      vars->{auth_client}
      ->request_access_token( params->{oauth_token}, params->{oauth_verifier} );

    # Use the access token to fetch a protected resource
    my $response =
      $access_token->get( vars->{auth_client}->build_api_url('/customers') );

    # Do something with said resource...
    if ( $response->is_success ) {
        return $response->decoded_content;
    }
    else {
        return "Error: " . $response->status_line;
    }
};

dance;

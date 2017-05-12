package WebService::GData::ClientLogin;
use WebService::GData 'private';
use base 'WebService::GData';
use WebService::GData::Error;
use WebService::GData::Constants;
use LWP;


our $VERSION = 0.01_06;
our $CLIENT_LOGIN_URI = WebService::GData::Constants::CLIENT_LOGIN_URL;
our $CAPTCHA_URL      = WebService::GData::Constants::CAPTCHA_URL;

WebService::GData::install_in_package(
    [qw(type password service source captcha_token captcha_answer email key)],
    sub {
        my $subname = shift;
        return sub {
            my $this = shift;
            $this->{$subname}
          }
    }
);

sub __init {
    my ( $this, %params ) = @_;

    $this->{email}    = $params{email};
    $this->{password} = $params{password};

    die new WebService::GData::Error( 'invalid_parameters',
        'Password and Email are required to log in.' )
      if ( !$params{password} || !$params{email} );

    $this->{service} = $params{service}
      || WebService::GData::Constants::YOUTUBE_SERVICE;

    $this->{type} = $params{type} || 'HOSTED_OR_GOOGLE';

    $this->{source} =
      ( defined $params{source} )
      ? $params{source}
      : __PACKAGE__ . '-' . $VERSION;

    $this->{captcha_token} = $params{captcha_token};

    $this->{captcha_answer} = $params{captcha_answer};

    #youtube related?
    $this->{key} = $params{key};

    $this->{ua} = $this->_create_ua();

    return $this->_clientLogin();
}

sub captcha_url {
    my $this = shift;
    if ( $this->{captcha_url} ) {
        return $CAPTCHA_URL . $this->{captcha_url};
    }
    return undef;
}

sub authorization_key {
    my $this = shift;
    return $this->{Auth};
}

#for developer only
sub set_authorization_headers {
    my ( $this, $subject, $req ) = @_;
    $req->header(
        'Authorization' => 'GoogleLogin auth=' . $this->authorization_key );
}

#youtube
sub set_service_headers {
    my ( $this, $subject, $req ) = @_;
    $req->header( 'X-GData-Key' => 'key=' . $this->key ) if defined $this->key;
}

#private

private _create_ua => sub {
    my $this = shift;
    my $ua   = LWP::UserAgent->new;
    $ua->agent( $this->source );
    return $ua;
};

private _post => sub {
    my ( $this, $uri, $content ) = @_;
    my $req = HTTP::Request->new( POST => $uri );
    $req->content_type('application/x-www-form-urlencoded');
    $req->content($content);
    my $res = $this->{ua}->request($req);
    if ( $res->is_success
        || ( $res->code == 403 && $res->content() =~ m/CaptchaRequired/ ) )
    {
        return $res->content();
    }
    else {
        if (   $res->code == 500
            && $res->content() =~ m/www.google.com:443 \(Invalid argument\)/ )
        {
            die new WebService::GData::Error( 'missing_ssl_module',
                'Crypt::SSLeay must be installed in order to use ssl.' );
        }
        my $error = _parse_response( 'Error', $res->content );
        die new WebService::GData::Error( $error, $res->content );
    }
};

private _parse_response => sub {
    my ( $key, $content ) = @_;
    return ( split( /$key\s*=(.+?)\s{1}/m, $content ) )[1];
};

private _clientLogin => sub {
    my $this = shift;

    my $content = 'Email=' . _urlencode( $this->email );
    $content .= '&Passwd=' . _urlencode( $this->password );
    $content .= '&service=' . $this->service;
    $content .= '&source=' . _urlencode( $this->source );
    $content .= '&accountType=' . $this->type;

    #when failed the first time, add the captcha
    $content .= '&logintoken=' . $this->captcha_token
      if ( $this->captcha_token );
    $content .= '&logincaptcha=' . $this->captcha_answer
      if ( $this->captcha_answer );

    $this->{content} = $content;

    my $ret = $this->_post( $CLIENT_LOGIN_URI, $content );

    $this->{Auth}          = _parse_response( 'Auth',         $ret );
    $this->{captcha_token} = _parse_response( 'CaptchaToken', $ret );
    $this->{captcha_url}   = _parse_response( 'CaptchaUrl',   $ret );
    return $this;

};

private _urlencode => sub {
    my ($string) = shift;
    $string =~ s/(\W)/"%" . unpack("H2", $1)/ge;
    return $string;
};

"The earth is blue like an orange.";

__END__

=pod

=head1 NAME

WebService::GData::ClientLogin - implements ClientLogin authorization for google data related APIs v2.

=head1 SYNOPSIS

    #you will want to use a service instead such as WebService::GData::YouTube;
    use WebService::GData::Base;
    use WebService::GData::ClientLogin;

    #create an object that only has read access
    my $base = new WebService::GData::Base();
    
    my $auth;

    eval {
        $auth = new WebService::GData::ClientLogin(
            email    => '...',
            password => '...',
            service  => '...', #default to youtube,
            source   => '...' #default to WebService::GData::ClientLogin-$VERSION,
            type    => '...'  #default to HOSTED_OR_GOOGLE
        );
    };
    if(my $error = $@){
        #$error->code,$error->content...
    }
    
    if($auth->captcha_url){
        #display the image and get the answer from the user
        #then try to login again
    }

    #everything is fine...
    #give write access to the above user...
    
    $base->auth($auth);

    #now you can... (url are here for examples!)

    #create a new entry with application/x-www-form-urlencoded content-type
    
    my $ret = $base->post('http://gdata.youtube.com/feeds/api/users/default/playlists',$content);

    #if it fails a first time, you will need to add captcha related parameters:
    my $auth;
    eval {
        $auth = new WebService::GData::ClientLogin(
            email          => '...',
            password       => '...',
            captcha_token  => '...',
            captcha_answer => '...'
        );
    };
        
    #youtube specific developer key 
    my $auth;
    eval {	
        $auth = new WebService::GData::ClientLogin(
             email    => '...',
             password => '...',
              key      => '...',
        );
    };


=head1 DESCRIPTION

I<inherits from L<WebService::GData>

Google services supports different authorization systems allowing you to write data programmaticly. ClientLogin is one of such system.
This package tries to get an authorization key to the service specified by logging in with the user account information: email and password.
If the loggin succeeds, the authorization key generated grants you access to write actions as long as you pass the key with each requests.

ClientLogin authorization key does expire but the expire time is set on a per service basis.
You should use this authorization system for installed applications.
Web application should use the OAuth (to be implemented) or AuthSub (will be deprecated and will not be implemented) authorization systems.

The connection is done via ssl, therefore you should install L<Crypt::SSLeay> before using this module or an error code: 'missing_ssl_module'
will be thrown.


More information about ClientLogin can be found here:

L<http://code.google.com/intl/en/apis/accounts/docs/AuthForInstalledApps.html>

Some problems can be encountered if your account is not directly linked to a Google Account.

Please see L<http://apiblog.youtube.com/2011/03/clientlogin-fail.html>.


=head2 CONSTRUCTOR


=head3 new

=over

Create an instance by passing an hash.

B<Parameters>

=over 

=item C<settings:Hash> an hash containing the following keys:(* parameters are optional)

=over

=item B<email>

Specify the user email account.  

=item B<password>

Specifies the user password account. 
    
=item B<service> (default to youtube)

Specify the service you want to log in. youtube for youtube, cl for calendar,etc. 

List available here:L<http://code.google.com/intl/en/apis/base/faq_gdata.html#clientlogin>.

Constants available in L<WebService::GData::Constants>


=item B<source> (default to WebService::GData::ClientLogin-$VERSION)

Specify the name of your application in the following format "company_name-application_name-version_id".
You should provide a real source to avoid getting blocked because Google thought you are a bot...
     
=item B<type*> (default to HOSTED_OR_GOOGLE)

Specify the type of account: GOOGLE,HOSTED or HOSTED_OR_GOOGLE.

=item B<key*>

The key must be specified for YouTube service. See C<key()> for further information about the key.

=item B<captcha_token*>

Specify the captcha_token you received in response to a failure to log in. 

=item B<captcha_answer*>

Specify the answer of the user for the CAPTCHA. 

=back

=back

B<Returns> 

=over 

=item L<WebService::GData::ClientLogin>

=back

B<Throws> 

=over 

=item L<WebService::GData::Error>

If the email or password is not set it will throw an error with invalid_parameters code.
Other errors might happen while trying to connect to the service. You should look at the error code and content.

See also L<http://code.google.com/intl/en/apis/accounts/docs/AuthForInstalledApps.html#Errors> for error code list.

You can use L<WebService::GData::Constants> to check the error code.

=back


Example:

    use WebService::GData::Base;
    use WebService::GData::ClientLogin;	
    
    my $auth = new WebService::GData::ClientLogin(
        email          => '...',
        password       => '...',
        captcha_token  => '...',
        captcha_answer => '...'
    );
    
    my $base = new WebService::GData::YouTube(auth=>$auth);

=back

=head2 CONSTRUCTOR GETTER METHODS

All these methods allows you to get access to the data you passed to the constructor
or to the data you got back from the server. 

=head3 email

=over

Get the email address set to log in.

B<Parameters>

=over

=item C<none> 

=back

B<Returns> 

=over 

=item C<email:Scalar>

=back

Example:

    use WebService::GData::ClientLogin;	
    
    my $auth = new WebService::GData::ClientLogin(
        email          => '...',
        password       => '...'
    );
    
    $auth->email;

	   
=back

=head3 password

=over

Get the password set to log in.

B<Parameters>

=over

=item C<none> 

=back

B<Returns> 

=over 

=item C<password:Scalar>

=back

Example:

    use WebService::GData::ClientLogin;	
    
    my $auth = new WebService::GData::ClientLogin(
        email          => '...',
        password       => '...'
    );
    
    $auth->password;

	   
=back

=head3 source

=over

Get the source set to log in.

B<Parameters>

=over

=item C<none> 

=back

B<Returns> 

=over 

=item C<source:Scalar>

=back

Example:

    use WebService::GData::ClientLogin;	
    
    my $auth = new WebService::GData::ClientLogin(
        email          => '...',
        password       => '...'
    );
    
    $auth->source;#by default WebService::GData::ClientLogin-$VERSION
   
=back

=head3 service

=over

Get the service set to log in.

B<Parameters>

=over

=item C<none> 

=back

B<Returns> 

=over 

=item C<service:Scalar>

=back

Example:

    use WebService::GData::ClientLogin;	
    
    my $auth = new WebService::GData::ClientLogin(
        email          => '...',
        password       => '...'
    );
    
    $auth->service;#by default youtube
   
=back

=head3 type

=over

Get the account type set to log in.

B<Parameters>

=over

=item C<none> 

=back

B<Returns> 

=over 

=item C<account_type:Scalar>

=back

Example:

    use WebService::GData::ClientLogin;	
    
    my $auth = new WebService::GData::ClientLogin(
        email          => '...',
        password       => '...'
    );
    
    $auth->service;#by default HOSTED_OR_GOOGLE
   
=back


=head3 key 

=over

The key is required by the youtube service to identify the application making the request.
You must handle this in the developer dashboard:L<http://code.google.com/apis/youtube/dashboard/>.

See also L<http://code.google.com/intl/en/apis/youtube/2.0/developers_guide_protocol.html#Developer_Key>.

B<Parameters>

=over 4

=item C<none> 

=back

B<Returns> 

=over 4

=item C<key:Scalar>

=back

Example:

    use WebService::GData::ClientLogin;	
    
    my $auth = new WebService::GData::ClientLogin(
        email          => '...',
        password       => '...',
        key            => '...'
    );
    
    $auth->key;
   
=back

=head2 CAPTCHA GETTER METHODS

The following getters are used in case of failure to connect leading in an error response from the service
requiring to proove that you are a human (or at least seem to...).
The reason for this error to arrive could be several errors to log in in a short interval of time.

=head3 captcha_token

=over

Get the captcha token sent back by the server after a failure to connect leading to a CaptchaRequired error message.


B<Parameters>

=over

=item C<none> 

=back

B<Returns> 

=over 

=item C<captcha_token:Scalar>

=back

Example:

    use WebService::GData::ClientLogin;	
    
    my $auth = new WebService::GData::ClientLogin(
        email          => '...',
        password       => '...'
    );
    
    $auth->captcha_token;#by default nothing, so if you have something, you did not succeed in logging in.
   
=back

=head3 captcha_url

=over

Get the captcha token sent back by the server after a failure to connect leading to a CaptchaRequired error message.
This url links to an image containing the challenge.

B<Parameters>

=over

=item C<none> 

=back

B<Returns> 

=over 

=item C<captcha_url:Scalar>

=back

Example:

    use WebService::GData::ClientLogin;	
    
    my $auth = new WebService::GData::ClientLogin(
        email          => '...',
        password       => '...',
    );
    
    my $url = $auth->captcha_url;#by default nothing, so if you have something, you did not succeed in logging in.
    
    #you could do:
    
    print qq[<img src="$url"/>]; #display a  message to decrypt...
   
=back

=head3 captcha_answer

=over

Get the answer from the user after he/she was presented with the captcha image (link in captcha_url).  You set this parameter in the constructor.

B<Parameters>

=over

=item C<none> 

=back

B<Returns> 

=over 

=item C<captcha_answer:Scalar>

=back

Example:

    use WebService::GData::ClientLogin;	
    
    my $auth = new WebService::GData::ClientLogin(
        email          => '...',
        password       => '...'
    );
    
    my $url = $auth->captcha_url;#by default nothing, so if you have something, you did not succeed in logging in.
    
    #you could do:
    
    print qq[<img src="$url"/>]; #display a  message to decrypt...
    print q[<input type="text" name="captcha_answer" value=""/>];#let the user enters the message displayed
   
=back

=head3 authorization_key

=over

Get the authorization key sent back by the server in case of success to log in.
This will be the key you  put in the Authorization header to each protect content that you want to request.
This is handled by each service and should be transparent to the end user of the library.

B<Parameters>

=over 4

=item C<none> 

=back

B<Returns> 

=over 4

=item C<authorization_key:Scalar>

=back

Example:

    use WebService::GData::ClientLogin;	
    
    my $auth = new WebService::GData::ClientLogin(
        email          => '...',
        password       => '...'
    );
    
    my $url = $auth->authorization_key;#by default nothing, so if you have something, you did succeed in logging in.
    
   
=back


=head1  HANDLING ERROR/CAPTCHA

Google data APIs relies on querying remote urls on particular services.
All queries that fail will throw (die) a WebService::GData::Error object. 
The error instance will contain the error code as a string in L<code()> and the full error string in C<content()>.

The CaptchaRequired code return by the service does not throw an error though as you can recover by a captcha.

Below is an example of how to implement the logic for a captcha in a web context.

(WARNING:shall not be used in a web context though but easy to grasp!)


Example:

    use WebService::GData::Constants qw(:errors);
    use WebService::GData::ClientLogin;

    my $auth;	
    eval {
        $auth   = new WebService::GData::ClientLogin(
            email => '...',#from the user
            password =>'...',#from the user
            service =>'youtube',
            source =>'MyCompany-MyApp-2'
        );
    };

    if(my $error = $@) {
        #something went wrong, display some info to the user
        #$error->code,$error->content
        if($error->code eq BAD_AUTHENTICATION){
            #display a message to the user...
        }
    }

    #else it seems ok but...

    #check to see if got back a captcha_url

    if($auth->captcha_url){
        
        #ok, so there was something wrong, we'll try again.
        
        my $img = $auth->captcha_url;
        my $key = $auth->captcha_token;
		
        #here an html form as an example
        #(WARNING:shall not be used in a web context but easy to grasp!)
        
        print q[<form action="/cgi-bin/...mycaptcha.cgi" method="POST">];
        print qq[<input type="hidden" value="$key" name="captcha_token"/>];
        print qq[<input type="text" value="" name="email"/>];
        print qq[<input type="text" value="" name="password"/>];
        print qq[<img src="$img" />];
        print qq[<input type="text" value=""  name="captcha_answer"/>];
        
        #submit button here
    }
    
    #once the form is submitted, in your mycaptcha.cgi program:
    
    my $auth;	
    eval {
        $auth   = new WebService::GData::ClientLogin(
            email => '...',#from the user
            password =>'...',#from the user
            service =>'youtube',
            source =>'MyCompany-MyApp-2',
            captcha_token => '...',#from the above form
            captcha_answer => '...'#from the user
        );
    };

    ##error checking again:lather,rinse,repeat...



=head1  DEPENDENCIES

L<LWP>

L<Crypt::SSLeay>

=head1 BUGS AND LIMITATIONS

If you do me the favor to _use_ this module and find a bug, please email me
i will try to do my best to fix it (patches welcome)!

=head1 AUTHOR

shiriru E<lt>shirirulestheworld[arobas]gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

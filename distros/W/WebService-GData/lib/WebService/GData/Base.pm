package WebService::GData::Base;
use WebService::GData 'private';
use base 'WebService::GData';

use WebService::GData::Query;
use WebService::GData::Error;
use WebService::GData::Constants qw(:all);

use JSON;
use LWP;

#the base class specifies the basic get/post/insert/update/delete methods

our $VERSION = 0.02_03;

sub __set {
    my ($this,$func,$val)=@_;
    die new WebService::GData::Error('forbidden_method_call',
        'agent() is used internally.' ) if $func eq 'agent';    

    if(my $code = $this->{__UA__}->can($func)){
    	$code->($this->{__UA__},$val);
    	return $this;
    }
    die new WebService::GData::Error('unknown_method_call',
        $func.'() is not a LWP::UserAgent Method.' );
}

sub __get {
	my ($this,$func)=@_;
    die new WebService::GData::Error('forbidden_method_call',
        'agent() is used internally.' ) if $func eq 'agent';
	my $code = $this->{__UA__}->can($func);
	return $code->($this->{__UA__}) if $code;
    die new WebService::GData::Error('unknown_method_call',
        $func.'() is not a LWP::UserAgent Method.' );
}

sub __init {
    my ( $this, %params ) = @_;

    $this->{__COMPRESSION__}= FALSE;
    $this->{__OVERRIDE__}   = FALSE;
    $this->{__AUTH__}       = undef;
    $this->{__URI__}        = undef;
    $this->{__UA__}         = LWP::UserAgent->new;
    $this->{__UA_NAME__}    = '';
    $this->query( new WebService::GData::Query() );

    $this->auth( $params{auth} )
      if ( defined $params{auth} );
}

sub auth {
    my ( $this, $auth ) = @_;

    if ( _is_auth_object_compliant($auth) ) {
        $this->{__AUTH__} = $auth;
        $this->_set_ua_name;
    }
    return $this->{__AUTH__};
}

sub query {
    my ( $this, $query ) = @_;
    $this->{_basequery} = $query
      if ( _is_query_object_compliant($query) );
    return $this->{_basequery};
}

sub override_method {
    my ( $this, $override ) = @_;

    return $this->{__OVERRIDE__} if ( !$override );

    if ( $override eq TRUE ) {
        $this->{__OVERRIDE__} = TRUE;
    }
    if ( $override eq FALSE ) {
        $this->{__OVERRIDE__} = FALSE;
    }
}

sub enable_compression {
    my ( $this, $compression ) = @_;

    return $this->{__COMPRESSION__} if ( !$compression );

    if ( $compression eq TRUE ) {
        $this->{__COMPRESSION__} = TRUE;
    }
    if ( $compression eq FALSE ) {
        $this->{__COMPRESSION__} = FALSE;
    }
    $this->_set_ua_name;
}

sub user_agent_name {
    my ($this,$name) = @_;
    return $this->{__UA__}->agent if not defined $name;
    $this->{__UA_NAME__}=$name;
    $this->_set_ua_name;
    
}

sub get_uri {
    my $this = shift;
    return $this->{__URI__};
}


sub get {
    my ( $this, $uri,$with_query_string ) = @_;

    #the url from the feeds contain the version but not the one we pass directly
    $this->query->set_from_query_string($uri) if $with_query_string;
    
    $uri = _delete_query_string($uri);

    _error_invali_uri('get') if ( !$uri || length($uri) == 0 );

    $this->{__URI__} = $uri;
    my $req = HTTP::Request->new( GET => $uri . $this->query->to_query_string );
    $req->content_type('application/atom+xml; charset=UTF-8');

    $this->_prepare_request($req);

    my $ret = $this->_request($req);
    return $this->query->get('alt') =~ m/^jsonc*$/ ? from_json($ret) : $ret;

}

sub post {
    my ( $this, $uri, $content ) = @_;

    _error_invali_uri('post') if ( !$uri || length($uri) == 0 );

    $this->{__URI__} = $uri;
    my $req = HTTP::Request->new( POST => $uri );
    $req->content_type('application/x-www-form-urlencoded');
    $this->_prepare_request( $req, length($content) );
    $req->content($content);
    return $this->_request($req);
}

sub insert {
    my ( $this, $uri, $content, $callback ) = @_;

    _error_invali_uri('insert') if ( !$uri || length($uri) == 0 );

    return $this->_save( 'POST', $uri, $content, $callback );
}

sub update {
    my ( $this, $uri, $content, $callback ) = @_;

    _error_invali_uri('update') if ( !$uri || length($uri) == 0 );

    return $this->_save( 'PUT', $uri, $content, $callback );
}

sub delete {
    my ( $this, $uri ) = @_;

    _error_invali_uri('delete') if ( !$uri || length($uri) == 0 );

    $this->{__URI__} = $uri;
    my $req;
    if ( $this->override_method eq TRUE ) {
        $req = HTTP::Request->new( POST => $uri );
        $req->header( 'X-HTTP-Method-Override' => 'DELETE' );
    }
    else {
        $req = HTTP::Request->new( DELETE => $uri );
    }
    $req->content_type('application/atom+xml; charset=UTF-8');
    $this->_prepare_request($req);

    return $this->_request($req);
}

###PRIVATE###

#methods#

private _set_ua_name => sub {
    my ( $this ) = @_;	
    my $custom = $this->{__UA_NAME__} ? $this->{__UA_NAME__}.' ' : '';
    my $name = $custom._ua_base_name();
       $name = $this->auth->source . ' ' . $name if $this->auth;
       $name.= ' (gzip)' if $this->enable_compression eq TRUE;
    $this->{__UA__}->agent($name);
};

private _request => sub {
    my ( $this, $req ) = @_;

    $this->_set_ua_name();
   
    if($this->enable_compression eq TRUE) {
    	my $compressions = HTTP::Message::decodable();
        $this->{__UA__}->default_header('Accept-Encoding' => $compressions) if $compressions=~m/gzip/;
    }

    my $res = $this->{__UA__}->request($req);

    if ( $res->is_success ) {
        return $this->enable_compression eq TRUE ? $res->decoded_content():$res->content();
    }
    else {
        die new WebService::GData::Error( $res->code, $res->content );
    }
};

private _save => sub {
    my ( $this, $method, $uri, $content, $callback ) = @_;
    $this->{__URI__} = $uri;
    my $req;
    if ( $this->override_method eq TRUE && $method =~ m/PUT|PATCH/ ) {
        $req = HTTP::Request->new( POST => $uri );
        $req->header( 'X-HTTP-Method-Override' => $method );
    }
    else {
        $req = HTTP::Request->new( "$method" => $uri );
    }
    $req->content_type('application/atom+xml; charset=UTF-8');



    $this->_prepare_request( $req, length($content) );
    $req->content($content);
    if ($callback) {
        &$callback($req);
    }

    return $this->_request($req);
};

private _prepare_request => sub {
    my ( $this, $req, $length ) = @_;
    $req->header( 'GData-Version' => $this->query->get('v') );
    $req->header( 'Content-Length' => $length ) if ($length);
    if ( $this->auth ) {
        $this->auth->set_authorization_headers( $this, $req );
        $this->auth->set_service_headers( $this, $req );
    }
};

#sub#

private _error_invali_uri => sub {
    my $method = shift;
    die new WebService::GData::Error( 'invalid_uri',
        'The uri is empty in ' . $method . '().' );
};

private _ua_base_name => sub {
    return __PACKAGE__ . "/" . $VERSION;
};


private _is_object => sub {
    my $val = shift;
    eval { $val->can('can'); };
    return undef if ($@);
    return 1;

};

#duck typing has I don't want to enfore inheritance
private _is_auth_object_compliant => sub {
    my $auth = shift;
    return 1
      if ( _is_object($auth)
        && $auth->can('set_authorization_headers')
        && $auth->can('set_service_headers')
        && $auth->can('source') );
    return undef;
};

private _is_query_object_compliant => sub {
    my $query = shift;
    return 1
      if ( _is_object($query)
        && $query->can('to_query_string')
        && $query->can('get')
        && int( $query->get('v') ) >= GDATA_MINIMUM_VERSION );
    return undef;
};

private _delete_query_string => sub {
    my $uri = shift;
    $uri =~ s/\?.*//;
    return $uri;
};

"The earth is blue like an orange.";

__END__


=pod

=head1 NAME

WebService::GData::Base - core read/write methods over HTTP for google data API v2.

=head1 SYNOPSIS

    use WebService::GData::Base;

    #read only
	
    my $base = new WebService::GData::Base();

    my $ret  = $base->get('http://gdata.youtube.com/feeds/api/standardfeeds/top_rated');
    my $feed = $ret->{feed};

    #give write access
	
    $base->auth($auth);

    #now you can
    #get hidden/private contents
	
    my $ret = $base->get('http://gdata.youtube.com/feeds/api/users/default/playlists');

    #new entry with application/x-www-form-urlencoded content-type
	
    my $ret = $base->post('http://gdata.youtube.com/feeds/api/users/default/playlists',$content);

    my $ret = $base->delete('http://gdata.youtube.com/feeds/api/users/playlist/'.$someid);

    #the content type is application/atom+xml; charset=UTF-8
	
    my $ret = $base->insert($uri,$content,$callback);

    #the content type is application/atom+xml; charset=UTF-8
	
    my $ret = $base->update($uri,$content,$callback);

    #modify the query string query string: ?alt=jsonc&v=2&prettyprint=false&strict=true
	
    $base->query->alt('jsonc')->prettyprint('false');

    #overwrite WebService::GData::Query with youtube query parameters
	
    $base->query(new WebService::GData::YouTube::Query);

    #now the query will have the following query string: 
    #?alt=json&v=2&prettyprint=false&strict=true&safeSearch=none
	
    $base->query->safe_search('none');




=head1 DESCRIPTION

I<inherits from L<WebService::GData>>

This package allows you to manipulate the data stored on Google servers. 
It grants you access to the main read/write (get,post,insert,update,delete) methods available for the google data APIs by wrapping LWP methods.
Some actions require to be authenticated (ClientLogin,OAuth,SubAuth). If an authentication object is set at construction time, 
it will be called to add any extra headers the authentication mechanism requires.
This package should be inherited by services (youtube,analytics,calendar) to offer higher level of abstraction.

Every request (get,post,insert,update,delete) will throw a L<WebService::GData::Error> in case of failure.
It is therefore recommanded to enclose your code in eval blocks to catch and handle the error as you see fit.

The google data based APIs offer different format for the core protocol: atom based, rss based,json based, jsonc based.
In order to offer good parsing performance, we use the json based response as a default to get() the feeds.
Unfortunately, if we can read the feeds in json,the write methods require atom based data.
The server also sends back an atom response too. We have therefore a hugly mixed of atom/json logic for now.


=head2 CONSTRUCTOR

=head3 new

=over

Create an instance.

B<Parameters>

=over 

=item C<auth:AuthObject> (optional) - You can set an authorization object like L<WebService::GData::ClientLogin>

=back

B<Returns> 

=over 

=item L<WebService::GData::Base>

=back


Example:

    use WebService::GData::Base;
	
    my $base   = new WebService::GData::Base(auth=>$auth);
	
=back

=head2 PROXY METHODS

Any call to a method that is not defined in this package will be dispatched to the L<LWP::UserAgent> instance.
In getter context, they send back the WebService::GData::Base instance.

Example:

    use WebService::GData::Base;

    my $base = new WebService::GData::Base();
    
    #LWP::UserAgent timeout is set to 15 
    #and will look after environment variables for proxy settings
       $base->timeout(15)->env_proxy; 
       
=back



=head2 SETTER/GETTER METHODS

=head3 auth

=over

Set/get an auth object that handles access to protected contents.
The auth object will be used by post/insert/update/delete methods by calling two methods: 

=over

=item * C<set_authorization_headers(base:WebService::GData::Base,req:HTTP::Request)> 

- Headers required by the authentication protocol.

=item * C<set_service_headers(base:WebService::GData::Base,req:HTTP::Request)> 

- Extra headers required by a particular service.

=item * C<source()> 

- The name of the application. Will be used for the user agent string.

=back

These methods will receive the instance calling them and the request instance.
They shall add any extra headers required to implement their own authentication protocol (ie,ClientLogin,OAuth,SubAuth).
If the object can not handle the above methods it will not be set.

B<Parameters>

=over

=item C<none> - use as a getter

=item C<auth:Object> - use as a setter: a auth object defining the necessary methods.

=back

B<Returns> 

=over 

=item C<auth:Object> in a setter/getter context.

=back

Example:

    use WebService::GData::Base;
	
    #should be in a eval {... }; block to catch an error...
	
    my $auth = new WebService::GData::ClientLogin(email=>...);

    my $base = new WebService::GData::Base(auth=>$auth);
	
    #or
	
    my $base   = new WebService::GData::Base();	
       $base  -> auth($auth);
	   
=back

=head3 query

=over

Set/get a query object that handles the creation of the query string. 
The query object will be used to add extra query parameters when calling L<WebService::GData::Base>::get().

The query object should only implement the following methods (do not need to inherit from L<WebService::GData::Query>):

=over 

=item * C<get('value-name')> - Gives access to a parameter value

=item * C<to_query_string()> - return the query string.

=item * C<get('v')> - should return a version number >=L<WebService::GData::Constants>::GDATA_MINIMUM_VERSION

=back

B<Parameters>

=over

=item C<none> - use as a getter

=item C<query:Object> - use as a setter: a query object defining the necessary methods.

=back

B<Returns> 

=over 

=item C<query:Object> in a setter/getter context.

=back

The L<WebService::GData::Query> returns by default:

    '?alt=json&prettyprint=false&strict=true&v=2'
	
when C<to_query_string()> is called.

When you call L<WebService::GData::Base>::get(), you should only set an url with no query string:

Example:
   
    use WebService::GData::Constants qw(:all);
    use WebService::GData::Base;
	
    #should be in a eval { ... }; block...
    my $auth   = new WebService::GData::ClientLogin(email=>...);

    my $base   = new WebService::GData::Base(auth=>$auth);

    $base->query->alt(JSONC);
    
    $base->get('http://gdata.youtube.com/feeds/api/standardfeeds/top_rated');
    #is in fact calling:
    #http://gdata.youtube.com/feeds/api/standardfeeds/top_rated?alt=jsonc&prettyprint=false&strict=true&v=2

    #or set a new query object:
    $base->query(new WebService::GData::YouTube::Query());

=back

=head3 override_method

=over

Set/get the override method. 

Depending on your server configurations, you might not be able to set the method to PUT/DELETE/PATCH. This will forbid you to do any updates or deletes.
In such a case, you should set override_method to TRUE so that it uses the POST method but override it by the proper value (ie,PUT/DELETE/PATCH) using X-HTTP-Method-Override.


B<Parameters>

=over

=item C<none> - use as a getter

=item C<true_or_false:Scalar> - use as a setter: WebService::GData::Constants::TRUE or WebService::GData::Constants::FALSE (default)

=back

B<Returns> 

=over 

=item C<void> in a setter context. 

=item C<override_state:Scalar> in a getter context, either WebService::GData::Constants::TRUE or WebService::GData::Constants::FALSE.

=back

Example:

    use WebService::GData::Constants qw(:all);
    use WebService::GData::Base;
	
	
    #using override_method makes sense only if you are logged in
    #and want to do some write methods.

    my $auth = new WebService::GData::ClientLogin(email=>...);

    my $base = new WebService::GData::Base(auth=>$auth);

    $base->override_method(TRUE);
	
    $base->update($url,$content);
	   
=back

=head3 enable_compression

=over

Set/get the compression mode. 

Depending on your perl configuration, you might be able to handle data compress using gzip.
By setting this method to TRUE, the data coming from Google servers will be gzipped and unzipped for you as a convenience.
It may offer a way to limit the number of bytes exchanged over the network but requires more calculation on your side.
By default, compression mode is not enabled.


B<Parameters>

=over

=item C<none> - use as a getter

=item C<true_or_false:Scalar> - use as a setter: WebService::GData::Constants::TRUE or WebService::GData::Constants::FALSE (default)

=back

B<Returns> 

=over 

=item C<void> in a setter context. 

=item C<compression_state:Scalar> in a getter context, either WebService::GData::Constants::TRUE or WebService::GData::Constants::FALSE.

=back

Example:

    use WebService::GData::Constants qw(:all);
    use WebService::GData::Base;
	my $base = new WebService::GData::Base();
       $base->enable_compression(TRUE);
    
    my $ret = $base->get($url);#the data was gzipped and ungzipped if possible
       
=back


=head3 get_uri

=over

Get the last queried uri. 


B<Parameters>

=over

=item C<none> - getter only

=back

B<Returns> 

=over 

=item C<uri:Scalar> in a getter context, either undef if no query has been made or the uri with no query string as a Scalar.

=back

Example:

    use WebService::GData::Base;
	
    my $base = new WebService::GData::Base();

    $base->get('http://www.example.com?v=2');
	
    $base->get_uri();#'http://www.example.com'
	   
=back


=head3 user_agent_name

=over

Set or get the user agent name set. 


B<Parameters>

=over

=item C<none> - getter 

=item C<name:Scalar> - set the user agent name 

=back

B<Returns> 

=over 

=item C<user_agent_name:Scalar> the full user agent name when used in a getter context 

=back

Example:

    use WebService::GData::Base;
	
    my $base = new WebService::GData::Base();

    $base->get('http://www.example.com?v=2');
	
    $base->user_agent_name();#WebService::GData::Base/2
	
    $base->auth($auth);#where $auth->source eq 'MyApp-MyCompany-ID'

    $base->user_agent_name();#MyApp-MyCompany-ID WebService::GData::Base/2
    
    $base->user_agent_name("my app");#MyApp-MyCompany-ID my app WebService::GData::Base/2
	   
=back

	
=head2 READ METHODS

=head3 get

=over

Get the content of a feed in any format. If the format is json or jsonc, it will send back a perl object.
If an auth object is specified, it will call the required methods to set the authentication headers.
It will also set the 'GData-Version' header by calling $this->query->get('v');
You should put the code in a eval { ... }; block to catch any error.

B<Parameters>

=over 

=item C<url:Scalar> - an url to fetch that do not contain any query string.

Query string will be removed before sending the request.

=back

B<Returns> 

=over 

=item C<response:Object|Scalar> - a perl object if it is a json or jsonc request else the raw content.

=back

B<Throws> 

=over 

=item L<WebService::GData::Error> if it fails to reach the contents.

=back

Example:

    use WebService::GData::Base;
	
    my $base   = new WebService::GData::Base();
    
    $base->get('http://gdata.youtube.com/feeds/api/standardfeeds/top_rated');
	
    #is in fact calling:
    #http://gdata.youtube.com/feeds/api/standardfeeds/top_rated?alt=json&prettyprint=false&strict=true&v=2

    #the query string will be erased and change to query->to_query_string()
	
    $base->get('http://gdata.youtube.com/feeds/api/standardfeeds/top_rated?alt=atom');
	
    #is in fact calling:
    #http://gdata.youtube.com/feeds/api/standardfeeds/top_rated?alt=json&prettyprint=false&strict=true&v=2

=back

=head2 WRITE METHODS

All the following methods will set the 'GData-Version' header by calling $this->query->get('v');
You should put the code in a eval { ... }; block to catch any error these methods may throw.

=head3 post

=over

Post data to an url with application/x-www-form-urlencoded content type.
An auth object must be specified. it will call the required methods to set the authentication headers.

B<Parameters>

=over

=item C<url:Scalar> - the url to query

=item C<content:Scalar|Binary> - the content to post

=back

B<Returns> 

=over 

=item C<response:Scalar> - the response to the query in case of success.

=back

B<Throws> 

=over 

=item L<WebService::GData::Error> if it fails to reach the contents.

=back


Example:

    use WebService::GData::Base;
	
    #you must be authorized to do any write actions.
    my $base   = new WebService::GData::Base(auth=>...);
    
    #create a new entry with application/x-www-form-urlencoded content-type
    my $ret = $base->post($url,$content);
	
=back

=head3 insert

=over

Insert data to an url with application/atom+xml; charset=UTF-8 content type (POST).
An auth object must be specified. it will call the required methods to set the authentication headers.


B<Parameters>

=over

=item C<url:Scalar> - the url to query

=item C<content:Scalar> - the content to post

=back

B<Returns> 

=over

=item C<response:Scalar> - the response to the query in case of success.

=back

B<Throws> 

=over 

=item L<WebService::GData::Error> if it fails to reach the contents.

=back

Example:

    use WebService::GData::Base;
	
    #you must be authorized to do any write actions.
    my $base   = new WebService::GData::Base(auth=>...);
    
    #create a new entry with application/atom+xml; charset=UTF-8 content-type
    my $ret = $base->insert($url,$content);

=back

=head3 update

=over

Update data to an url with application/atom+xml; charset=UTF-8 content type (PUT).
An auth object must be specified. it will call the required methods to set the authentication headers.

B<Parameters>

=over

=item C<url:Scalar> - the url to query

=item C<content:Scalar> - the content to put.

=back

B<Returns> 

=over 

=item C<response:Scalar> - the response to the query in case of success.

=back

B<Throws> 

=over

=item L<WebService::GData::Error> if it fails to reach the contents.

=back

Example:

    use WebService::GData::Base;
	
    #you must be authorized to do any write actions.
    my $base   = new WebService::GData::Base(auth=>...);
    
    #create a new entry with application/atom+xml; charset=UTF-8 content-type
    my $ret = $base->upate($url,$content);
	
=back

=head3 delete

=over

Delete data from an url with application/atom+xml; charset=UTF-8 content type (DELETE).

B<Parameters>

=over

=item C<url:Scalar> - the url to query

=back

B<Returns> 

=over

=item C<response:Scalar> - the response to the query in case of success.

=back

B<Throws> 

=over

=item L<WebService::GData::Error> if it fails to reach the contents.

=back


Example:

    use WebService::GData::Base;
	
    #you must be authorized to do any write actions.
    my $base   = new WebService::GData::Base(auth=>...);
    
    #create a new entry with application/atom+xml; charset=UTF-8 content-type
    my $ret = $base->delete($url);
	
=back


=head2  HANDLING ERRORS

Google data APIs relies on querying remote urls on particular services.

Some of these services limits the number of request with quotas and may return an error code in such a case.

All queries that fail will throw (die) a L<WebService::GData::Error> object. 

You should enclose all code that requires connecting to a service within eval blocks in order to handle it.


Example:

    use WebService::GData::Base;
	
    my $base   = new WebService::GData::Base();
	
    #the server is dead or the url is not available anymore or you've reach your quota of the day.
    #boom the application dies and your program fails...
    $base->get('http://gdata.youtube.com/feeds/api/standardfeeds/top_rated');

    #with error handling...

    #enclose your code in a eval block...
    eval {
        $base->get('http://gdata.youtube.com/feeds/api/standardfeeds/top_rated');
    }; 

    #if something went wrong, you will get a WebService::GData::Error object back:
    if(my $error = $@){

        #do whatever you think is necessary to recover (or not)
        #print/log: $error->content,$error->code
    }	


=head1  DEPENDENCIES

L<JSON>

L<LWP>

=head1 BUGS AND LIMITATIONS

If you do me the favor to _use_ this module and find a bug, please email me
i will try to do my best to fix it (patches welcome)!

=head1 AUTHOR

shiriru E<lt>shirirulestheworld[arobas]gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

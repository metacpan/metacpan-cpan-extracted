#!/usr/bin/perl
# GetUserInfo.pm, a number as an object

package GetUserInfo;	# This is the &quot;Class&quot;
    use OxdPackages::OxdClient;
	use base qw(OxdClient Class::Accessor);
	use strict;
	our @ISA = qw(OxdClient);    # inherits from OxdClient
	
	use vars qw($VERSION);
    $VERSION = '0.01';
	
	sub new {
		my $class = shift;
		my $self = {
			# @var string $request_oxd_id                            This parameter you must get after registration site in gluu-server
			_request_oxd_id => shift,
			
			# @var string $request_access_token                            This parameter you must get after using get_token_code class
			_request_access_token => shift,
			
			# Response parameter from oxd-server
			# Showing logedin user information
			# @var array $response_claims
			_response_claims => shift,
        };
		# Print all the values just for clarification.
		#print "setRequestOxdId is $self->{_request_oxd_id}<br>";
		#print "setRequestCode is $self->{_request_code}<br>";
		#print "setRequestState is $self->{_request_state}<br>";
		bless $self, $class;
		
		return $self;
	} 
	
	
   
    # @return array
    
    sub getResponseClaims
    {   
		my( $self ) = @_;
		$self->{_response_claims} = $self->getResponseData()->{claims};
		return $self->{_response_claims};
    }

    
    # @return string
    
    sub getRequestAccessToken
    {   
		my( $self ) = @_;
		return $self->{_request_access_token};
    }

    
    # @param string $request_access_token
    # @return void
    
    sub setRequestAccessToken
    {
		my ( $self, $request_access_token ) = @_;
		$self->{_request_access_token} = $request_access_token if defined($request_access_token);
		return $self->{_request_access_token};
    }

    
    # @return string
    
    sub getRequestOxdId
    {  
		my( $self ) = @_;
		return $self->{_request_oxd_id};
    }

    
    # @param string $request_oxd_id
    # @return void
    
    sub setRequestOxdId
    {   
		my ( $self, $request_oxd_id ) = @_;
		$self->{_request_oxd_id} = $request_oxd_id if defined($request_oxd_id);
		return $self->{_request_oxd_id};
    }

    
    # Protocol command to oxd server
    # @return void
    
    sub setCommand
    {
        my ( $self, $command ) = @_;
		$self->{_command} = 'get_user_info';
		return $self->{_command};
    }
    
    # Protocol parameter to oxd server
    # @return void
    
    sub setParams
    {   
		my ( $self, $params ) = @_;
        my $paramsArray = {
            "oxd_id" => $self->getRequestOxdId(),
            "access_token" => $self->getRequestAccessToken()
        };
        $self->{_params} = $paramsArray;
		return $self->{_params};
    }
	 
	
1;		# this 1; is neccessary for our class to work

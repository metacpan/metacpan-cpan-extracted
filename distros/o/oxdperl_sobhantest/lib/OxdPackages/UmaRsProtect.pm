#!/usr/bin/perl

 ##
 # Gluu-oxd-library
 #
 # An open source application library for Perl
 #
 # This content is released under the MIT License (MIT)
 #
 # Copyright (c) 2017, Gluu inc, USA, Austin
 #
 # Permission is hereby granted, free of charge, to any person obtaining a copy
 # of this software and associated documentation files (the "Software"), to deal
 # in the Software without restriction, including without limitation the rights
 # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 # copies of the Software, and to permit persons to whom the Software is
 # furnished to do so, subject to the following conditions:
 #
 # The above copyright notice and this permission notice shall be included in
 # all copies or substantial portions of the Software.
 #
 # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 # OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 # THE SOFTWARE.
 #
 # @package		Gluu-oxd-library
 # @version     	3.1.0
 # @author		Inderpal Singh, Sobhan Panda
 # @author_email	inderpal@ourdesignz.com, sobhan@centroxy.com
 # @copyright		Copyright (c) 2017, Gluu inc federation (https://gluu.org/)
 # @license		http://opensource.org/licenses/MIT	MIT License
 # @link		https://gluu.org/
 # @since		Version 3.1.0
 # @filesource
 #/

 ##
 # UMA RS Protect resources package
 #
 # Package is connecting to oxd-server via socket, and adding resources in gluu-server.
 #
 # @package		Gluu-oxd-library
 # @subpackage		Libraries
 # @category		Relying Party (RP) and User Managed Access (UMA)
 # @author		Inderpal Singh, Sobhan Panda
 # @author		inderpal@ourdesignz.com, sobhan@centroxy.com
 # @see	        	OxdClientSocket
 # @see	        	OxdClient
 # @see	        	OxdConfig
 ##

package UmaRsProtect;
use vars qw($VERSION);
$VERSION = '0.01';
use OxdPackages::OxdClient;
use base qw(OxdClient Class::Accessor);
use strict;
our @ISA = qw(OxdClient);    # inherits from OxdClient 
use Data::Dumper;
    
    sub new {
		my $class = shift;
		my $self = {
			# @var string $request_oxd_id                         This parameter you must get after registration site in gluu-server
			_request_oxd_id  => shift,
			
			_request_protection_access_token => shift,

			# @var array $request_resources                       This parameter your resources parameter
			_request_resources  => [],
			_request_resource  => [],
			_request_condition  => [],
		};
		# Print all the values just for clarification.
		#print "First Name is $self->{_request_oxd_id}\n";
		
		#print "<br>";
		bless $self, $class;
		return $self;
    }

    # @return string
    sub getRequestOxdId{
		my( $self ) = @_;
		return $self->{_request_oxd_id};
    }

    # @param string $request_oxd_id
    # @return void
    sub setRequestOxdId{
		my ( $self, $request_oxd_id ) = @_;
		$self->{_request_oxd_id} = $request_oxd_id if defined($request_oxd_id);
		return $self->{_request_oxd_id};
	}

    # @return array
    sub getRequestProtectionAccessToken
    {   
		my( $self ) = @_;
		return $self->{_request_protection_access_token};
    }

    
    # @param array $request_request_protection_access_token
    # @return void
    sub setRequestProtectionAccessToken
    {
		my ( $self, $request_protection_access_token ) = @_;
		$self->{_request_protection_access_token} = $request_protection_access_token if defined($request_protection_access_token);
		return $self->{_request_protection_access_token};
	}
    
    # @return array
    sub getRequestResources{
        my( $self ) = @_;
		return $self->{_request_resources};
	}

    sub addResource{
		my ( $self, $path ) = @_;
		
        my @request_resources =  {
            'path'=>$path,
            'conditions' => $self->{_request_condition}
        };
        
		push $self->{_request_resources}, @request_resources;
		$self->{_request_condition} = "";
    }

    sub addConditionForPath{
        my ( $self, $httpMethods, $scopes, $ticketScopes ) = @_;
        
        my @request_condition =  {
                                "httpMethods" => $httpMethods,
                                "scopes" => $scopes,
                               "ticketScopes" => $ticketScopes
        };
        
        push $self->{_request_condition}, @request_condition;
        return $self->{_request_condition};
    }
    sub getCondition{
		my( $self ) = @_;
		return $self->{_request_condition};
    }
    
    # Protocol command to oxd server
    # @return void
    sub setCommand{
		my ( $self ) = @_;
        $self->{_command} = 'uma_rs_protect';
    }
    
    # Protocol command to oxd to http server
    # @return void
    sub sethttpCommand {
		my ( $self ) = @_;
        $self->{_httpcommand} = 'uma-rs-protect';
    }

    # Protocol parameter to oxd server
    # @return void
    sub setParams{
        my ( $self, $params ) = @_;
        my $paramsArray = {
            "oxd_id" => $self->getRequestOxdId(),
            "resources" => $self->getRequestResources(),
            "protection_access_token" => $self->getRequestProtectionAccessToken()

        };
       # print Dumper $paramsArray;
        $self->{_params} = $paramsArray;
        
        #exit 1;
		return $self->{_params};
    }

1;		# this 1; is neccessary for our class to work

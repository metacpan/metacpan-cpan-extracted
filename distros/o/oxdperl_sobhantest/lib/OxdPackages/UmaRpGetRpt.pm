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
 # @copyright		Copyright (c) 2016, Gluu inc federation (https://gluu.org/)
 # @license		http://opensource.org/licenses/MIT	MIT License
 # @link		https://gluu.org/
 # @since		Version 3.1.0
 # @filesource
 #

##
 # UMA RP - Get Rpt class
 #
 # Class is connecting to oxd-server via socket, and getting GAT from gluu-server.
 #
 # @package		Gluu-oxd-library
 # @subpackage		Libraries
 # @category		Relying Party (RP) and User Managed Access (UMA)
 # @author		Inderpal Singh, Sobhan Panda
 # @author		inderpal@ourdesignz.com, sobhan@centroxy.com
 # @see	        	OxdClientSocket
 # @see	        	OxdClient
 # @see	        	OxdConfig
 #/

package UmaRpGetRpt;
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
			
			# @var string $request_oxd_id                            This parameter you must get after registration site in gluu-server
			_request_oxd_id => shift,
			
			# @var bool $request_force_new                          Indicates whether return new RPT, in general should be false, so oxd server can cache/reuse same RPT
			_request_force_new => shift,
			
			_request_ticket => shift,
			
			_request_claim_token => shift,
			
			_request_claim_token_format => shift,
			
			_request_pct => shift,
			
			_request_rpt => shift,
			
			_request_scope => shift,
			
			_request_state => shift,
			
			_request_protection_access_token => shift,
			
			
			# Response parameter from oxd-server
			# Gluu RP Token
			# @var string $response_rpt
			
			_response_rpt => shift
		};
		# Print all the values just for clarification.
		# print "First Name is $self->{_request_oxd_id}\n";
		
		# print "<br>";
		bless $self, $class;
		return $self;
    } 
    
    # @return string
    sub getRequestOxdId
    {   
		my( $self ) = @_;
		return $self->{_request_oxd_id}
    }

    ##
    # @param string $request_oxd_id
    # @return void
    #
    sub setRequestOxdId
    {   
		my ( $self, $request_oxd_id ) = @_;
		$self->{_request_oxd_id} = $request_oxd_id if defined($request_oxd_id);
		return $self->{_request_oxd_id};
    }

    ##
    # @return bool
    #
    sub getRequestForceNew
    {   
		my( $self ) = @_;
		return $self->{_request_force_new};
    }

    ##
    # @param bool $request_force_new
    # @return void
    #
    sub setRequestForceNew
    {   
		my ( $self, $request_force_new ) = @_;
		$self->{_request_force_new} = $request_force_new if defined($request_force_new);
		return $self->{_request_force_new};
	}


    # @return string
    sub getRequestTicket
    {   
		my( $self ) = @_;
		return $self->{_request_ticket}
    }

    ##
    # @param string $request_ticket
    # @return void
    #
    sub setRequestTicket
    {   
		my ( $self, $request_ticket ) = @_;
		$self->{_request_ticket} = $request_ticket if defined($request_ticket);
		return $self->{_request_ticket};
    }
    
    
    # @return string
    sub getRequestClaimToken
    {   
		my( $self ) = @_;
		return $self->{_request_claim_token}
    }

    ##
    # @param string $request_claim_token
    # @return void
    #
    sub setRequestClaimToken
    {   
		my ( $self, $request_claim_token ) = @_;
		$self->{_request_claim_token} = $request_claim_token if defined($request_claim_token);
		return $self->{_request_claim_token};
    }
    
    
    # @return string
    sub getRequestClaimTokenFormat
    {   
		my( $self ) = @_;
		return $self->{_request_claim_token_format}
    }

    ##
    # @param string $request_claim_token_format
    # @return void
    #
    sub setRequestClaimTokenFormat
    {   
		my ( $self, $request_claim_token_format ) = @_;
		$self->{_request_claim_token_format} = $request_claim_token_format if defined($request_claim_token_format);
		return $self->{_request_claim_token_format};
    }
    
    
    # @return string
    sub getRequestPCT
    {   
		my( $self ) = @_;
		return $self->{_request_pct}
    }

    ##
    # @param string $request_pct
    # @return void
    #
    sub setRequestPCT
    {   
		my ( $self, $request_pct ) = @_;
		$self->{_request_pct} = $request_pct if defined($request_pct);
		return $self->{_request_pct};
    }
    
    
    # @return string
    sub getRequestRPT
    {   
		my( $self ) = @_;
		return $self->{_request_rpt}
    }

    ##
    # @param string $request_rpt
    # @return void
    #
    sub setRequestRPT
    {   
		my ( $self, $request_rpt ) = @_;
		$self->{_request_rpt} = $request_rpt if defined($request_rpt);
		return $self->{_request_rpt};
    }
    
    
    # @return string
    sub getRequestScope
    {   
		my( $self ) = @_;
		return $self->{_request_scope}
    }

    ##
    # @param string $request_scope
    # @return void
    #
    sub setRequestScope
    {   
		my ( $self, $request_scope ) = @_;
		$self->{_request_scope} = $request_scope if defined($request_scope);
		return $self->{_request_scope};
    }
    
    
    # @return string
    sub getRequestState
    {   
		my( $self ) = @_;
		return $self->{_request_state}
    }

    ##
    # @param string $request_state
    # @return void
    #
    sub setRequestState
    {   
		my ( $self, $request_state ) = @_;
		$self->{_request_state} = $request_state if defined($request_state);
		return $self->{_request_state};
    }
    
    
    # @return string
    sub getRequestProtectionAccessToken
    {   
		my( $self ) = @_;
		return $self->{_request_protection_access_token}
    }

    ##
    # @param string $request_protection_access_token
    # @return void
    #
    sub setRequestProtectionAccessToken
    {   
		my ( $self, $request_protection_access_token ) = @_;
		$self->{_request_protection_access_token} = $request_protection_access_token if defined($request_protection_access_token);
		return $self->{_request_protection_access_token};
    }
    
    
    ##
    # @return string
    #
    sub getResponseRpt
    {    
		my( $self ) = @_;
		$self->{_response_rpt} = $self->getResponseData()->{rpt};
        return $self->{_response_rpt};
    }

    ##
    # Protocol command to oxd server
    # @return void
    #
    sub setCommand
    {	
		my ( $self ) = @_;
        $self->{_command} = 'uma_rp_get_rpt';
    }
    
    ##
    # Protocol command to oxd to http server
    # @return void
    #
    sub sethttpCommand
    {	
		my ( $self ) = @_;
        $self->{_httpcommand} = 'uma-rp-get-rpt';
    }

    ##
    # Protocol parameter to oxd server
    # @return void
    #
    sub setParams
    {
        my ( $self, $params ) = @_;
        my $paramsArray = {
            "oxd_id" => $self->getRequestOxdId(),
            "ticket" => $self->getRequestTicket(),
            "claim_token" => $self->getRequestClaimToken(),
            "claim_token_format" => $self->getRequestClaimTokenFormat(),
            "pct" => $self->getRequestPCT(),
            "rpt" => $self->getRequestRPT(),
            "scope" => $self->getRequestScope(),
            "state" => $self->getRequestState(),
            "protection_access_token" => $self->getRequestProtectionAccessToken()
        };
        $self->{_params} = $paramsArray;
        return $self->{_params};
    }

1;		# this 1; is neccessary for our class to work

#!/usr/bin/perl

##
 # Gluu-oxd-library
 #
 # An open source application library for PHP
 #
 # This content is released under the MIT License (MIT)
 #
 # Copyright (c) 2016, Gluu inc, USA, Austin
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
 # @package	    Gluu-oxd-library
 # @version     2.4.4
 # @author	    Inderpal Singh
 # @author		inderpal@ourdesignz.com
 # @copyright	Copyright (c) 2016, Gluu inc federation (https://gluu.org/)
 # @license	    http://opensource.org/licenses/MIT	MIT License
 # @link	    https://gluu.org/
 # @since	    Version 2.4.4
 # @filesource
 #

##
 # UMA RP - Get Rpt class
 #
 # Class is connecting to oxd-server via socket, and getting GAT from gluu-server.
 #
 # @package		Gluu-oxd-library
 # @subpackage	Libraries
 # @category	Relying Party (RP) and User Managed Access (UMA)
 # @author		Inderpal Singh
 # @author		inderpal@ourdesignz.com
 # @see	        OxdClientSocket
 # @see	        OxdClient
 # @see	        OxdConfig
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
    # Protocol parameter to oxd server
    # @return void
    #
    sub setParams
    {
        my ( $self, $params ) = @_;
        my $paramsArray = {
            "oxd_id" => $self->getRequestOxdId(),
            "force_new" => $self->getRequestForceNew()

        };
        $self->{_params} = $paramsArray;
        return $self->{_params};
    }

1;		# this 1; is neccessary for our class to work

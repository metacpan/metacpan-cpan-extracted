#!/usr/bin/perl
# OxdClient.pm, a number as an object

#
# Gluu-oxd-library
#
# An open source application library for Perl
#
# This content is released under the MIT License (MIT)
#
# Copyright (c) 2018, Gluu inc, USA, Austin
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
# @package	Gluu-oxd-library
# @version	3.1.2
# @author	Sobhan Panda
# @author_email	sobhan@centroxy.com
# @copyright	Copyright (c) 2018, Gluu inc federation (https://gluu.org/)
# @license	http://opensource.org/licenses/MIT	MIT License
# @link		https://gluu.org/
# @since	Version 3.1.2
# @filesource
#/


package Attribute::Abstract;

package OxdClient;	# This is the &quot;Class&quot;
    
    use vars qw($VERSION);
    $VERSION = '0.01';
     
    use OxdPackages::OxdClientSocket;
    our @ISA = qw(OxdClientSocket);    # inherits from OxdClient
	# makes all attributes available
	use lib './modules';
	use Attribute::Handlers;
	use strict;
	use warnings;
	use JSON::PP;
    use OxdPackages::OxdConfig;
	use Data::Dumper qw(Dumper);
	use utf8;
	use Encode;
	
	
	sub new {
		my $class = shift;
		my $self = {
			# @var string $command             Extend class protocol command name, for sending oxd-server
			_command=>shift,
			
			# @var string $httpcommand         Extend class protocol command name, for sending oxd-https-extension
			_httpcommand=>shift,
			
			# @var string $params              Extends class sending parameters to oxd
			_params => [],
			
			# @var string $data                Response data from oxd
			_data => [],
			
			# @var string $response_json       Response data from oxd in format json
			_response_json=>shift,
			
			# @var object $response_object     Response data from oxd in format object
			_response_object=>shift,
			
			# @var string $response_status     Response status from oxd
			_response_status=>shift,
			
			# @var array $response_data        Response data from oxd in format array
			_response_data => [],

		
		};
		# Print all the values just for clarification.
		#print "First Name is $self->{_firstName}\n";
		bless $self, $class;
		
		return $self;
	}  
	
	# send function sends the command to the oxd server.
    # Args:
    # command (dict) - Dict representation of the JSON command string
    # @return	void
    #
    
    
    # Method: request
    # This method is called for sending request to oxd for all the oxd commands.
    #
    # Parameters:
    #
    #	object RequestObject
    #
    # Returns:
    #	void
    sub request {
		my ($self) = @_;
		
		# @var array $command_types        Protocols commands name
	    my @command_types  =  ("get_authorization_url",
							    "update_site_registration",
								"get_tokens_by_code",
								"get_user_info",
								"register_site",
								"get_logout_uri",
								"get_authorization_code",
								"uma_rs_protect",
								"uma_rs_check_access",
								"uma_rp_get_rpt",
								"uma_rp_authorize_rpt",
								"uma_rp_get_gat");
		
		
		$self->setCommand();
		$self->sethttpCommand();
		
		my $exist = 'false';
        for (my $i=0; $i <= scalar @command_types; $i++) {
			if ($command_types[$i]  eq $self->getCommand()) {
                my $exist = 'true';
                last;
            }
        }
       
        
        if (!$exist) {
            $self->log('Command: ' . $self->getCommand() . ' is not exist!','Exiting process.');
            $self->error_message('Command: ' . $self->getCommand() . ' is not exist!');
        }
		
        $self->setParams();
        
        my $oxdConfig = OxdConfig->new();
		my $connectionType = $oxdConfig->{'_connection_type'};
        
		my $json_array = $self->getData();
		my $http_json = $self->getParams();
		my $httpcommand = $self->gethttpCommand();
		
		my $json = JSON::PP->new;
		
        my $jsondata = $json->encode($json_array);
        my $httpParams = $json->encode($http_json);
       
	
        if(!$self->is_JSON($jsondata)){
            $self->log("Sending parameters must be JSON.",'Exiting process.');
            $self->error_message('Sending parameters must be JSON.');
        }
         
        my $lenght = length $jsondata;
        
        if($lenght<=0){
            $self->log("Length must be more than zero.",'Exiting process.');
            $self->error_message("Length must be more than zero.");
        }else{
            $lenght = $lenght <= 999 ? "0" . $lenght : $lenght;
        }
        
        my $lenght_jsondata = encode('UTF-8', $lenght . $jsondata);
        
        my $response_json = "";	
	
	if($connectionType eq 'local') {
	    $response_json = $self->oxd_socket_request($lenght_jsondata);
	    my $char_count = substr($response_json, 0, 4);
	    $response_json =~ s/$char_count//g;
	}
	elsif($connectionType eq 'web') {
	    $response_json = $self->oxd_http_request($httpParams, $httpcommand);
	    $response_json = $response_json->{_content};
	}
        
        $self->{_response_json} = $response_json if defined($response_json);
        if ( $response_json) {
            my $object = JSON::PP->new->utf8->decode($response_json);
            
            if ($object->{status} eq 'error') {
		if($object->{data}->{error} eq 'need_info') {
			$self->setResponseObject( $object );
		}
		else {
			$self->error_message($object->{data}->{error} . ' : ' . $object->{data}->{error_description});
		}
            } elsif ($object->{status} eq 'ok') {
                $self->setResponseObject( $object );
            }
        } else {
			print "I am here";
            $self->log("Response is empty...",'Exiting process.');
            $self->error_message('Response is empty...');
        }
    }

    
    # Response status
    # @return string, OK on success, error on failure
    sub getResponseStatus
    {  
		my ($self) = @_;
		return $self->{_response_status};
    }

    
    # Setting response status
    # @return	void
    sub setResponseStatus
    {
		my ( $self) = @_;
		$self->{_response_status} = $self->getResponseObject()->{status};
		return $self->{_response_status};
	}

    
    # Method: getResponseData
    # If data is not empty it is returning response data from oxd in array format.
    # If data empty or error , you have problem with parameter or protocol.
    #
    # Parameters:
    #
    #	object ResponseObject
    #
    # Returns:
    #	object ResponseData
    sub getResponseData{
		my ($self) = @_;
        if (!$self->getResponseObject()) {
            $self->{_response_data} = 'Data is empty';
            $self->error_message($self->{_response_data});
        } else {
            $self->{_response_data} = $self->getResponseObject()->{data};
        }
        return $self->{_response_data};
    }

    # Method: getData
    # Data which need to send to oxd server.
    #
    # Parameters:
    #
    #	string $command - oxd-server command name
    #
    #	dict $params - oxd-server request parameters
    #
    # Returns:
    #	object RequestObject
    sub getData{  
		my ($self) = @_;
		
		my $data = {
            "command" => $self->getCommand(),
            "params" => $self->getParams(),
        };
		
		#my @data = ('command' => $self->getCommand(), 'params' => $self->getParams());
        return $data;
    }

    
    # Protocol name for request.
    # @return string
     
    sub getCommand{
        my ($self) = @_;
        return $self->{_command};
        #return 'register_site';
    }

    # Protocol name for request.
    # @return string
     
    sub gethttpCommand{
        my ($self) = @_;
        return $self->{_httpcommand};
    }

    # Setting protocol name for request.
    # @return void
    #sub setCommand : Abstract;
   
    # If response data is not empty it is returning response data from oxd-server in format object.
    # If response data empty or error , you have problem with parameter or protocol.
    #
    # @return object
     
    sub setResponseObject{
		my ( $self, $response_object ) = @_;
		$self->{_response_object} = $response_object if defined($response_object);
		return $self->{_response_object};
    }
    
    
    # Method: getResponseObject
    # It returns response object from oxd-server in json format.
    #
    # Returns:
    #	object ResponseObject
    sub getResponseObject{
		my ($self) = @_;
		return $self->{_response_object};
    }

    
    
    # @return string
     
    sub getResponseJSON{
		my ($self) = @_;
		return $self->{_response_json};
    }

    
    # Setting parameters for request.
    # @return void
    #sub setParams : Abstract; 
    
    
    # Parameters for request.
    # @return array
    sub getParams{
	   my ($self) = @_;
       return $self->{_params};
    }

    
    # Checking format string.
    # @param  string  $string
    # @return bool
    sub is_JSON{
		# Get passed arguments
        my($self,$jsondata) = @_;
        my $json_out = eval { decode_json($jsondata) };
		if ($@){
			#print "Error: $@";
			return 0;
		}else{
			return 1;
			#print "OK!\n";
		}
    }

1;		# this 1; is neccessary for our class to work

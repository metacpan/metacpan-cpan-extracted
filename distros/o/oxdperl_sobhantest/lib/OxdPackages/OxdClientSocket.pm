#!/usr/bin/perl
# OxdClientSocket.pm, a number as an object

#
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
# @package	Gluu-oxd-library
# @version	3.1.0
# @author	Sobhan Panda
# @author_email	sobhan@centroxy.com
# @copyright	Copyright (c) 2017, Gluu inc federation (https://gluu.org/)
# @license	http://opensource.org/licenses/MIT	MIT License
# @link		https://gluu.org/
# @since	Version 3.1.0
# @filesource
#/


package OxdClientSocket;	# This is the &quot;Class&quot;

    use vars qw($VERSION);
    $VERSION = '0.01';
	# makes all attributes available
	use Time::Piece;
	use lib './modules';
	use Attribute::Handlers;
	#use strict;
	use warnings;
	use 5.010;
	use JSON::PP;
    use Data::Dumper qw(Dumper);
	use utf8;
	use Encode;
	use File::Basename;
	use warnings;
	use OxdPackages::OxdConfig;
	#use IO::Socket::Socks;
	use CGI::Session;#Test
    use IO::Socket::SSL qw(debug0);
    use LWP::UserAgent;
    use Crypt::SSLeay;
    use Net::SSL ();
	#use Sys::Hostname;
	#$| = 1;
	use constant BUFSIZE => 1024;
    
	sub new { 
		my $class = shift;
		my $self = {
			# @static
			# @var object $socket        Socket connection
			_socket => shift,
			
			# @var string $base_url      Base url for log file directory and oxd-rp-setting.json file.
			_base_url => dirname(__FILE__)

	    };
		
		bless $self, $class;
		return $self;
	}  
     
	# Sending request to oxd server via socket
    #
    # @param  string  $data
    # @param  int  $char_count
    # @return object
    sub oxd_socket_request{
	    my ($self,$data, $char_count) = @_;
	    $char_count =  $char_count ? $char_count : 8192;
	    
	    #print $data;#Test
	    
	    my $oxdConfig = OxdConfig->new();
	    my $op_host = $oxdConfig->{'_op_host'};
	    my $oxd_host_port = $oxdConfig->{'_oxd_host_port'};
	   
	    $socket = new IO::Socket::INET ( PeerHost => '127.0.0.1', PeerPort => $oxd_host_port, Proto => 'tcp', Reuse => 1) or die "$!\n"; 
	    if (!$socket) {
		$self->log("Client: socket::socket_connect is not connected, error: ",$!);
	    die $!;
	    }else{
	       $self->log("Client: socket::socket_connect ", "socket connected");
	    }
	    
	    if(!($socket->syswrite($data, length($data)))){
		    $self->log("Client: socket::socket_connect ", "Error writing");
	    }
	    
	    $self->log("Client: oxd_socket_request", $socket->syswrite($data, length($data)));
	    $socket->syswrite($data, length($data));
	    
	    sysread($socket, $result, $char_count);
		
	    if($result){
		$self->log("Client: oxd_socket_response", $result);
	    }else{
		$self->log("Client: oxd_socket_response", 'Error socket reading process.');
	    }
	    if(close($socket)){
		$self->log("Client: oxd_socket_connection", "disconnected.");
	    }
	    return $result;
	}
	
	
    sub oxd_http_request {
	    
	    my ($self,$data, $httpcommand, $char_count) = @_;
	    $char_count =  $char_count ? $char_count : 8192;
	    
	    my $json = JSON::PP->new;
	    my $jsonContent = $json->decode($data);
	    
	    my $accessToken = '';
	    if ($jsonContent->{protection_access_token}) {
		    $accessToken = "Bearer ".$jsonContent->{protection_access_token};
	    }
	    
	    
	    my $oxdConfig = OxdConfig->new();
	    my $rest_service_url = $oxdConfig->{'_rest_service_url'};
	    
	    my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });# 0: Do not verify SSL, 1: verify SSL
	    $ua->protocols_allowed( [ 'http','https'] );
	    
	    
	    ## If the URL does not contain '/' as the last character, then add '/' at the last
	    my $lc = substr($rest_service_url, -1);
	    if($lc ne '/')
	    {
		    $rest_service_url = $rest_service_url.'/';
	    }
	    
	    my $url = $rest_service_url.$httpcommand;
	    
	    my $header = HTTP::Headers->new;
	    $header->header(Accept => 'application/json', Authorization => $accessToken);
	    
	    my $req = HTTP::Request->new('POST', $url, $header);
	    
	    $req->content($data);
	    #Pass request to the user agent and get a response back
	    my $response = $ua->request($req);
	    

	    #Check the outcome of the response
	    if ($response->is_success) {
		$self->log("Client: oxd_http_response", $response);
	    } else {
	        $self->log("Client: oxd_http_response", 'Error while processing.');
	    }
	    
	    return $response;
	}
	
	
	
    # Showing errors and exit.
    # @param  string  $error
    # @return void
    sub error_message{
		my ($self, $error) = @_;
		print '<div class="alert alert-danger"> ' . $error.'</div>';
        exit($error);
    }
    
    # Saving process in log file.
    # @param  string  $process
    # @param  string  $message
    # @return void
    sub log{
		my ($self, $process, $message) = @_;
        
		my $t = localtime;
		my $timeStamp =  $t->mdy("-");# 02/29/2000
		
		my $fileName = "oxd-perl-server-$timeStamp.log";
        
        my $datestring = localtime();
        
        my $filename = "logs/$fileName";
		open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";
		my $person = "\n".$datestring."\n".$process." ".$message."\n";
		say $fh "$person\n";
		close $fh;
		#say "done\n";
    }

1;		# this 1; is neccessary for our class to work

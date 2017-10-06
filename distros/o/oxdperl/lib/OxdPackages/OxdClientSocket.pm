#!/usr/bin/perl
# OxdClientSocket.pm, a number as an object

#####################################
# Client Script:
# Copyright 2016 (c) Ourdesignz
# this program is distributed according to
# the terms of the Perl license
# Use at your own risk
#####################################



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
    use IO::Socket::SSL qw(debug0);
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
		
		#print $data;
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
		#print "$result\n";
		
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

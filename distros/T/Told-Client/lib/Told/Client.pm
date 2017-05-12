package Told::Client;

use 5.016002;
use strict;
use warnings;

use JSON;
use LWP;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	tell
    setDebug
    setConnectionType
    setHost
    setType
    setTags
    setDefaulttags
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    getParams
);

our $VERSION = '0.01';

sub new {
    my $package = shift;
    my $config = shift;
    my $recref = {};
    bless $recref, $package;
    $recref->setHost(           $config->{'host'} || '');
    $recref->setType(           $config->{'type'} || '');
    $recref->setDefaulttags(    @{$config->{'defaulttags'}}) if($config->{'defaulttags'});
    $recref->setTags(           @{$config->{'tags'}}) if($config->{'tags'});
    $recref->setConnectionType( $config->{'connection'} || 'POST');
    
    return $recref;
}

sub setDebug {
    my $self = shift;
    if(@_) {
        $self->{'verbose'} = shift;
    }
    print "Told::Client in debug mode.\n" if $self->{'verbose'};
}

sub getParams {
    my $self = shift;
    my $param = {
        'host' => $self->{'host'}
        , 'type' => $self->{'type'}
        , 'defaulttags' => $self->{'defaulttags'}
        , 'tags' => $self->{'tags'}
    };
    return $param;
}


sub setConnectionType {
    my $self = shift;
    my $type = shift;
    if($type) {
        if($type =~ /GET|POST|UDP/i){
            $self->{'connectiontype'} = $type;
        } else {
            warn("Connectiontype ".$type." is not known.") if $self->{'verbose'};
            return 0;
        }
    }
    return 1;
}


sub setHost {
    my $self = shift;
    if(@_) {
        $self->{'host'} = shift;
    }
    print "Setting host to: ". $self->{'host'} ."\n" if $self->{'verbose'};
}

sub setType {
    my $self = shift;
    if(@_) {
        $self->{'type'} = shift;
    }
    print "Setting type to: ". $self->{'type'} ."\n" if $self->{'verbose'};
}

sub setTags {
    my $self = shift;
    my @tags;
    while(@_){
        push(@tags, shift);
    }
    $self->{'tags'} = \@tags;
    print "Setting tags to: ". join(", ", @{$self->{'tags'}}) ."\n" if $self->{'verbose'};
}

sub setDefaulttags {
    my $self = shift;
    my @defaulttags;
    while(@_){
        push(@defaulttags, shift);
    }
    $self->{'defaulttags'} = \@defaulttags;
    print "Setting defaulttags to: ". join(", ", @{$self->{'defaulttags'}}) ."\n" if $self->{'verbose'};
}

sub tell {
    my $self = shift;
    my ($_message, $_type, @_tags) = @_;
    
    my $browser = LWP::UserAgent->new;
    if(!$self->{'host'} || length($self->{'host'}) == 0){
        warn "No host ist set\n" if $self->{'verbose'};
        return 0;
    }
    $self->{'host'} =~ s/^(([a-z]{0,5}\:\/\/)?([^\/]+))\/?$/$1/isg;
    
    my @tags = ();
    my $cnt_fn_tags = @_tags;
    my $cnt_known_tags = @{$self->{'tags'}} if($self->{'tags'});
    @tags = @{$self->{'defaulttags'}} if($self->{'defaulttags'} && ($cnt_fn_tags <= 0 && $cnt_known_tags <= 0));
    
    foreach my $t(@{$self->{'tags'}} ){
        push(@tags, $t);
    }
    if($cnt_fn_tags > 0){
    	foreach my $t(@_tags){
    		push(@tags, $t);
    	}
    
    }
    
	my $type = $_type || $self->{'type'} || "";
 	my $message;
	if (ref($_message) eq "HASH") {
		
        if($_message->{type}){
            $type = $_message->{type} if($type eq '');
            delete $_message->{type};
        }
        if($_message->{tags}){
			foreach my $t(@{$_message->{tags}}){
                push(@tags, $t);
            };
            delete $_message->{tags};
        }
        # if there is only one message as string:
        if( ref($_message->{message}) eq ''  ){
        	$message = $_message->{message};
        } else {
        	$message = $_message;
        	if($self->{'connectiontype'} eq 'GET'){
        		warn("This message can not be send via get. Set the Type to POST automaticly for this message.") if $self->{'verbose'};
        		$self->{'connectiontype'} = 'POST';
        	}
        }
    }
    
    my $result;
    if($self->{'connectiontype'} eq 'GET'){
	    my $query;
	    $query .= "message=". $message if($message);
	    my $anz_tags = @tags;
	    if($anz_tags > 0){
	    	$query .= "&" if($message && length($message) > 0);
	        $query .= 'tags=';
    	    $query .= join(",", uniq(@tags));
    	    $query .= "&" if(length($type) > 0)
    	}
        $query .= "etype=". $type if(length($type) > 0);
        
        if($self->{'host'} =~ /^test/){
            $result = $self->{'host'}."/log?". $query;
        } else {
            $result = $browser->get($self->{'host'}."/log?". $query);
        }
    }
    elsif($self->{'connectiontype'} eq 'POST'){
    	my %data;
    	$data{'etype'} = $type;
    	$data{'tags'} = \@tags;
    	$data{'message'} = $message;
    	
    	if($self->{'host'} =~ /^test/){
            $result = encode_json(\%data);
    	} else {
        	$result = $browser->post($self->{'host'}."/log"
           		, encode_json \%data
	        );
	    }
    } elsif($self->{'connectiontype'} eq 'UDP'){
    	die("UDP is not supported, yet");
    } else {
    	warn("Connection type ". $self->{'connectiontype'}  
    		." is not supportet.\nSet the Type to POST automaticly for this message.")
    		if $self->{'verbose'};
    	$self->setConnectionType("POST");
    	$result = $self->tell($_message, $_type, @_tags);
    }
    return $result;
}

### PRIVATES ###

sub uniq {
    return keys %{{ map { $_ => 1 } @_ }};
}

1;
__END__

=head1 NAME

Told::Client -  A client to log messages into a told log recorder.
See https://github.com/petershaw/told-LogRecorder to lern more about told.

=head1 SYNOPSIS

  my $told = Told::Client->new();
  $told->setHost('http://told.my-domain.com');
  $told->tell('This message should be logged.');

=head1 DESCRIPTION

Sends a message to the server. Noting more, nothing less.

=head2 CONFIGURATION

First of all you have to initiate the Client with a few minimal configurations. 
It is up to you how you set them. It is possible to pass an config array to the init 
method of the client, or to initiate the client blank and set the config-params later on. 

=head3 EXAMPLE

    my $told = Told::Client->new({
       "host"	=> 'http://told.my-domain.com'
    });
    $told->tell('This message should be logged.');

- or -

    my $told = Told::Client->new();
    $told->setHost('http://told.my-domain.com');
    $told->tell('This message should be logged.');


The 'host' parameter is **mandatory**.!
Optional parameters are: type, tags, defaulttage and debug.

tag          Description 

type         Describes the type of this log message. Choose the type wisely, because you will group by type at the administration frontend. |  
tags         These tags will be send ALWAYS right next to the tags that are send by the call it self. It is a good decision to add your application-id and maybe customer-id as tags. |  
defaultags   To set some default tags that will be overwritten by the call . If no tags are given, than the defaulttags take place. |  

Again, it is possible to set the global type and tags in the constructor, or via setters 
later on. 

=head2 SEND

After initialisation the client is ready to use.
To send a message with the default tags and type, just call

     $told->tell("This is my little test message");

Each call can have special types and tags. For example: to send a message with a type of 'Testing' and the Tag 'Honigkuchen' call

    $told->tell("This is my little test message", "Testing", "Honigkuchen");

Or to send multiple tags, like Honigkuchen and Zuckerschlecken it is possible to pass a array:

    $told->tell("This is my little test message", "Testing", ["Honigkuchen", "Zuckerschlecken"]);

It is also possible to send the information in one single hash:

    $told->tell({
	    'message' => "This is my little test message"
	    , 'type' => "Testing"
	    , 'tags' => ["Honigkuchen", "Zuckerschlecken"]
    });

The above example is valid for all the three transportation types. 
Set the connection type with _setCOnnectionType()_ to GET, POST or UDP.

Complex structured messages can not be send with GET. If you try to choose GET and send a 
komplex data, than this module choose POST instead. Turn the debug mode on to get verbose 
output about the internal correction.

    $told->setConnectionType("POST");
    $told->setDebug(1);

A Complex example:

    my $told = Told::Client->new({
	    'host' => 'http://told.my-domain.com'
	    , 'type' => 'Demo'
	    , 'defaulttags' => ['perl', 'told-client', 'manual']
	    , 'tags' => 'notag'
    });
    $told->setDebug(1);
    $told->tell({
	    'message' => {
		    'said' => "This is my little test message"
		    , 'thrown' => 'Exception'
	    }
	    , 'type' => "Testing"
	    , 'tags' => ["Honigkuchen", "Zuckerschlecken"]
    });

=head2 PROTOKOLL

As default, this client use http POST over tcp ip. GET is also available and UDP is in planing.

=head2 EXPORT

	tell
    setDebug
    setConnectionType
    setHost
    setType
    setTags
    setDefaulttags

=head1 SEE ALSO

Told Log-Recorder: https://github.com/petershaw/told-LogRecorder
The github page: https://github.com/petershaw/told-perl-client

=head1 AUTHOR

Peter Shaw, <lt>unthoughted@googlemail.com<gt>

=head1 NO COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it. Do what ever you like.

=cut

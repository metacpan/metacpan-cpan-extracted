package xdSRA;
# Copyright 2004 Jerzy Wachowiak

use strict;
use warnings;
use vars qw( $VERSION );
use Text::CSV_XS;

$VERSION = '1.01';

sub create_sra_from {
    
    my $filepath = shift;

    open( JCLIENTS, "< $filepath") or die "Cannot open $filepath $! ! Bye, Bye...";
    my ( $si, $ri, $ai );
    $si = $ri = $ai = 0;
    my ( $role, $hostname, $port, $username,
    $password, $resource, $comments );
    my ( @sender, @receiver, @archivist );
    my $csv = Text::CSV_XS->new( {'sep_char' => ';'} );
    while( <JCLIENTS> ){
	# Removing trash.
	chomp;
	s/^\s+//;
	s/#.*//;
	s/\s+$//;  
	next unless length();
	$csv->parse( $_ );
	my @record = $csv->fields();
	next unless length( join( '', @record ) );
    
	my ( $comments, $role, $hostname, $port, $username,
        $password, $resource, $OSname, $homepath ) = @record;

    
	#Sanity check
	$role = &trim( $role );
	$hostname = &trim( $hostname );
	$port = &trim( $port );
	$username = &trim( $username );
	$password = &trim( $password );
	$resource = &trim( $resource );
	$comments = &trim( $comments ) if defined( $comments );		    
	$OSname = &trim( $OSname ) if defined( $OSname );
        $homepath = &trim( $homepath ) if defined( $homepath );
		
	if ( $username !~ /^[0-9a-zA-Z\.\-\_]+$/ ){
	        die "Username ", $username,
		 " contains somewhere unallowed character:",
	        ' @, :, /, "',"\ntabs, newline, carriage return,",
	        " control character, ASCI under 33 (decimal). \nBye, bye...\n";
	};
	if ( $username =~ /^[^0-9a-zA-Z]/ ){
	        die "Username $username"
		." must start with alpha or number. Bye, bye...\n";
	};
	if ( length( $username ) > 255 ){
	        die "Username $username\n"
		." is longer than allowed 255 characters. Bye, bye...\n";
	};
	if ( $hostname !~ /^[0-9a-zA-Z\.\-]+$/ ){
		die "Hostname ", $hostname,
	        " contains somewhere unallowed character:",
	        ' @, :, /, "',"\ntabs, newline, carriage return,",
	        " control character, ASCI under 33 (decimal). \nBye, bye...\n";
	};
	if ( $hostname =~ /^[^0-9a-zA-Z]/ ){
		die "Hostname $hostname"
		." must start with alpha or number. Bye, bye...\n";
	};    
	if ( $resource !~ /^[0-9a-zA-Z\.\-\_]+$/ ){
		die "Resource ", $resource,
		" for $username\@$hostname contains somewhere unallowed character:",
		' @, :, /, "',"\ntabs, newline, carriage return,",
		" control character, ASCI under 33 (decimal). \nBye, bye...\n";
	};
#$    
	#Spelling tolerant sender, receiver, archivist array initialisation 
	if ( $role =~ /nd/i ){
	    $sender[$si]{hostname} = $hostname;
	    $sender[$si]{port} = $port;
	    $sender[$si]{username} = $username;
	    $sender[$si]{password} = $password;
	    $sender[$si]{resource} = $resource;
	    $sender[$si]{comments} = $comments;
	    $sender[$si]{id} = $si + 1;
	    $sender[$si]{dbalias} = 'sender'.($si+1);
	    $sender[$si]{OSname} = $OSname;
	    $sender[$si]{homepath} = $homepath;
	    $si++
	}
     
	if ( $role =~ /ceiv|ciev/i ){
	    $receiver[$ri]{hostname} = $hostname;
	    $receiver[$ri]{port} = $port;
	    $receiver[$ri]{username} = $username;
	    $receiver[$ri]{password} = $password;
	    $receiver[$ri]{resource} = $resource;
	    $receiver[$ri]{comments} = $comments;
	    $receiver[$ri]{id} = $ri + 1;
    	    $receiver[$ri]{dbalias} = "receiver".($ri+1);
	    $receiver[$ri]{OSname} = $OSname;
	    $receiver[$ri]{homepath} = $homepath;
	    $ri++
	}
     
	if ( $role =~ /chivi/i ){
	    $archivist[$ai]{hostname} = $hostname;
	    $archivist[$ai]{port} = $port;
	    $archivist[$ai]{username} = $username;
	    $archivist[$ai]{password} = $password;
	    $archivist[$ai]{resource} = $resource;
	    $archivist[$ai]{comments} = $comments;
	    $archivist[$ai]{id} = $ai + 1;
	    $archivist[$ai]{OSname} = $OSname;
	    $archivist[$ai]{homepath} = $homepath;
	    $ai++
	}
    }
    close (JCLIENTS);

    die "xDash: Missing sender information in the file $filepath.\n" unless
    @sender; #exists
    die "xDash: Missing receiver information in the file $filepath.\n"
    unless @receiver; #exists 
    die "xDash: Missing archivist information in the file $filepath.\n"
    unless @archivist; #exists
    return { sender =>\@sender,
	     receiver => \@receiver, 
	     archivist => \@archivist }
}

sub trim {
    my @out=@_;
    for (@out) {
	s/^\s+//;
	s/\s+$//;
    }
    return wantarray ? @out : $out[0];
}

sub create_directory {
    
    my $jclientpath = shift;
    
    unless ( -d $jclientpath ){
	mkdir( $jclientpath ) or 
         die "Failed to create the directory $jclientpath ($!). Bye, bye...\n";
    }
}
1
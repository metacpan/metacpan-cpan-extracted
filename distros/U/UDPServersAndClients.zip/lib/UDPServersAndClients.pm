#!/usr/bin/perl

package UDPServersAndClients;

require Exporter; 

use IO::Socket::INET;

our @ISA = qw (Exporter);
our @EXPORT = qw (server_onlinecheck client_onlinecheck server_filestore client_filestore $ioserver $ioclient $ip);
our @EXPORT_OK = (@EXPORT);

our $VERSION = '1.0a'; 

our $ip = 'localhost';
our $ioserver = new IO::Socket::INET -> new (Proto=>'udp', LocalPort=>'1224');
our $ioclient = new IO::Socket::INET -> new (Proto=>'udp', PeerPort=>'1224', PeerAddr=>"$ip");

sub server_onlinecheck { 
	print "Server running. Waiting for connections. Press Control-C to exit server.\n";
	my $clientdata; 
	while () {
		
		if ($ioserver -> recv ($clientdata, 3000)) {
			print "A client has connected. Sending the client data...\n";
			$ioserver -> send ("Request Received. Server online.\n");
			} 
		} 
	}  

sub client_onlinecheck {
	my $input; 
	my $serverdata; 
	print 'If after typing message this program hangs, you will have to exit it with Control-C and will know that the server is down. Enter a message to send the server to check if server is online: ' ;
	chomp ($input = <STDIN>);
	$ioclient -> send ($input);
	$ioclient -> recv ($serverdata, 200);
	if ($serverdata) 
		{ 
		print "Server is running.\n"; 
		exit 1; 
		} 
	} 
sub server_filestore
	{ 
	my $clientdata; 
	my $filedata; 
	my $dirdata; 
	my $filetosend; 
	my @dir; 
	my @fdataspl;
	my @sentfdata; 
	my $joinedfdata; 
	my $in; 
	print "Server running. Waiting for connections. Press Control-C to exit server.\n";
	while ()
		{ 
		if ($ioserver -> recv ($clientdata, 3000) ) 
			{ 
			print "[[[INCOMING DATA]]]\n";
			} 
		if ($clientdata eq "|sendfile|")
			{ 
			print "A client is trying to send a file.\n";
			$ioserver -> recv ($filedata, 1000000000);
			@fdataspl = split (/\|\|\|/, $filedata);
			if (! @fdataspl) 
				{ 
				print "Invalid file sent\n";
				$ioserver -> send ("|fileerror|");
				next; 
				} 
			if (-e $fdataspl[0]) 
				{ 
				print "File sending to server canceled. File exists on server.\n";
				$ioserver -> send ("|fileexists|"); 
				} 
			else
				{ 
				open (F, ">$fdataspl[0]");
				print F $fdataspl[1];
				close (F);
				print "File $fdataspl[0] saved to server directory.\n";
				$ioserver -> send ("|sendsuccess|");

				} 
			} 
		if ($clientdata eq "|listfiles|")
			{ 
			print "Client requested list of files.\n";
			opendir (D, "./");
			@dir = readdir (D);
			closedir (D);
			$dirdata = join ("\n", @dir);
			$ioserver -> send ($dirdata); 
			} 
		if ($clientdata eq "|getfile|")
			{ 
			print "A client requested a file.\n";
			$ioserver -> recv ($filetosend, 1000); 
			if (-e $filetosend and ! -d $filetosend)
				{
				open (FTS, $filetosend);
				@sentfdata = <FTS>; 
				close (FTS);
				$joinedfdata = join ('', @sentfdata); 
				print "Sending file...\n";
				$ioserver -> send ($joinedfdata); 
				}
			else
				{ 
				print "Client specified invalid file name to get.\n";
				$ioserver -> send ("|filenoexist|"); 
				next;  
				} 
			} 
		} 
	} 

sub client_filestore
	{ 
	my $recv1;
	my $recv2;
	my $recv3;
	my $filein; 
	my $filein2; 
	my $filein3; 
	my $overwritetogg;
	my $filedata; 
	my $filedata2; 
	my $genin; 
	my @filedata; 
	my $joinedfdata; 
	my $sendrec; 
	print "Welcome...\n";
	while ()
		{ 
		print "Enter '/get' to get a file or '/list' for a list of files on the server.\nEnter '/send' to send a file to the server.\nEnter '/ls' to list local files.\nEnter a blank line to exit. \n";		
		chomp ($genin = <STDIN>);
		if (! $genin) 
			{ 
			last; 
			} 
		elsif ($genin eq '/list')
			{
			$ioclient -> send ("|listfiles|"); 
			$ioclient -> recv ($recv1, 4000);
			print "Files on the server:\n";
			print "$recv1\n"; 
			} 
		elsif ($genin eq '/get')
			{ 
			print "Enter the name of a file on the remote server to get: ";
			chomp ($filein = <STDIN>);
			if ($filein eq "." or $filein eq "..")
				{ 
				print "Those are special files and cannot be gotten.\n";
				next; 
				} 
			if ($filein)
				{ 
				$ioclient -> send ("|getfile|");  
				$ioclient -> send ($filein); 
				print "Receiving file...\n";
				$ioclient -> recv ($filedata, 1000000000);
				if ($filedata eq "|filenoexist|") 
					{ 
					print "File does not exist on the remote server or file is a directory. Try again.\n";
					print "Operation canceled.\n";
					next; 
					}
				else
					{ 
					print "Enter filename for your file from the server: ";
					chomp ($filein = <STDIN>);
					if ($filein eq "." or $filein eq ".." or -d $filein)
						{ 
						print "File is a directory. You cannot overwrite it.\n";
						print "Operation canceled.\n";
						next;
						} 
					if (-e $filein) 
						{ 
						print "File exists. Overwrite? (y/n) "; 
						chomp ($overwritetogg = <STDIN>);
						if ($overwritetogg eq 'y')
							{
							open (F, ">$filein");
							print F $filedata; 
							close (F);						
							print "File saved as $filein.\n";
							}
						else
							{ 
							print "Operation canceled.\n";
							next; 
							} 
						} 
					else
						{ 
						open (F, ">$filein");
						print F $filedata; 
						close (F);						
						print "File saved as $filein.\n";
						} 

					} 

				} 

			} 
		elsif ($genin eq '/send')
			{ 
			print "Enter the file name of the file you wish to send: ";
			chomp ($filein2 = <STDIN>);
			if (! -e $filein2 or -d $filein2 or ! $filein2) 
				{ 
				print "File does not exist or is a directory. Try again.\n";
				print "Operation canceled.\n";	
				next; 
				} 
			print "Enter what you want to call the file on the remote server: ";
			chomp ($filein3 = <STDIN>);
			if (! $filein3)
				{ 
				print "Please specify a file name. Try again.\n";
				print "Operation canceled.\n";
				next; 
				} 
			$ioclient -> send ("|sendfile|"); 
			open (F, $filein2);
			@filedata = <F>; 
			close (F);
			$joinedfdata = join ('', @filedata);
			$ioclient -> send ("$filein3|||$joinedfdata");
			$ioclient -> recv ($sendrec, 1000); 
			if ($sendrec eq "|sendsuccess|")
				{ 
				print "File saved to server successfully.\n";
				} 
			elsif ($sendrec eq "|fileerror|") 
				{ 
				print "A general error occured. Try again.\n";
				print "Operation canceled.\n";
				} 
			else
				{ 
				print "File exists on server. Try a different file name.\n";
				print "Operation canceled.\n";
				} 
			} 
		elsif ($genin eq '/ls')
			{
			my @dir; 
			my $j; 
			opendir (D, "./");
			@dir = readdir (D);
			closedir (D);
			$j = join ("\n", @dir); 
			print "Local files:\n";
			print "$j\n"; 
			}
		else
			{ 
			print "Invalid command.\n";
			} 

		} 	
	} 
1;  

__END__

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

UDPServersAndClients - A Module that is four server/client rograms. 

=head1 SYNOPSIS

  use UDPServersAndClients;

=head1 DESCRIPTION

This module exports a variable, $ip that you should set as the ip of the computer where you are running the server before running any of the below client functions to connect to that computer. 

This module exports four subroutines which do not accept any values or return any: 

1. server_onlinecheck ();  -- this subroutine runs a server that will allow anyone running the client function, client_onlinecheck (); to check if the server is online. This can be useful if you have a server you want to check using UDP. 

2. server_filestore ();  -- this subroutine runs a server that will allow anyone running the client function, client_filestore(); to transfer files to and get files from the server's current directory (the directory of your script that accesses server_filestore();). 

3. client_onlinecheck ();  -- this subroutine has already been explained. Just run it.

4. client_filestore ();  -- Ditto.

Note: the port used for data transfer is 1234 so it must be available for this module to work. 

Note: this module requires the module IO::Socket::INET.
=head1 SEE ALSO

IO::Socket and IO::Socket::INET 

=head1 AUTHOR

Robin Bank, E<lt>webmaster@infusedlight.net<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Robin Bank

LICENSE: I don't care at all. 

=cut

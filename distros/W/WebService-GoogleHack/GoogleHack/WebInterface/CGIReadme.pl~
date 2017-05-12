=head1 WebService::Google-Hack Web Installation Guide

=head1 SYNOPSIS

The WebService::Google-Hack web interface provides an easy to use interface
for some of the features of WebService::Google-Hack.

=head1 DESCRIPTION

To install the interface please follow these steps:

The web interface for WebService::Google-Hack has been implemented such that, there needs to be a WebService::Google-Hack Server running in the background, so that the client file google_hack.cgi can connect to the server on a specific port, and retrieve results.

=head1 Installation Guide

1) Create a directory named ghack in your cgi-bin directory (Where all your cgi files reside). So it should be something like:

/webspace/cgi-bin/ghack

2) Next, copy the file named google_hack.cgi, which is given with the 
distribution of the google-hack package into your cgi-bin/ghack/ directory.

3) Open the google_hack.cgi file (The google_hack.cgi file is in the WebInterface directory of GoogleHack. For eg: WebService/GoogleHack/WebInterface), 
and change the lib path to the path where WebService::GoogleHack has been 
installed on your machine.

4) Now, open the ghack_server.pl file (which is also given in the  WebInterface directory of GoogleHack),

5) In the ghack_server.pl file, change the following variables accordingly:

Basedir should be the path to the cgi-bin directory in which google_hack.cgi 
resides.

$BASEDIR = '/webspace/cgi-bin/ghack'; 

The localport should be a number above 1024, and less than around 66,000. Make
 sure that localport number is the same on both the client and server side.

$localport = 32983;


$lock_file = "$BASEDIR/ghack_server.lock";

$error_log = "$BASEDIR/error.log";


The lockfile & error_log variables will remain the same. 

6) Now, open the google_hack.cgi  file (which is also given in the  WebInterface directory of GoogleHack),

Set the remote_host, and remote_port variables to the correct values.

The remote host will be the IP address of the machine where the google_hack server will be running.

$remote_host = '';

The remote port needs to be the same as the $localport variable in ghack_server.pl
$remote_port = '';

7)If your ghack server is running behind a firewall, you will need to
edit the file /etc/sysconfig/iptables to allow clients to connect to the machine through the port you had given.  There is a line that looks like this:

-A RH-Firewall-1-INPUT -p tcp --dport XXXXX -j ACCEPT

Where XXXXX is the port that your client will be connecting to (the value of $localport in ghack_server.pl).

The change would not take effect until the host machine is rebooted. If you do not have permissions to reboot, please issue the following command:
 
/sbin/iptables -I RH-Firewall-1-INPUT 10 -p tcp --dport XXXXX -j ACCEPT

Where XXXXX is the port that your client will be connecting to (the value of $localport in ghack_server.pl).

Now start the server by running the ghack_server.pl as you would run a 
regular perl file.
 
You should now be able to use the web interface.

=head1 AUTHOR

Ted Pedersen, E<lt>tpederse@d.umn.eduE<gt> 

Pratheepan Raveendranathan, E<lt>rave0029@d.umn.eduE<gt> 

Date 11/08/2004

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003 by Pratheepan Raveendranathan, Ted Pedersen

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to

The Free Software Foundation, Inc.,
59 Temple Place - Suite 330,
Boston, MA  02111-1307, USA.

=cut









#!/usr/bin/perl -w

# $Id: Omnitel.pm,v 1.1 2003/03/21 00:10:44 eim Exp $

#############################################################################
#                                                                           #
#   IMPORTANT NOTE                                                          #
#                                                                           #
#   !!! THE AUTHOR IS ==NOT== RESPONSIBLE FOR ANY USE OF THIS PROGRAM !!!   #
#                                                                           #
#   GPL LICENSE                                                             #
#                                                                           #
#   This program is free software; you can redistribute it and/or modify    #
#   it under the terms of the GNU General Public License as published by    #
#   the Free Software Foundation; either version 2 of the License, or       #
#   (at your option) any later version.                                     #
#                                                                           #
#   This program is distributed in the hope that it will be useful,         #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of          #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           #
#   GNU General Public License for more details.                            #
#                                                                           #
#   You should have received a copy of the GNU General Public License       #
#   along with this program; if not, write to the Free Software             #
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston,                   #
#   MA  02111-1307 USA                                                      #
#                                                                           #
#############################################################################

#
# ABOUT THIS MODULE
#
# This WWW-SMS module provides an interface to the Omnitel SMS gateway
# available over at http://www.omnitel.it, all is done in two steps:
#
# 	STEP 1		Authenticate and login.
# 	STEP 2		Send the SMS message.
#
# Here is a list af all the Italian operators supported by this gateway:
# 
#	OMNITEL
#	340, 347, 348, 349
#
# The maximal length of each message is 1200 chars, this is quite cool.
#
# Note that $debug=1 will print out all the HTML source code of the portal
# the best thing you can do is to redirect the debugging output to a file.
#
# Doc note: The Perl LWP (libwww-perl) documentation is avaiable in your
# local perldoc repository, see: % perldoc lwpcook it's always usefull.
#
# This packages was written by: Ivo Mario <eim@users.sourceforge.net>
# and was last modified: $Date: 2003/03/21 00:10:44 $ 
#


#
# LIBS AND CONFIGS
#

package WWW::SMS::Omnitel;
use Telephone::Number;
require Exporter;

$VERSION = '1.00';
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(@PREFIXES _send MAXLENGTH);
@PREFIXES = (Telephone::Number->new('39', [
		qw(340 347 348 349)
		], undef)
);


#
# SUBROUTINES
#

# 
# Message max length defintion.
#
sub MAXLENGTH () {1200}

# 
# Error handling functions.
# 
sub hnd_error {
	$_ = shift;
	$WWW::SMS::Error = "Failed at step $_ of module Omnitel.pm\n";
	return 0;
}

#
# Operations to send the SMS message.
#
sub _send {

	use HTTP::Request::Common qw(GET POST);				# the base LWP stuff
	use LWP::UserAgent;						# the LWP user agent
	use HTTP::Cookies;						# cookie support in LWP
	my $self = shift;						# shift the self array
	my $debug = 0;							# debug option
   
   	# cut message if it's too long
	if (length($self->{smstext})>MAXLENGTH) {
		$self->{smstext} = substr($self->{smstext}, 0, MAXLENGTH - 1);
	}

	my $ua = LWP::UserAgent->new;					# create user agent object
	$ua->agent('Mozilla/5.0');					# user agent properties
	$ua->proxy('http', $self->{proxy}) if ($self->{proxy});		# proxy settings if available
	$ua->cookie_jar(HTTP::Cookies->new(				# user agent cookie settings
			file => $self->{cookie_jar},			# saves to lwpcookies.txt
			autosave => 1					# save automaticly
		)
	);
	
	#
	# STEP 1
	#
	# Let's authenticate and login, cookies are optional, sessions are serverside.
	# 
	my $step = 1;

	$req = POST 'http://www.areaprivati.190.it/_mem_bin/verifpwd.asp',
		[
			ApriPopUp => '0',
			username => $self->{username},
			password => $self->{passwd},
			URL => '',
			HomePage => 'NO',
			'19A' => 'YES'
		];

        $file = $ua->request($req)->as_string;

	if ($debug) {
		print "\n\n#####################\n";
		print "# DEBUG FOR STEP: $step #\n";
		print "#####################\n\n";
		print $file;
	}

	return &hnd_error($debug ? "$step ($file)" : $step)
		unless $file =~ /exch.vodafoneomnitel.it/;

	#
	# STEP 2
	# 
	# Now let's send the SMS message, folks. Here wo go, woheeeee!
	# 
	$step++;

	$req = POST 'http://freesms.190.it/190personal/sms_hp_send.asp',
		[
			num => $self->{prefix} . $self->{telnum},
			msg => $self->{smstext},
			Prov => 1
		];
	
	$file = $ua->simple_request($req)->as_string;

	if ($debug) {
		print "\n\n#####################\n";
		print "# DEBUG FOR STEP: $step #\n";
		print "#####################\n\n";
		print $file;
	}

	return &hnd_error($debug ? "$step ($file)" : $step)
		unless $file =~ /SMS_HP_SendOk.asp\?nsms=/;
	
	1;
}

1;

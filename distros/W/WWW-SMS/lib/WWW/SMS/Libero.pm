#!/usr/bin/perl -w

# $Id: Libero.pm,v 1.4 2003/03/20 00:07:32 eim Exp $

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
# This WWW-SMS module provides an interface to the Libero/Wind SMS gateway
# available over at http://windeureka.libero.it, all is done in two steps:
#
# 	STEP 1		Authenticate and login.
# 	STEP 2		Send the SMS message.
#
# Here is a list af all the Italian operators supported by this gateway:
# 
#	WIND			TIM
#	320, 328, 329		330, 333, 334, 335, 336, 337, 338, 339, 360, 368
#		
#	OMNITEL			BLU
#	340, 347, 348, 349	380, 388, 389
#
# Note that $debug=1 will print out all the HTML source code of the portal
# the best thing you can do is to redirect the debugging output to a file.
#
# Doc note: The Perl LWP (libwww-perl) documentation is avaiable in your
# local perldoc repository, see: % perldoc lwpcook it's always usefull.
#
# This packages was written by: Ivo Mario <eim@users.sourceforge.net>
# and was last modified: $Date: 2003/03/20 00:07:32 $ 
#


#
# LIBS AND CONFIGS
#

package WWW::SMS::Libero;
use Telephone::Number;
require Exporter;

$VERSION = '1.00';
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(@PREFIXES _send MAXLENGTH);
@PREFIXES = (Telephone::Number->new('39', [
		qw(320 328 329 330 333 334 335 336 337 338 339 360 368 340 347 348 349 380 388 389)
		], undef)
);


#
# SUBROUTINES
#

# 
# Message max length defintion.
#
sub MAXLENGTH () {96}

# 
# Error handling functions.
# 
sub hnd_error {
	$_ = shift;
	$WWW::SMS::Error = "Failed at step $_ of module Libero.pm\n";
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

	$req = POST 'http://windeureka.libero.it/sms/inviosms.php',
		[
			telefono => '',
			PrefissoBox => '',
			telefonoBox => '',
			Testo => '',
			tipo => '',
			username => $self->{username},
			pwd => $self->{passwd},
			dominio => 'libero',
			Act_Login => ''
		];

        $file = $ua->request($req)->as_string;

	if ($debug) {
		print "\n\n#####################\n";
		print "# DEBUG FOR STEP: $step #\n";
		print "#####################\n\n";
		print $file;
	}

	return &hnd_error($debug ? "$step ($file)" : $step)
		unless $file =~ /COMPONI IL MESSAGGIO/;

	#
	# STEP 2
	# 
	# Now let's send the SMS message, folks. Here wo go, woheeeee!
	# 
	$step++;

	$req = POST 'http://windeureka.libero.it/sms/inviasms.php',
		[
			telefono => $self->{prefix} . $self->{telnum},
			Testo => $self->{smstext},
			Counter => 92,
			tipo => 'immediato',
			ore => '',
			minuti => '',
			giorno => ''
		];
	
	$file = $ua->simple_request($req)->as_string;

	if ($debug) {
		print "\n\n#####################\n";
		print "# DEBUG FOR STEP: $step #\n";
		print "#####################\n\n";
		print $file;
	}

	return &hnd_error($debug ? "$step ($file)" : $step)
		unless $file =~ /SMS inviati correttamente/;
	
	1;
}

1;

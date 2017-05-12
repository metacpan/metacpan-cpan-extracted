#!/usr/bin/perl -w
# option -w == warnings ON

# CVS related code
# $Id: Gomobile.pm,v 1.5 2002/12/28 17:32:17 eim Exp $

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


#////////////////////////////////////////#
#   A B O U T  T H I S  P A C K A G E    #
#////////////////////////////////////////#

# This is a module for www.gomobile.ch you must have a valid user account
# at www.gomobile.ch which will provide you with login and password.

# You can get a free user account on the www.gomobile.ch website,
# furthermore you'll be able to send SMS all over the world without
# per day SMS limits, I would say this is quite cool.

# Note that $debug=1 will print out all the HTML source code of the portal
# the best thing you can do is to redirect the debugging output to a file.

# Doc note: The Perl LWP (libwww-perl) documentation is avaiable in your
# local perldoc repository, see: % perldoc lwpcook it's always usefull.

# This packages was written by: Ivo Mario <eim@eimbox.org>
# and was last modified: $Date: 2002/12/28 17:32:17 $


#////////////////////////////////////////#
#     L I B S  A N D  C O N F I G S      #
#////////////////////////////////////////#

# name of this package
package WWW::SMS::Gomobile;

# other modules we need
use Telephone::Number;
require Exporter;

# definitions
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(@PREFIXES _send MAXLENGTH);
@PREFIXES = (Telephone::Number->new('43', [ qw(676 650 699 664) ], undef));
$VERSION = '1.00';				# package version


#////////////////////////////////////////#
#         S U B R O U T I N E S          #
#////////////////////////////////////////#

# subroutine to define max message length
sub MAXLENGTH () {500}


# subroutine to handle errors
sub hnd_error {
	$_ = shift;
	$WWW::SMS::Error = "Failed at step $_ of module Gomobile.pm\n";
	return 0;
}


# subroutine to send SMS
sub _send {

	# external libraries
	use HTTP::Request::Common qw(GET POST);
	use LWP::UserAgent;				# the LWP user agent
	use HTTP::Cookies;				# cookie support in LWP

	# private vars
	my $self = shift;				# no idea actually
	my $debug = 0;					# enable debug
    
	# check if message is too long
	if (length($self->{smstext})>MAXLENGTH) {
		
		# cut the message
		$self->{smstext} = substr($self->{smstext}, 0, MAXLENGTH - 1);
	}

	# create user agent object
	my $ua = LWP::UserAgent->new;

		# user agent properties
		$ua->agent('Mozilla/5.0');
		$ua->proxy('http', $self->{proxy}) if ($self->{proxy});

		# user agent cookie settings
		$ua->cookie_jar(HTTP::Cookies->new(

				file => $self->{cookie_jar},	# saves to lwpcookies.txt
				autosave => 1			# save automaticly
			)
		);

	
	# =======================
	# STEP 1
	# Let's log on the portal
	# =======================
        
	my $step = 1;	# define the step
	
	# define the LWP request
	my $req = POST 'http://www.gomobile.ch/Portal?cmd=procLogin',
			[
				Referer => 'http://www.gomobile.ch/Portal?cmd=GenHomepage',
				Host => 'www.gomobile.ch',
				cmd => 'procLogin',
				userName => $self->{username},
				password => $self->{passwd}
			];
	

	# execute the LWP request
        my $file = $ua->request($req)->as_string;

	# if we are in debugging mode
	if ($debug) {

		print "\n\n#####################\n";	# print debug title
		print "# DEBUG FOR STEP: $step #\n";	# print debug title
		print "#####################\n\n";	# print debug title
		print $file;				# print debug infos
	}

	# check if we arrived on the everyday startpage
	# if not so, well... report an error and exit !
	# return &hnd_error($debug ? "$step ($file)" : $step)
		# unless $file =~ m{ no-checks-here }i;


	# ==================================================
	# STEP 2
	# Ok folks, lets send out the SMS, it quite rox, yes
	# ==================================================

	$step++;	# increment to next step

	# define the LWP request
	$req = POST 'http://www.gomobile.ch/Portal',
		[
			Host => 'www.movilnets.net',
			Referer => 'http://www.gomobile.ch/Portal?cmd=startFreeSMS',
			cmd => 'procGenSendFreeSMS',
			abbreviations => '',
			contacts => '',
			abbreviationPage => 1,
			address => '00' . $self->{intpref} . $self->{prefix} . $self->{telnum},
			abbreviation => 'Goodbye+for+ever%2C+boss%21+Just+won+the+lottery.',
			smstext => $self->{smstext},
			nSMS => 1,
			emoticonSelection => '%3A%29',
			smil=> ''
		];

	# execute the LWP request
        $file = $ua->request($req)->as_string;

	# if we are in debugging mode
	if ($debug) {

		print "\n\n#####################\n";	# print debug title
		print "# DEBUG FOR STEP: $step #\n";	# print debug title
		print "#####################\n\n";	# print debug title
		print $file;				# print debug infos
	}

	# check if the message was sent successfully if not report an error and exit.
	return &hnd_error($debug ? "$step ($file)" : $step)
		unless (
			$file =~ /Your text message has been successfully sent to/
			|| $file =~ /Ihre Nachricht wurde erfolgreich gesendet an/
			|| $file =~ /stato trasmesso con successo a/
			|| $file =~ /avec succ/
		);
	
	# clear the cookie
	$ua->cookie_jar->clear('www.gomobile.ch');

	1;
}

1;

#!/usr/bin/perl -w
# option -w == warnings ON

# CVS related code
# $Id: Everyday.pm,v 1.8 2003/03/20 00:10:24 eim Exp $

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

# This is a module for www.everyday.com you must have a valid user account
# at www.everyday.com which will provide you with login and password.

# Furthermore www.everyday.com allows you to send 10 SMS messages per day,
# and to stress much more his users there are so called "pepites" which you
# need to send SMS message, no idea how to get them, read on their site.

# I've done some test and it seems that www.everyday.com doesn't
# support proxies so don't use a proxy here, SMS delivering will fail.

# Note that $debug=1 will print out all the HTML source code of the portal
# the best thing you can do is to redirect the debugging output to a file.

# Doc note: The Perl LWP (libwww-perl) documentation is avaiable in your
# local perldoc repository, see: % perldoc lwpcook it's always usefull.

# This packages was written by: Ivo Mario <eim@eimbox.org>
# and was last modified: $Date: 2003/03/20 00:10:24 $ 


#////////////////////////////////////////#
#     L I B S  A N D  C O N F I G S      #
#////////////////////////////////////////#

# name of this package
package WWW::SMS::Everyday;

# other modules we need
use Telephone::Number;
require Exporter;

# definitions
$VERSION = '1.00';
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(@PREFIXES _send MAXLENGTH);
@PREFIXES = (Telephone::Number->new('39', [
		qw(320 328 329 330 333 334 335 336 337 338 339 360 368 340 347 348 349 380 388 389)
		], undef)
);


#////////////////////////////////////////#
#         S U B R O U T I N E S          #
#////////////////////////////////////////#

# subroutine to define max message length
sub MAXLENGTH () {127}


# subroutine to handle errors
sub hnd_error {
	$_ = shift;
	$WWW::SMS::Error = "Failed at step $_ of module Everyday.pm\n";
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

	
	# ============================================================
	# STEP 1
	# We just connect to bypass the browser check and get a cookie
	# ============================================================
        
	my $step = 1;	# define the step
	
	# First of all we need to set this cookie in order
	# to pass everday's javascript browser detection, it does his job.
	$ua->cookie_jar->set_cookie('0', 'BrowserDetect', 'passed', "/", ".everyday.com");
	
	# define the LWP request
	my $req = GET 'http://www.everyday.com/login.phtml';

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
	return &hnd_error($debug ? "$step ($file)" : $step)
		unless $file =~ m{<a href="http://www.register.everyday.com/">}i;


	# =====================================================
	# STEP 2
	# Ok folks, once fetched the cookie it's time to log in
	# =====================================================

	$step++;	# increment to next step

	# define the LWP request
	$req = POST 'http://www.everyday.com/login.phtml',
		[
			login_username => $self->{username},
			login_password => $self->{passwd}
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

	# check if we successfully logged in,
	# if not so, report an error and exiti !
	return &hnd_error($debug ? "$step ($file)" : $step)
		unless $file =~ m{path=/; domain=.everyday.com}i;


	# ==============================================
	# STEP 3
	# Let's finaly send the SMS message, jope dooo !
	# ==============================================

	$step++;	# increment to next step

	# define the LWP request
	$req = POST 'http://sms.everyday.com/index.phtml',
		[
			gsmnumber => $self->{intpref} . $self->{prefix} . $self->{telnum},
			message => $self->{smstext},
			send_sms => 1,
		];

	# execute the LWP request
	$file = $ua->simple_request($req)->as_string;

	# if we are in debugging mode
	if ($debug) {

		print "\n\n#####################\n";	# print debug title
		print "# DEBUG FOR STEP: $step #\n";	# print debug title
		print "#####################\n\n";	# print debug title
		print $file;				# print debug infos
	}

	return &hnd_error($debug ? "$step ($file)" : $step)
		
		# This is not the best check we can do but
		# it should work for international everyday sites
		# unless $file =~ m{<title>Everyday.com - SMS</title>}i;

		unless (
			$file =~ /SMS inviato!/
			|| $file =~ /a smistarlo/
		);

	1;
}

1;

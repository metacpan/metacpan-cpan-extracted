package yesssSMS;

use 5.014002;
use strict;
use warnings;
use HTML::Parser;
use LWP::UserAgent;
use HTTP::Cookies;


require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use yesssSMS ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '2.00';

sub new
{
	my $self = {};
	$self->{LOGINSTATE} = 0;

	bless ($self);
	return $self;
}

sub login
{
	my $self = shift;
	($self->{TELNR},
		$self->{PASS})=@_;

	# don't login if logged in...
	if ($self->{LOGINSTATE} == 1)
	{
		$self->{LASTERROR}='Cannot login when already logged in';
		$self->{RETURNCODE}=1;
		return 1;
	}

	# Cookies are needed
	$self->{UA} = LWP::UserAgent->new;
	$self->{UA}->cookie_jar(HTTP::Cookies->new);

	# go to start page
	#$self->{CONTENT}=$self->{UA}->get("https://www.yesss.at/");
	$self->{CONTENT}=$self->{UA}->get("https://www.yesss.at/kontomanager.at/");

	# if there was an error on the start page, stop
	if (!($self->{CONTENT}->is_success))
	{
		$self->{LASTERROR}='Error loading startpage of YESSS!';
		$self->{RETURNCODE}=2;
		return 2;
	}

	# do the login post
	#$self->{CONTENT}=$self->{UA}->post("https://www.yesss.at/kontomanager.php",{'login_rufnummer' => $self->{TELNR},'login_passwort' => $self->{PASS}});
	$self->{CONTENT}=$self->{UA}->post("https://www.yesss.at/kontomanager.at/index.php",{'login_rufnummer' => $self->{TELNR},'login_passwort' => $self->{PASS}});

	#print "Returncode during login: ".$self->{CONTENT}->code."\n";
	#print "Content during login: ".$self->{CONTENT}->decoded_content."\n";

	# successful login results in redirect
	if (!($self->{CONTENT}->is_redirect))
	{
		$self->{LASTERROR}='Error sending credentials!';
		$self->{RETURNCODE}=3;
		return 3;
	}

	# usually, a redirect is replied
	while ($self->{CONTENT}->is_redirect)
	{
		# follow redirect
		$self->{CONTENT}=$self->{UA}->post($self->{CONTENT}->header("Location"),{'login_rufnummer' => $self->{TELNR},'login_passwort' => $self->{PASS}});

		# if there was an error during redirect, stop
		if (!($self->{CONTENT}->is_success))
		{
			$self->{LASTERROR}='Error during post-login redirect';
			$self->{RETURNCODE}=4;
			print $self->{CONTENT}->status_line;
			return 4;
		}
	}
	$self->{LOGINSTATE}=1;
	$self->{LASTERROR}='Login successful';
	$self->{RETURNCODE}=0;
	return 0;
}

sub sendmessage
{
	my $self = shift;
	my ($telnr,$message)=@_;

	# only send message when login was successful
	if ($self->{LOGINSTATE} == 0)
	{
		$self->{LASTERROR}='Not logged in while trying to send a message';
		$self->{RETURNCODE}=1;
		return 1;
	}

	#if (length($message)>160)
	#{
	#	$self->{LASTERROR}='Shortmessage too long';
	#	$self->{RETURNCODE}=2;
	#	return 2;
	#}
	if (!($telnr=~/^00/) || (length($telnr)<14))
	{
		$self->{LASTERROR}='Invalid destination (not Austria or too short)';
		$self->{RETURNCODE}=3;
		return 3;
	}

	# go to correct menu item
	$self->{CONTENT}=$self->{UA}->post("https://www.yesss.at/kontomanager.at/websms.php");

	# stop on error
	if (!($self->{CONTENT}->is_success))
	{
		$self->{LASTERROR}='Error while selecting SMS menu';
		$self->{RETURNCODE}=4;
		return 4;
	}

	# try to send message
	$self->{CONTENT}=$self->{UA}->post("https://www.yesss.at/kontomanager.at/websms_send.php",{'to_netz' => 'a','to_nummer' => $telnr,'nachricht' => $message});

	# stop on error
	if (!($self->{CONTENT}->is_success))
	{
		$self->{LASTERROR}='Error while sending message';
		$self->{RETURNCODE}=5;
		return 5;
	}

	$self->{LASTERROR}='Message sent successfully';
	$self->{RETURNCODE}=0;
	return 0;
}

sub getLoginstate
{
	my $self = shift;
	
	return $self->{LOGINSTATE};
}

sub logout
{
	my $self = shift;

	# don't logout if not logged in...
	if ($self->{LOGINSTATE} == 0)
	{
		$self->{LASTERROR}='Cannot logout when not logged in.';
		$self->{RETURNCODE}=1;
		return 1;
	}

	# post the logout url
	$self->{CONTENT}=$self->{UA}->post("https://www.yesss.at/kontomanager.at/index.php?dologout=1");

	# if there was an error during logout, stop
	if (!($self->{CONTENT}->is_success))
	{
		$self->{LASTERROR}='Error during logout.';
		$self->{RETURNCODE}=2;
		return 2;
	}

	# reset LOGINSTATE
	$self->{LOGINSTATE}=0;
	$self->{LASTERROR}='Logout successful';
	$self->{RETURNCODE}=0;
	return 0;
}

sub getLastResult
{
	my $self = shift;

	return $self->{RETURNCODE};
}

sub getLastError
{
	my $self = shift;

	return $self->{LASTERROR};
}

sub getContent
{
	my $self = shift;

	return $self->{CONTENT};
}

sub DESTROY
{
	my $self = shift;
	if ($self->{LOGINSTATE}==1)
	{
		$self->logout();
	}
}

1;
__END__
# Below is the documentation for the module.

=head1 NAME

yesssSMS - Send text messages to mobile phones through the website of yesss!

=head1 SYNOPSIS

 use yesssSMS;
 use strict;
 
 # create SMS object
 my $sms=yesssSMS->new();
 
 # login to the site with your phone number and the password
 $sms->login("06811234567","MyPassword");
 
 # check whether login was successful
 if ($sms->getLastResult!=0)
 {
 	print STDERR "Error during login: ".$sms->getLastError()."\n";
 }
 
 # send a text message
 $sms->sendmessage('00436817654321','Just testing...');
 
 # check whether the message was delivered
 if ($sms->getLastResult!=0)
 {
 	print STDERR "Error during sendmessage: ".
		$sms->getLastError()."\n";
 }
 
 # logout of site
 $sms->logout();
 
 # check whether login was successful
 if ($sms->getLastResult!=0)
 {
 	print STDERR "Error during logout: ".$sms->getLastError()."\n";
 }


=head1 DESCRIPTION

Objects of the yesssSMS class are only able to send text messages to
mobile phones through the website of yesss!. To be able to use this
service, you need to have an account at yesss! (a mobile phone). The
target phone number must be provided with the international code starting
with 00 (e.g. 0043 for Austria). The text messages are limited to 160 
characters.

This module requires following modules:

 * strict
 * warnings
 * HTML::Parser
 * LWP::UserAgent
 * HTTML::Cookies

=head1 METHODS

The following method is used to construct a new yesssSMS object:

=over

=item $sms = yesssSMS->new()

=back


The following method logs into the website with your phone number and the password:

=over

=item $sms->login(MyPhonenumber,Password)

=back

The following method sends a text message if a login was successful before:

=over

=item $sms->sendmessage(OtherPhonenumer,Textmessage)

It is possible to send multiple text messages during one login.

=back

The following method logs out of the website of yesss!

=over

=item $sms->logout()

=back

The following method returns the current login state:

=over

=item $sms->getLoginstate()

0 means: not logged in

1 means: logged in

=back

The following method returns the result of the last operation:

=over

=item $sms->getLastResult()

0 means: successful

>0 means: an error occured

=back

The following method returns a textual description of the result of the
last operation:

=over

=item $sms->getLastError()

=back


The following method returns the LWP::UserAgent last return content:

=over

=item $sms->getContent()

=back

=head1 HISTORY

=over 8

=item 1.00

Original version

=item 2.00

Adopted for the new website being online since August 1st, 2014

=back

=head1 AUTHOR

Armin Fuerst

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Armin Fuerst

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut

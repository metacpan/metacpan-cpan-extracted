#!/usr/bin/perl

use strict;
use Yahoo::BBAuth;

# Test the Photos API using BBauth
# Author: Jason Levitt

# Display errors in the web browser, if possible
use CGI::Carp qw(fatalsToBrowser);

# Make sure standard output headers are sent
use CGI qw(:all);
print header();

# Put your BBauth appid and secret here
my $bbauth = Yahoo::BBAuth->new(
    appid  => 'ZUPN1wTIxxxxxxxxxxxxxxxEIEJBc_V26',
    secret => 'e7b7f0xxxxxxxxxxxxxxxxxxx0a10439',
);

# Retrieve CGI environment variables
my $grabcgi = CGI->new;

# If the token is not in the environment, we're not coming back from a BBauth authorization
if (!defined($grabcgi->param('token'))) {
   my $send_userhash = 1;
   my $appdata = 'someappdata';
   # Display the BBauth login link for the user
   print '<h1>Test Yahoo! Photos Using BBauth</h1>';
   print '<b>You have not authorized access to your Yahoo! Photos account yet.</b><br>';
   printf '<a href="%s">Click here to authorize</a>', $bbauth->auth_url(
          send_userhash  => '1',
          appdata => 'someappdata',
          );  
} else  {
    
  # Validate the BBauth attempt
  if (!$bbauth->validate_sig()) {
      print '<h2>Authentication Failed. Error is: </h2>'.$bbauth->{sig_validation_error};
      exit(0);
  }
  
  print '<h2>BBauthAuthentication Successful</h2>';
  print '<b>Userhash is: '.$bbauth->{userhash}.'</b><br>';
  print '<b>appdata is: '.$bbauth->{appdata}.'</b><br>';
  
  # Make an authenticated web services call
  my $url = 'http://photos.yahooapis.com/V3.0/listAlbums?';
  my $xml = $bbauth->auth_ws_get_call($url);
  
  if (!$xml) {
      print '<h2>Web services call failed. Error is:</h2> '. $bbauth->{access_credentials_error};
      exit(0);
  }
  
  print '<b>timeout is: '.$bbauth->{timeout}.'<br>'; 
  print 'token is: '.$bbauth->{token}.'<br>';
  print 'WSSID is: '.$bbauth->{WSSID}.'<br>'; 
  print 'Cookie is: '.$bbauth->{cookie}.'<br></b>';
  
  # Alter the XML so that we can display it in the user's browser without it being
  # interpreted as HTML markup
  my %entities = ( "<"=>"&lt;", ">"=>"&gt;", "&"=>"&amp;" );
  while (my ($k, $v) = each(%entities)) {
	$xml =~ s/$k/$v/g;
  }

  print '<br><b>The web service call appeared to succeed. Here is the XML response showing your Y! Photo Albums:</b><br><br> '.$xml;
  
}

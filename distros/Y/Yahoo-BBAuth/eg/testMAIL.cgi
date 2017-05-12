#!/usr/bin/perl

# Test the Mail API using BBauth
# Author: Jason Levitt

use strict;
use Yahoo::BBAuth;
use Data::Dumper;

# Display errors in the web browser, if possible
use CGI::Carp qw(fatalsToBrowser);

# Make sure standard output headers are sent
use CGI qw(:all);
print header();

# Put your BBauth appid and secret here
my $bbauth = Yahoo::BBAuth->new(
    appid  => 'Mai6nmbxxxxxxxxxxxxxxxxxVXmhAWSrMXr',
    secret => '2f8c085baxxxxxxxxxxxxxxxxxxx0c25501f',
);

# Retrieve CGI environment variables
my $grabcgi = CGI->new;

# If the token is not in the environment, we're not coming back from a BBauth authorization
if (!defined($grabcgi->param('token'))) {
   my $send_userhash = 1;
   my $appdata = 'someappdata';
   # Display the BBauth login link for the user
   print '<h1>Test Yahoo! Mail API Using BBauth</h1>';
   print '<b>You have not authorized access to your Yahoo! Mail account yet.</b><br>';
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
  print '<strong>Userhash is: '.$bbauth->{userhash}.'</strong><br>';
  print '<strong>appdata is: '.$bbauth->{appdata}.'</strong><br>';
  
  # Make an authenticated web services call
  
  my $json = $bbauth->make_jsonrpc_call('ListFolders', [{}] );
  
  if (!$json) {
      print '<h2>Web services call failed. Error is:</h2> '. $bbauth->{access_credentials_error};
      exit(0);
  }
  
  print '<b>timeout is: '.$bbauth->{timeout}.'<br>'; 
  print 'token is: '.$bbauth->{token}.'<br>';
  print 'WSSID is: '.$bbauth->{WSSID}.'<br>'; 
  print 'Cookie is: '.$bbauth->{cookie}.'<br></b>';

  print '<br><b>The JSON-RPC call appeared to succeed. Here is a Perl data structure showing the output of the ListFolders method:</b><br><br> ';
  print Dumper($json);
}
  

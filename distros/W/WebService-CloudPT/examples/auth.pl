#!/usr/bin/perl

###############################################################
## THIS IS JUST AN EXAMPLE OF HOW TO GET AN ACCESS_TOKEN AND 
## ACCESS_SECRET TO YOUR ACCOUNT FOR YOU NEW APP
##
## You need to update $key and $secret with your app data
##
## You need to install Dancer begore using this
###############################################################


use strict;
use warnings;
use Dancer;
use WebService::CloudPT;


my $callback ='http://localhost:3000/callback_cloudpt'; ## USE THIS URL AS CALLBACK WHEN REGISTERING YOUR APP
my $key =''; ### USE YOUR APP KEY HERE
my $secret = ''; ### USER YOUR APP SECRET
my $box = WebService::CloudPT->new( { 'key' => $key, 'secret' => $secret});


get '/' => sub {
		my $login_link;
		eval {	
			$login_link = $box->login($callback);
		}; 
		if ($@) {
			status 500;
			return   "There was a problem generating the login link, are you sure you updated this script with your app key and secret and the correct callback?";
		} else {
			redirect $login_link;
		}
};

get '/callback_cloudpt' => sub {
	my $args = params;
	my $verifier = $args->{'oauth_verifier'};
	$box->auth({'verifier' => $verifier});
	my $access_secret = $box->access_secret ;
	my $access_token  =  $box->access_token ;

	
	my $html = "<pre>Login Success\n\naccess_secret: " . $access_secret ."\naccess_token: " . $access_token ."\n\n";

	my $account_data = $box->account_info();
	$html .="store those for future access\n\n";
	$html .= "your email: " . $account_data->{'email'};
	$html .="</pre>";
	return $html;
};
	


	


dance;


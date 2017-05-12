#! /usr/bin/perl

use WebService::Dwolla;
use CGI;

my $redirect_url = 'http://192.168.11.14/cgi-bin/dwolla.cgi'; 

my $api = WebService::Dwolla->new(undef,undef,$redirect_url);

$api->set_api_config_from_file('/usr/local/etc/dwolla_api.conf');

my $q = new CGI->new;
my $params = $q->Vars;

# Step 1: Create an authentication URL that the user will be redirected to,
if (!$params->{'code'} || !$params->{'error'}) {
    print $q->redirect($api->get_auth_url());
}

# Exchange the temporary code given to us in the querystring, for
# a never-expiring OAuth access token.
if ($params->{'error'}) {
    $q->p('There was an error. Dwolla said: ' . $params->{'error_description'});
} elsif ($params->{'code'}) {
    $api->request_token($code);
    if (!$token) {
    	my @e = $api->get_errors();
    } else {
        $q->p('Your token is: ' . $params->{'code'});
    }
}

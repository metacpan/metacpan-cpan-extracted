#!/usr/bin/perl
=pod
/**
 * Language: Perl 5
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @Created On: 21-10-2016
 * Author: Inderpal Singh
 * Email: inderpal@ourdesignz.com
 * Updated On: 08/14/2017
 * Author: Sobhan Panda
 * Email: sobhan@centroxy.com
 * Company: Gluu Inc.
 * Company Website: https://www.gluu.org/
 * @license   http://www.opensource.org/licenses/mit-license.php MIT License
 */
=cut

###############
## Libraries ##
###############

use warnings;
use CGI qw{ :standard };
use lib './modules';
use JSON::PP;
use CGI::Carp qw(fatalsToBrowser); # show errors in browser
use CGI::Session;
#Load oxd Perl Module
use OxdPerlModule;

# Create the CGI object
my $cgi = new CGI;
# will restore any existing session with the session ID in the query object
my $session = CGI::Session->new($cgi);
# print the HTTP header and set the session ID cookie
print $session->header();

print "oxd Id: ".$session->param('oxd_id');
#print $session->param('client_id');
#print $session->param('client_secret');

##################
## Main program ##
##################
#server_side_ajax();
print_page_header();
print_html_head_section();
print_html_body_section_top();
# Process form if submitted; otherwise display it
if($cgi->param("submit")) {
	# Parameters are defined, therefore the form has been submitted
	display_results($cgi);
} else {
	# We're here for the first time, display the form
	print_html_form();
}

print_html_body_section_bottom();


#################
## Subroutines ##
#################
sub print_page_header {
    # Print the HTML header (don't forget TWO newlines!)
    #print "Content-type:  text/html\n\n";
}


sub print_html_head_section {
    
    print "<!DOCTYPE html>\n";
    print '<html lang="en">'."\n";
    print '<head>'."\n";
    print '<title>oxd Perl Application: UMA</title>'."\n";
    print '<meta charset="utf-8">'."\n";
    print '<meta name="viewport" content="width=device-width, initial-scale=1">'."\n";
    print '<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">'."\n";
    print "</head>\n";
}


sub print_html_body_section_top {
    # Create HTML body and show values from 1 - $max ($ncols per row)
    print '<body>'."\n";
    print '<div class="container">'."\n";
    print '<h1>oxd Perl Application - UMA</h1>'."\n";
   
}

sub print_html_body_section_bottom {    
   
    print '</div>'."\n";
    print '</body>'."\n";
    print '</html>'."\n";
}

# Displays the  form
sub print_html_form {
	print '<div class="row">'."\n";
    print '<div class="col-md-4">'."\n";
    print '<ul class = "list-group">'."\n";
	print '<li class="list-group-item"><a href="uma_rs_protect_test.cgi" target="_blank" >UMA RS Protect</a></li>'."\n";
	print '<li class="list-group-item"><a href="uma_rs_ckeck_access_test.cgi" target="_blank" >UMA RS Check Access</a></li>'."\n";
	print '<li class="list-group-item"><a href="uma_rp_get_rpt_test.cgi" target="_blank" >UMA RP - Get RPT</a></li>'."\n";
	print '<li class="list-group-item"><a href="uma_rp_get_claims_gathering_url_test.cgi" target="_blank" >UMA RP - Get Claims-Gathering URL</a></li>'."\n";
    print '</ul>'."\n";
	print '</div>'."\n";
    print '</div>'."\n";
}





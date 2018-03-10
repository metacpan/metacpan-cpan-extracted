#!/usr/bin/perl
=pod
/**
 * Language: Perl 5
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @Created On: 07/18/2017
 * Author: Sobhan Panda
 * Email: sobhan@centroxy.com
 * Company: Gluu Inc.
 * Company Website: https://www.gluu.org/
 * @license   http://www.opensource.org/licenses/mit-license.php MIT License
 */
=cut
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser); # show errors in browser
use CGI::Session;
use JSON::PP;
# new query object
my $cgi = CGI->new();

# new session object, will get session ID from the query object
# will restore any existing session with the session ID in the query object
my $session = CGI::Session->new($cgi);

# print the HTTP header and set the session ID cookie
print $session->header();
#BEGIN {push @INC, '..'}
use OxdPerlModule;
use Data::Dumper;


print_page_header();
print_html_head_section();
print_html_body_section_top();
# Process form if submitted; otherwise display it
print_html_form();

print_html_body_section_bottom();

sub print_page_header {
    # Print the HTML header (don't forget TWO newlines!)
    #print "Content-type:  text/html\n\n";
}


sub print_html_head_section {
    # Include stylesheet 'pm.css', jQuery library,
    # and javascript 'pm.js' in the <head> of the HTML.
    ##
    print "<!DOCTYPE html>\n";
    print '<html lang="en">'."\n";
    print '<head>'."\n";
    print '<title>oxd Perl Application</title>'."\n";
    print '<meta charset="utf-8">'."\n";
    print '<meta name="viewport" content="width=device-width, initial-scale=1">'."\n";
    print '<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">'."\n";
    print "</head>\n";
}


sub print_html_body_section_top {
    # Create HTML body and show values from 1 - $max ($ncols per row)
    print '<body>'."\n";
    print '<div class="container">'."\n";
    print '<div class="jumbotron"><h1>Gluu oxd Perl Application</h1></div>'."\n";
    print '<h2>User Info</h2>'."\n";
   
}

sub print_html_body_section_bottom {    
   
    print '</div>'."\n";
    print '</body>'."\n";
    print '</html>'."\n";
}

# Displays the  form
sub print_html_form {
	my $user_name = $session->param("username");
	my $user_mail = $session->param("useremail");
	my $given_name = $session->param("givenname");
	my $family_name = $session->param("familyname");
	
	my $red_url = "index.cgi";
	if($session->param('oxd_id') eq "") {
		print '<meta http-equiv="refresh" content="0;URL='.$red_url.'" />';
	}
	
	# Remove any potentially malicious HTML tags
	if($user_mail){
		$user_mail =~ s/<([^>]|\n)*>//g;
	}else{
		$user_mail = "";
	}
	if(!$user_name){
		$user_name = "";
	}
	
	print '<div class="col-md-12" align="right">
		<p><a href="logout.cgi">Logout</a></p>
		</div>'."\n";
	print '<div class="row">'."\n";
	print '<div class="col-md-4">'."\n";
	
	print '<form name="gluu-form" action="index.cgi" method="get" >
				<div class="form-group">
					<label for="user_name">Name</label>
					<input type="text" class="form-control" id="user_name" name="user_name" placeholder="Name" value="'.$user_name.'" disabled="disabled" />
				</div>
				<div class="form-group">
					<label for="user_mail">Email</label>
					<input type="email" class="form-control" id="user_mail" name="user_mail" placeholder="Email" value="'.$user_mail.'" disabled="disabled" />
				</div>
				
			</form>'."\n";
	print '</div>'."\n";
    print '</div>'."\n";
}

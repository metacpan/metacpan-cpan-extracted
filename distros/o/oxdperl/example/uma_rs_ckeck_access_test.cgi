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
 * Company: ourdesignz Pvt Ltd.
 * Company Website: http://wwww.ourdesignz.com
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
#Load Oxd Perl Module
use OxdPerlModule;
use Data::Dumper;
# Create the CGI object
my $cgi = new CGI;
# will restore any existing session with the session ID in the query object
my $session = CGI::Session->new($cgi);
# print the HTTP header and set the session ID cookie
print $session->header();
 
my $oxdId = $session->param('oxd_id');
my $umaRpt = $session->param('uma_rpt');

$uma_rs_authorize_rpt = new UmaRsCheckAccess();
$uma_rs_authorize_rpt->setRequestOxdId($oxdId);
$uma_rs_authorize_rpt->setRequestRpt($umaRpt);
$uma_rs_authorize_rpt->setRequestPath("/photo");
$uma_rs_authorize_rpt->setRequestHttpMethod("GET");
$uma_rs_authorize_rpt->request();
print "UMA RS CHECK ACCESS";
print "<br/><br/>";
print "<pre>";
print Dumper($uma_rs_authorize_rpt->getResponseObject());

my $uma_ticket= $uma_rs_authorize_rpt->getResponseTicket();
$session->param('uma_ticket', $uma_ticket);


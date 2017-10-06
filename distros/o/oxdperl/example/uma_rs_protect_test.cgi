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

#my $oxdId = $session->param('oxd_id');
my $oxdId = $session->param('oxd_id');

$uma_rs_protect = new UmaRsProtect();
$uma_rs_protect->setRequestOxdId($oxdId);

$uma_rs_protect->addConditionForPath(["GET"],["https://photoz.example.com/dev/actions/view"], ["https://photoz.example.com/dev/actions/view"]);
$uma_rs_protect->addConditionForPath(["POST"],[ "https://photoz.example.com/dev/actions/add"],[ "https://photoz.example.com/dev/actions/add"]);
$uma_rs_protect->addConditionForPath(["DELETE"],["https://photoz.example.com/dev/actions/remove"], ["https://photoz.example.com/dev/actions/remove"]);
$uma_rs_protect->addResource('/photo');

$uma_rs_protect->request();
print "UMA RS PROTECT";
print "<br/><br/>";
print "<pre>";
print Dumper( $uma_rs_protect->getResponseObject() );

print '</pre><br/>';


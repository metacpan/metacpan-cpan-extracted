#
# SFR.pm for WWW::SMS
#
# Copyright (C) 2001 Cedric Bouvier (cédric) <cbouvi@free.fr>
# Copyright (C) 2000,2001 Julien Gaulmin (julien23) <julien23@multimania.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
# USA or look at http://www.gnu.org/copyleft/gpl.html
#
# Contributors :
#	- Cédric Bouvier (bwana147) <cbouvi@free.fr>
#	- Julien Gaulmin (julien23) <julien23@multimania.com>
#
# Change Log :
#	- v1.1 (bwana147)   : first version adapted from sms4nothing

package WWW::SMS::SFR;
use strict;

use Telephone::Number;
use vars qw/ @ISA @EXPORT @EXPORT_OK @PREFIXES $VERSION /;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(@PREFIXES _send MAXLENGTH);
@PREFIXES = (Telephone::Number->new('33', [
		qw(60[39] 61\d 62[0-3] 655)
		], undef));

$VERSION = '1.02';
sub MAXLENGTH ()	{640}
use constant LANGUAGE => 'FR';
use constant NETWORK => 'smsc1';
use constant VALIDITY_PERIOD => '72';


sub hnd_error {
    $WWW::SMS::Error = "Failed at step $_[0] of module SFR.pm\n";
    return 0;
}

sub _send {
    my $self = shift;

    require HTTP::Cookies;
    #require Time::localtime;
    #require Time::Local;
    require Date::Manip;
    require LWP::UserAgent;
    require HTTP::Request;

    import Date::Manip qw/ ParseDate UnixDate /;

    my $step = 1;

    my $ua = LWP::UserAgent->new;
    my $cookie_jar = HTTP::Cookies->new(
	file => ($self->{cookie_jar} || "lwpcookie.txt"),
	autosave => 1
    );
    $ua->agent('Mozilla/5.0');
    $ua->proxy('http', $self->{proxy}) if ($self->{proxy});
    $ua->cookie_jar($cookie_jar);

    $self->{smstext} = substr($self->{smstext}, 0, MAXLENGTH - 1) 
	if (length($self->{smstext})>MAXLENGTH);

    my (
        $delivery_year,	
        $delivery_month,
        $delivery_date,
        $delivery_hour,
        $delivery_min,
        $delivery_time,
    ) = UnixDate((ParseDate($self->{date}) || ParseDate('now')), qw/%Y %m %d %H %M %s/);

    # SFR compatible
    $delivery_month--;		# january is 0
    $delivery_time .= '000';	# strange sfr epoch format

    # Create a GET request in order to get the javasession cookie from SFR
    my $req = new HTTP::Request;
    $req->method('GET');
    $req->uri('http://195.115.48.10/servlet/ProxyFirst?' .
            'redirect=SMS&LANGUAGE=FR&PAGE=launch');

    # Pass request from the user agent and get a response back
    my $res = $ua->request($req);
    $cookie_jar->add_cookie_header($req);

    # Check the outcome of the response
    return &hnd_error($step) unless $res->is_success();
    $step++;

    # Create a POST request to send the message
    $req = new HTTP::Request;
    $req->method('POST');
    $req->uri('http://195.115.48.10/servlet/ProxySecond?redirect=SMS');
    $req->referer('http://195.115.48.10/servlet/SMSServlet_KZ1OS9?' .
                'redirect=SMS&LANGUAGE=FR&PAGE=launch');
    $req->content_type('application/x-www-form-urlencoded');

    my %content = (
        NOTIFICATION_FLAG	=> 'false',
        LANGUAGE        	=> LANGUAGE,
        NETWORK         	=> NETWORK,
        DELIVERY_TIME       	=> $delivery_time,
        DELIVERY_DATE	        => $delivery_date,
        DELIVERY_MONTH	        => $delivery_month,
        DELIVERY_YEAR       	=> $delivery_year,
        DELIVERY_HOUR	        => $delivery_hour,
        DELIVERY_MIN	        => $delivery_min,
        SENDER           	=> '',
        NOTIFICATION_ADDRESS	=> '',
        caracteres	        => length($self->{smstext}),
        SHORT_MESSAGE	        => $self->{smstext},
        VALIDITY_PERIOD     	=> VALIDITY_PERIOD,
        RECIPIENT	        => '0'.$self->{prefix}.$self->{telnum},
    );
    $req->content(join '&' => map { "$_=$content{$_}" } keys %content);

    # Pass request from the user agent and get a response back
    $res = $ua->request($req);
    $cookie_jar->add_cookie_header($req);

    # Check the outcome of the response
    return &hnd_error($step) unless $res->is_success();
    1;
}

1;

#!/bin/perl
# 15.4.2008, Sampo Kellomaki (sampo@symlabs.com)

use Net::SSLeay;
use MIME::Base64;
use Data::Dumper;

$out  = "Content-Type: text/html\n\n<h1>Orange API Tester</h1>";
$out .= "<i><b>Powered by <a href=\"http://zxid.org/\">ZXID.org</a></b></i>\n";
$out .= qq(<p>[<a href="/protected/saml?o=gl">Local Logout</a>][<a href="/protected/saml?o=gr">Logout All</a>][<a href="/protected/saml?o=m">Mgmt</a>][<a href="/protected/orange.cgi">Redo</a>]);

#print Dumper %ENV;
#$tok = 'B64ZykVc8LgIlcwgLgOkFaASPMPSo5cp+q1Acbb4cnDZbCedIfYw9cllz89a2Ql+Pn4fGf8uhX2j4iH7PojzB57ppzrbv0ECxG+SzNewsjk0kU=|sau=|ted=1208280413|Lq7LWxp8KX2EaPPo3gQIRcWiSJA=';

$tok = $ENV{'SAML_OrangeAPIToken'};
$tok =~ s/\+/%2b/gs;

$myurl = 'https://sp1.zxidsp.org:5443/protected/orange.cgi';
$myurl =~ s|([/:?&])|sprintf("%%%02x", ord($1))|gsex;
$host = 'personal.alpha.orange-api.net';
#$user = 'https://sp1.zxidsp.org:8443/zxidhlo?o=B';
#$user = 'https%3a//sp1.zxidsp.org%3a8443/zxidhlo?o=B';
#$user = 'ZXIDHELLOT1184204761';
$user = 'ZXIDHELLOT5882485470';
$pass = '5)CIlpCG';

$out .= <<HTML;
<p>Host: $host<br>
User: $user<br>
Pass: $pass<br>
Tok: $tok<br>
MyURL: $myurl
HTML
    ;

# https://personal.alpha.orange-api.net/int/PersonalPhotos/V1
# https://personal.alpha.orange-api.net/int/PersonalContacts/V1
# https://personal.alpha.orange-api.net/int/PersonalMessages/V1
# https://personal.alpha.orange-api.net/int/PersonalCalendar/V1

@t = (
      '/int/PersonalContacts/V1?action=addcontact&lastname=Koerkki&firstname=Janne&nickname=koerkkicompany=ACME&function=Tester&department=Test+Lab&emailperso=koerkki@acme.com',
      '/int/PersonalContacts/V1?action=findcontactlist&search=Res',
      '/int/PersonalContacts/V1?action=findcontactlist&search=koe',
      '/int/PersonalContacts/V1?action=getcontact&cid=123',
      '/int/PersonalContacts/V1?action=getcontact&cid=456',
      '/int/PersonalMessages/V1?action=getPNS&infos=NoUnReadMails,NoEMails',
      '/int/PersonalCalendar/V1?action=addevent&title=Demo+meet&location=Townhall&description=Come+all+and+see+the+demo&startdate=2008-05-09&starttime=13:40&enddate=2008-05-09&endtime=14:15&datepattern=yyyy-MM-dd&timepattern=HH:mm',
      );

for $test (@t) {
    ++$i;
    ($page, $result, %headers)
	= Net::SSLeay::get_https($host, 443, "$test&token=$tok",
		    Net::SSLeay::make_headers(Authorization =>
				 'Basic ' . MIME::Base64::encode("$user:$pass",''))
		    );
    warn "GET $test\n$result\n";
    if ($page =~ /PrivacyAccessDeniedException/) {
	($url) = $page =~ /<url>(.*)<\/url>/;
	$url =~ s/&amp;/&/gs;
	warn "REDIRECT url($url)";
	print "Location: $url&urlRetour=$myurl%3FfromOrangePrivacy%3Dtrue\n\n";
	exit;
    }
    $out .= "<h3>Test $i</h3>\n<pre>GET $test\n$result\n</pre><textarea cols=100 rows=15>$page</textarea>\n";    
}

print $out;
print qq(<hr><a href="http://zxid.org/"><img src="http://zxid.org/button-zxid-150x60.png" width=150 height=60 border=0></a>\n);

__END__

https://personal.alpha.orange-api.net/int/PersonalContacts/V1?action=findcontactlist&search=Res&token=B649bqepYsSgyeG0YEqRfaqZfKepqqXA/MNWrq26wmyNg7DGqvq0XFg14sPAPCKxR0+j9rt+3KqcZC1kZXKam0Y0FWpbTeZSExLsvCThURos5Q=|sau=|ted=1208277327|lZNyzAFHF95wGIzT8+drVAaz1+k=

https://personal.alpha.orange-api.net/int/PersonalContacts/V1?action=findcontactlist&search=Res&token=B641JdSYmhqWQWIVe182/49MDWdr8vuesUdovzJm7uxzUFns7K55ADEASBSST8PNHox7vwoxAu2BwOrdOo7xVbUV6Uzyd36inXKiE6/tWINxlc=|sau=|ted=1208277986|ysJgx5YVaxtZgs/N/bvNObbgLTE=

https://personal.alpha.orange-api.net/int/PersonalContacts/V1?action=findcontactlist&search=Res&token=

https://personal.alpha.orange-api.net/int/PersonalContacts/V1?action=findcontactlist&search=Res&token=

https://personal.alpha.orange-api.net/int/PersonalContacts/V1?action=findcontactlist&search=Res&token=

https://sp1.zxidsp.org:8443/zxidhlo?o=B
5)CIlpCG



/privacy/interaction.do?family=contact&serviceId=DEMOSPUSIN1653032205&attributes=,add
&urlRetour=http%3A%2F%2F161.105.181.114%2FphpOrangeApiConsumer%2Fdemo%2Fresto%2FTonResto.com%2FEclaireur%2FEclaireur.php%3FfromOrangePrivacy%3Dtrue 


Orange API Tester
============ 1 ===========
/int/PersonalContacts/V1?action=findcontactlist&search=Res
HTTP/1.1 500 Internal Server Error
<?xml version="1.0" encoding="UTF-8"?><error><!--Warning : operation non autorisee--><code>-3</code><detail>PrivacyAccessDeniedException</detail><url>http://int4.mdsp.rec.orange.fr/privacy/interaction.do?family=contact&amp;serviceId=ZXIDHELLOT1184204761&amp;attributes=,see</url></error>


http://int4.mdsp.rec.orange.fr/privacy/interaction.do?family=contact&amp;serviceId=ZXIDHELLOT1184204761&amp;attributes=,see


<error>
  <code>-3</>
  <detail>PrivacyAccessDeniedException</>
  <url>
    http://int4.mdsp.rec.orange.fr/privacy/interaction.do?family=contact&serviceId=ZXIDHELLOT1184204761&attributes=,see</></>





http://int4.mdsp.rec.orange.fr/privacy/interaction.do?family=contact&serviceId=ZXIDHELLOT5882485470&attributes=,add

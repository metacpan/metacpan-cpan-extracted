use Test::More tests => 1;

use WWW::Domain::Registry::Afilias;

my $reg = WWW::Domain::Registry::Afilias->new;
my $res = $reg->parse_home(<<'EOS');
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html><head>


<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<meta content=".INFO, afilias, global registry, registry, domain names, register, registry services, domain name system, dns, whois, registrars, tld, gtld, registration authority, internet address, icann-accredited, afilias limited, afillias, affilias, afillius, official" name="keywords">
<meta content="Afilias -- The .INFO Registry. Afilias operates the world's new general-purpose top-level domain.  Learn how to get a .INFO domain name, and how to use it for business, personal use, and more." name="description">
<meta content="TRUE" name="MSSmartTagsPreventParsing"><title>Home</title>

<link type="text/css" href="home.do_files/infostyle.css" rel="StyleSheet"></head><body>
<div id="outer">
<div id="left">
<div class="dateBar">December 13, 2006</div>
<div class="balanceInfo">
<div style="text-indent: 20px;">BALANCE: $1,230.00</div>
<div style="text-indent: 20px;">TOTAL DOMAINS: 789*</div>
<div style="text-indent: 20px;" class="asof">*Updated Daily at 00:01 UTC</div>
</div>
<div style="margin-bottom: 2px;" class="registryTools"></div>
<a href="https://admin.afilias.net/home.do" class="leftMenuButton">
<div class="leftMenuButton">
<div class="leftMenuText">Home</div>
</div>
</a><a href="https://admin.afilias.net/account.do" class="leftMenuButton">
<div class="leftMenuButton">
<div class="leftMenuText">Account Information</div>
</div>
</a><a href="https://admin.afilias.net/check_availability.do" class="leftMenuButton">
<div class="leftMenuButton">
<div class="leftMenuText">Check Availability</div>
</div>
</a><a href="https://admin.afilias.net/access_existing.do" class="leftMenuButton">
<div class="leftMenuButton">
<div class="leftMenuText">View/Modify Objects</div>
</div>
</a><a href="https://admin.afilias.net/create_domain.do" class="leftMenuButton">
<div class="leftMenuButton">
<div class="leftMenuText">Create Domain</div>
</div>
</a><a href="https://admin.afilias.net/create_contact.do" class="leftMenuButton">
<div class="leftMenuButton">
<div class="leftMenuText">Create Contact</div>
</div>
</a><a href="https://admin.afilias.net/create_nameserver.do" class="leftMenuButton">
<div class="leftMenuButton">
<div class="leftMenuText">Create Nameserver</div>
</div>
</a><a href="https://admin.afilias.net/reports.do" class="leftMenuButton">
<div class="leftMenuButton">
<div class="leftMenuText">Reports</div>
</div>
</a><a href="https://admin.afilias.net/transfer.do" class="leftMenuButton">
<div class="leftMenuButton">
<div class="leftMenuText">Transfer Center</div>
</div>
</a><a href="https://admin.afilias.net/logout.do" class="leftMenuButton">
<div class="leftMenuButton">
<div class="leftMenuText">Logout</div>
</div>
</a>
<div class="dateBar" style="margin-top: 30px;">AFILIAS TECH SUPPORT</div>
<div class="techArea">
<div class="techEmail">
<a href="mailto:techsupport@afilias.net" class="techInfo">techsupport@afilias.net</a>
</div>
<div class="techPhone">
<a href="mailto:techsupport@afilias.net" class="techInfo">+1.416.646.3306</a>
</div>
<div class="techFax">
<a href="mailto:techsupport@afilias.net" class="techInfo">+1.416.646.1541</a>
</div>
</div>
<div class="dateBar" style="height: 12px;"></div>
</div>
<div id="clearheader"></div>
<div style="" id="centrecontent">
<div style="margin: 30px;">
<div class="bodyCopy">
<p class="contentSubSections">Welcome, foobar Co. Ltd.(3456-EG)</p>
<br>
<br>
<p>
<span class="dkbluetxt">Account balance:</span> &nbsp;US&nbsp;&nbsp;1,230.00</p>
<p>
<span class="dkbluetxt">Number of domains in your account:</span>789<br>
<table>
<tbody><tr>
<td width="20">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td><td width="40">.INFO</td><td width="50">789</td>
</tr>
</tbody></table>
</p>
<p>
<span class="dkbluetxt">Domain names created in your account yesterday:</span>0</p>
<p>The account balance displayed is as of the time of this page
request. The domain count numbers are as of Dec 13, 2006, 00:01 UTC and
are updated daily.</p>
</div>
</div>
</div>
<div id="clearfooter"></div>
</div>
<div style="text-indent: 10px; text-align: left; color: rgb(255, 255, 255); font-size: 10pt;" id="footer">Copyright Ž© 2006 Afilias Limited. All Rights Reserved</div>
<div id="header">
<div class="infoBar">
<div class="infoLogin">
       WELCOME  FOOBAR CO. LTD.</div>
<div style="float: right;">
<a href="https://admin.afilias.net/account.do" class="infoLogin">MY ACCOUNT</a><a href="" class="infoLogin">|</a><a href="https://admin.afilias.net/reports.do" class="infoLogin">MY REPORTS</a><a href="" class="infoLogin">|</a><a href="https://admin.afilias.net/contact_us.do" class="infoLogin">CONTACT US</a>
</div>
</div>
<div class="infoBarEdge"></div>
<div class="infoTabBar"></div>
<div class="infoTabBg"></div>
<a href="http://www.afilias.info/registrars/" class="tab1">
<div>
<font color="#2d50ac">Registrar Relations</font>
</div>
</a><a href="http://www.afilias.info/faqs/" class="tab2">
<div>
<font color="#2d50ac">.INFO FAQs</font>
</div>
</a><a href="https://www.afilias.info/registrars/registrar_relations/UserGuide.pdf" class="tab3">
<div>
<font color="#2d50ac">User Guide</font>
</div>
</a>
</div>
</body></html>
EOS
;

is($res->{'balance'}, 'US1,230.00', 'home');
1

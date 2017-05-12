use Test::More tests => 1;

use WWW::Domain::Registry::Afilias;

my $reg = WWW::Domain::Registry::Afilias->new;
my $res = $reg->parse_account(<<'EOS');
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html><head>


<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<meta content=".INFO, afilias, global registry, registry, domain names, register, registry services, domain name system, dns, whois, registrars, tld, gtld, registration authority, internet address, icann-accredited, afilias limited, afillias, affilias, afillius, official" name="keywords">
<meta content="Afilias -- The .INFO Registry. Afilias operates the world's new general-purpose top-level domain.  Learn how to get a .INFO domain name, and how to use it for business, personal use, and more." name="description">
<meta content="TRUE" name="MSSmartTagsPreventParsing"><title>Account Information</title>

<link type="text/css" href="account.do_files/infostyle.css" rel="StyleSheet"></head><body>
<div id="outer">
<div id="left">
<div class="dateBar">December 13, 2006</div>
<div class="balanceInfo">
<div style="text-indent: 20px;">BALANCE: $2,340.00</div>
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
<p class="contentSubSections">Account Information</p>
<br>
<p class="error"></p>
<p>Account information for Registrar: foobar Co. Ltd.</p>
<form action="account.do" method="post">
<br>
<table border="0" cellpadding="10" cellspacing="0">
<tbody><tr>
<td align="right" valign="top" width="150">&nbsp;</td><td align="left" valign="top"><input value="Update Account Details" name="update_account" src="account.do_files/updateAccountBtn.png" type="image"></td>
</tr>
<tr>
<td align="right" valign="top" width="150">Account ID</td><td align="left" valign="top">2345-EG</td>
</tr>
<tr>
<td align="right" valign="top" width="150">Balance</td><td align="left" valign="top">US&nbsp;&nbsp;2,340.00</td>
</tr>
<tr>
<td align="right" valign="top" width="150">Low balance notification threshold</td><td align="left" valign="top">US&nbsp;&nbsp;300.00</td>
</tr>
<tr>
<td align="right" valign="top" width="150">Low balance notification e-mail address</td><td align="left" valign="top">foo@example.jp</td>
</tr>
<tr>
<td align="right" valign="top" width="150">Default notification e-mail address</td><td align="left" valign="top"></td>
</tr>
<tr>
<td align="right" valign="top" width="150">URL</td><td align="left" valign="top"></td>
</tr>
<tr>
<td align="right" valign="top" width="150">Billing ID<br>
            Billing Name<br>
            Billing Organization<br>
            Billing Street1<br>
            Billing Street2<br>
            Billing Street3<br>
            Billing City<br>
            Billing State/Province<br>
            Billing Postal Code<br>
            Billing Country<br>
            Billing Phone<br>
            Billing Phone Ext<br>
            Billing Fax<br>
            Billing Fax Ext<br>
            Billing Email
            </td><td><a href="https://admin.afilias.net/access_contact.do?id=C12345678-LRMS">C12345678-LRMS</a>
<br>Osamu Inomata<br>foobar Co. Ltd.<br>Roppongi Hills 1F<br>6-10-1<br>Roppongi<br>Minato-ku<br>Tokyo<br>106-6138<br>JP<br>+81.355556666<br>
<br>+81.355557777<br>
<br>domain@example.net<br>
<br>
</td>
</tr>
<tr>
<td align="right" valign="top" width="150">&nbsp;</td><td align="left" valign="top"><input value="Registrar" name="accountType" type="hidden"><input value="300.00" name="threshold" type="hidden"><input value="foo@example.jp" name="lowBalanceNotifyEmail" type="hidden"><input value="" name="transferNotifyEmail" type="hidden"><input value="" name="URL" type="hidden"><input value="" name="admins" type="hidden"><input value="" name="techs" type="hidden"><input value="C12345678-LRMS" name="billings" type="hidden"><input value="Update Account Details" name="update_account" src="account.do_files/updateAccountBtn.png" type="image"></td>
</tr>
</tbody></table>
</form>
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

is($res->{'balance'}, 'US2,340.00', 'account');
1

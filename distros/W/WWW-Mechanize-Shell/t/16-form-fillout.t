#!/usr/bin/perl -w
use strict;
use FindBin;
use Test::More;

use File::Temp qw( tempfile );
our ($_STDOUT_, $_STDERR_ );
use URI::URL;
use Test::HTTP::LocalServer;
use lib './inc';
use IO::Catch;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'IO::Catch', '_STDOUT_' or die $!;
tie *STDERR, 'IO::Catch', '_STDERR_' or die $!;

our %tests = (
    interactive_script_creation => { requests => 2,
    									lines => [ 'eval @::list=qw(1 2 3 4 5 6 7 8 9 10 foo NY 11 DE 13 V 15 16 2038-01-01)',
    														 'eval
    														    no warnings qw"once redefine";
    														    *WWW::Mechanize::FormFiller::Value::Ask::ask_value = sub {
    														      #warn "Filled out ",$_[1]->name;
    														      my $value=shift @::list || "empty";
    														      push @{$_[0]->{shell}->{answers}}, [ $_[1]->name, $value ];
    														      $value
    														    }',
    														 'get %s',
    														 'fillout',
    														 'submit',
    														 'content' ],
    									location => '%sgift_card/alphasite/www/cgi-bin/giftcard.cgi/checkout_process' },
  );

plan tests => (scalar keys %tests)*6;
BEGIN {
  delete $ENV{PAGER};
  $ENV{PERL_RL} = 0;
};
use WWW::Mechanize::Shell;
SKIP: {

# Disable all ReadLine functionality
my $HTML = do { local $/; <DATA> };

# We want to be safe from non-resolving local host names
delete @ENV{qw(HTTP_PROXY http_proxy CGI_HTTP_PROXY)};

my $actual_requests;
{
  no warnings 'redefine';
  my $old_request = *WWW::Mechanize::request{CODE};
  *WWW::Mechanize::request = sub {
    $actual_requests++;
    goto &$old_request;
  };

  *WWW::Mechanize::Shell::status = sub {};
};

for my $name (sort keys %tests) {
  $_STDOUT_ = '';
  undef $_STDERR_;
  $actual_requests = 0;
  my @lines = @{$tests{$name}->{lines}};
  my $requests = $tests{$name}->{requests};

  my $server = Test::HTTP::LocalServer->spawn( html => $HTML );
	my $code_port = $server->port;

  my $result_location = sprintf $tests{$name}->{location}, $server->url;
	my $s = WWW::Mechanize::Shell->new( 'test', rcfile => undef, warnings => undef );
	for my $line (@lines) {
          no warnings;
	  $line = sprintf $line, $server->url;
  	$s->cmd($line);
	};
	$s->cmd('eval $self->agent->uri');
  my $code_output = $_STDOUT_;
  diag join( "\n", $s->history )
    unless is($s->agent->uri,$result_location,"Shell moved to the specified url for $name");
	is($_STDERR_,undef,"Shell produced no error output for $name");
	is($actual_requests,$requests,"$requests requests were made for $name");
	my $code_requests = $server->get_log;

  my $script_server = Test::HTTP::LocalServer->spawn(html => $HTML);
  my $script_port = $script_server->port;

  # Modify the generated Perl script to match the new? port
  my $script = join "\n", $s->script;
  s!\b$code_port\b!$script_port!smg for ($script, $code_output);
  undef $s;

	# Write the generated Perl script
  my ($fh,$tempname) = tempfile();
  print $fh $script;
  close $fh;

  my ($compile) = `$^X -c "$tempname" 2>&1`;
  chomp $compile;
  unless (is($compile,"$tempname syntax OK","$name compiles")) {
    $script_server->stop;
    diag $script;
    ok(0, "Script $name didn't compile" );
    ok(0, "Script $name didn't compile" );
  } else {
    my ($output);
    my $command = qq($^X -Ilib "$tempname" 2>&1);
    $output = `$command`;
    $output =~ s!^Cookie:.*$!Cookie: <removed>!smg; # cookies get re-ordered, sometimes
    $code_output =~ s!^Cookie:.*$!Cookie: <removed>!smg; # cookies get re-ordered, sometimes
    is( $output, $code_output, "Output of $name is identical" )
      or diag "Script:\n$script";
    my $script_requests = $script_server->get_log;
    $code_requests =~ s!\b$code_port\b!$script_port!smg;
    $code_requests =~ s!^Cookie:.*$!Cookie: <removed>!smg; # cookies get re-ordered, sometimes
    $script_requests =~ s!^Cookie:.*$!Cookie: <removed>!smg; # cookies get re-ordered, sometimes
    is($code_requests,$script_requests,"$name produces identical queries")
      or diag $script;
  };
  unlink $tempname
    or diag "Couldn't remove tempfile '$name' : $!";
};

unlink $_ for (<*.save_log_server_test.tmp>);

};

__DATA__
<!-- saved from url=(0022)http://internet.e-mail -->
<?xml version="1.0" encoding="iso-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml"><!-- #BeginTemplate "/Templates/page.dwt" --><!-- DW6 -->
<head>
<!-- #BeginEditable "doctitle" -->
<title>- Gift Cards</title>
<script language="JavaScript" type="text/JavaScript">
<!--
function MM_goToURL() { //v3.0
  var i, args=MM_goToURL.arguments; document.MM_returnValue = false;
  for (i=0; i<(args.length-1); i+=2) eval(args[i]+".location='"+args[i+1]+"'");
}
//-->
</script>
<!-- #EndEditable -->
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<link href="css/basic.css" rel="stylesheet" type="text/css" />
</head>

<body >
<table width="99%" border="0">
    <td valign="top" class="page-content"><!-- #BeginEditable "page_content" -->




      <table width="600" border="0" cellspacing="7" cellpadding="0">
        <tr align="left" valign="top">
          <td width="50%"><img src="images/giftcarddesign.gif" width="300" height="189" border="0" />
            <p class="page-content">&nbsp;</p>
          </td>
          <td width="50%" class="left-line-cell">  <p class="page-content"><b>Gift Card</b></p>
          <p class="page-content">Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent
luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. </p>
          </td>
        </tr>
        <tr align="left" valign="top">
			<td colspan="2"><form name="form2" id="form2" method="post" action="/gift_card/alphasite/www/cgi-bin/giftcard.cgi/checkout_process">
          <hr size="1" noshade="noshade" />
          <table width="100%" border="0" cellspacing="5" cellpadding="0">
            <tr align="left" valign="top">
              <td width="50%"><table width="100%" border="0" cellspacing="0" cellpadding="3">
                <tr>
                  <td colspan="3"> <b>Delivery Information</b></td>
                </tr>
                <tr bgcolor="#00548F">
                  <td colspan="3" class="page-content"><font color="#FFFFFF"><b>recipient Name:</b></font></td>
                </tr>
                <tr class="page-content">
                  <td width="20"> First: </td>
                  <td>
                    <input name="recipient_first_name" type="text" size="20" />
      * </td>
                </tr>
                <tr class="page-content">
                  <td>Middle: </td>
                  <td>
                    <input name="recipient_middle_name" type="text" size="20" />
                  </td>
                </tr>
                <tr class="page-content">
                  <td>Last: </td>
                  <td>
                    <input name="recipient_last_name" type="text" size="20" />
      * </td>
                </tr>
                <tr class="page-content">
                  <td>Nickname: </td>
                  <td>
                    <input name="recipient_nick_name" type="text" size="20" />
                  </td>
                </tr>
                <tr bgcolor="#00548F">
                  <td colspan="2" class="page-content"><font color="#FFFFFF"><b>Room Number:</b></font></td>
                </tr>
                <tr bgcolor="#FFFFFF">
                  <td colspan="3"><b></b>
                      <input name="recipient_room_number" type="text" />
                  </td>
                </tr>
                <tr bgcolor="#00548F">
                  <td colspan="3" class="page-content"><b><font color="#FFFFFF">Card Amount:</font></b></td>
                </tr>
                <tr bgcolor="#FFFFFF">
                  <td colspan="3"><input name="card_amount" type="text" size="10" />
                      <span class="page-content"> * (i.e. $20.00)</span></td>
                </tr>
              </table></td>
              <td width="50%"><table width="100%" border="0" align="center" cellpadding="3" cellspacing="1">
                <tr bgcolor="#FFFFFF">
                  <td colspan="2"> <b>Billing Information</b></td>
                </tr>
                <tr>
                  <td width="97" bgcolor="#00548F" class="page-content"><font color="#FFFFFF"><b>First Name:</b></font></td>
                  <td width="288" class="page-content">
                    <input name="billing_first_names" type="text" />
                    <b>*</b> </td>
                </tr>
                <tr>
                  <td width="97" bgcolor="#00548F" class="page-content"><font color="#FFFFFF"><b>Last Name:</b></font></td>
                  <td width="288" class="page-content">
                    <input name="billing_last_name" type="text" />
                    <b>* </b> </td>
                </tr>
                <tr>
                  <td width="97" bgcolor="#00548F" class="page-content"><font color="#FFFFFF"><b>Email Address :</b></font></td>
                  <td width="288" class="page-content">
                    <input name="billing_email" type="text" />
                    <b>*#</b></td>
                </tr>
                <tr>
                  <td width="97" bgcolor="#00548F" class="page-content"><font color="#FFFFFF"><b> Address:</b></font></td>
                  <td width="288" class="page-content">
                    <input name="billing_line1" type="text" />
                    <b>*</b> </td>
                </tr>
                <tr>
                  <td width="97" bgcolor="#00548F" class="page-content"><font color="#FFFFFF"><b> City:</b></font></td>
                  <td width="288" class="page-content">
                    <input name="billing_city" type="text" />
                    <b>*</b> </td>
                </tr>
                <tr>
                  <td width="97" bgcolor="#00548F" class="page-content"><font color="#FFFFFF"><b>State:</b></font></td>
                  <td width="288" class="page-content">
                    <select name="billing_usps_abbrev">
                      <option value="" selected="selected">Choose a State </option>
                      <option value="AL">Alabama </option>
                      <option value="AK">Alaska </option>
                      <option value="AB">Alberta </option>
                      <option value="AS">American Samoa </option>
                      <option value="AZ">Arizona </option>
                      <option value="AR">Arkansas </option>
                      <option value="BC">British Columbia </option>
                      <option value="CA">California </option>
                      <option value="CO">Colorado </option>
                      <option value="CT">Connecticut </option>
                      <option value="DE">Delaware </option>
                      <option value="DC">District Of Columbia </option>
                      <option value="FL">Florida </option>
                      <option value="GA">Georgia </option>
                      <option value="GU">Guam </option>
                      <option value="HI">Hawaii </option>
                      <option value="ID">Idaho </option>
                      <option value="IL">Illinois </option>
                      <option value="IN">Indiana </option>
                      <option value="IA">Iowa </option>
                      <option value="KS">Kansas </option>
                      <option value="KY">Kentucky </option>
                      <option value="LA">Louisiana </option>
                      <option value="ME">Maine </option>
                      <option value="MB">Manitoba </option>
                      <option value="MD">Maryland </option>
                      <option value="MA">Massachusetts </option>
                      <option value="MI">Michigan </option>
                      <option value="MN">Minnesota </option>
                      <option value="MS">Mississippi </option>
                      <option value="MO">Missouri </option>
                      <option value="MT">Montana </option>
                      <option value="NE">Nebraska </option>
                      <option value="NV">Nevada </option>
                      <option value="NB">New Brunswick </option>
                      <option value="NH">New Hampshire </option>
                      <option value="NJ">New Jersey </option>
                      <option value="NM">New Mexico </option>
                      <option value="NY">New York </option>
                      <option value="NF">Newfoundland </option>
                      <option value="NC">North Carolina </option>
                      <option value="ND">North Dakota </option>
                      <option value="MP">Northern Mariana Is </option>
                      <option value="NT">Northwest Territories </option>
                      <option value="NS">Nova Scotia </option>
                      <option value="OH">Ohio </option>
                      <option value="OK">Oklahoma </option>
                      <option value="ON">Ontario </option>
                      <option value="OR">Oregon </option>
                      <option value="PW">Palau </option>
                      <option value="PA">Pennsylvania </option>
                      <option value="PE">Prince Edward Island </option>
                      <option value="PQ">Province du Quebec </option>
                      <option value="PR">Puerto Rico </option>
                      <option value="RI">Rhode Island </option>
                      <option value="SK">Saskatchewan </option>
                      <option value="SC">South Carolina </option>
                      <option value="SD">South Dakota </option>
                      <option value="TN">Tennessee </option>
                      <option value="TX">Texas </option>
                      <option value="UT">Utah </option>
                      <option value="VT">Vermont </option>
                      <option value="VI">Virgin Islands </option>
                      <option value="VA">Virginia </option>
                      <option value="WA">Washington </option>
                      <option value="WV">West Virginia </option>
                      <option value="WI">Wisconsin </option>
                      <option value="WY">Wyoming </option>
                      <option value="YT">Yukon Territory </option>
                    </select>
                    <b>*</b> </td>
                </tr>
                <tr>
                  <td width="97" bgcolor="#00548F" class="page-content"><font color="#FFFFFF"><b> Zip:</b></font></td>
                  <td width="288" class="page-content">
                    <input maxlength="5" name="billing_zip_code" type="text" size="7" />
                    <b>*</b> </td>
                </tr>
                <tr>
                  <td width="97" bgcolor="#00548F" class="page-content"><font color="#FFFFFF"><b>Country:</b></font></td>
                  <td width="288" class="page-content">
                    <select name="billing_country_code">
                      <option value="AF">Afghanistan</option>
                      <option value="AL">Albania</option>
                      <option value="DZ">Algeria</option>
                      <option value="AS">American Samoa</option>
                      <option value="AD">Andorra</option>
                      <option value="AO">Angola</option>
                      <option value="AI">Anguilla</option>
                      <option value="AQ">Antarctica</option>
                      <option value="AG">Antigua and Barbuda</option>
                      <option value="AR">Argentina</option>
                      <option value="AM">Armenia</option>
                      <option value="AW">Aruba</option>
                      <option value="AU">Australia</option>
                      <option value="AT">Austria</option>
                      <option value="AZ">Azerbaijan</option>
                      <option value="BS">Bahamas</option>
                      <option value="BH">Bahrain</option>
                      <option value="BD">Bangladesh</option>
                      <option value="BB">Barbados</option>
                      <option value="BY">Belarus</option>
                      <option value="BE">Belgium</option>
                      <option value="BZ">Belize</option>
                      <option value="BJ">Benin</option>
                      <option value="BM">Bermuda</option>
                      <option value="BT">Bhutan</option>
                      <option value="BO">Bolivia</option>
                      <option value="BA">Bosnia and Herzegovina</option>
                      <option value="BW">Botswana</option>
                      <option value="BV">Bouvet Island</option>
                      <option value="BR">Brazil</option>
                      <option value="IO">British Indian Ocean Territory</option>
                      <option value="BN">Brunei Darussalam</option>
                      <option value="BG">Bulgaria</option>
                      <option value="BF">Burkina Faso</option>
                      <option value="BI">Burundi</option>
                      <option value="KH">Cambodia</option>
                      <option value="CM">Cameroon</option>
                      <option value="CA">Canada</option>
                      <option value="CV">Cape Verde</option>
                      <option value="KY">Cayman Islands</option>
                      <option value="CF">Central African Republic</option>
                      <option value="TD">Chad</option>
                      <option value="CL">Chile</option>
                      <option value="CN">China</option>
                      <option value="CX">Christmas Island</option>
                      <option value="CC">Cocos (Keeling) Islands</option>
                      <option value="CO">Colombia</option>
                      <option value="KM">Comoros</option>
                      <option value="CG">Congo</option>
                      <option value="CK">Cook Islands</option>
                      <option value="CR">Costa Rica</option>
                      <option value="HR">Croatia (Hrvatska)</option>
                      <option value="CU">Cuba</option>
                      <option value="CY">Cyprus</option>
                      <option value="CZ">Czech Republic</option>
                      <option value="CS">Czechoslovakia (former)</option>
                      <option value="DK">Denmark</option>
                      <option value="DJ">Djibouti</option>
                      <option value="DM">Dominica</option>
                      <option value="DO">Dominican Republic</option>
                      <option value="TP">East Timor</option>
                      <option value="EC">Ecuador</option>
                      <option value="EG">Egypt</option>
                      <option value="SV">El Salvador</option>
                      <option value="GQ">Equatorial Guinea</option>
                      <option value="ER">Eritrea</option>
                      <option value="EE">Estonia</option>
                      <option value="ET">Ethiopia</option>
                      <option value="FK">Falkland Islands (Malvinas)</option>
                      <option value="FO">Faroe Islands</option>
                      <option value="FJ">Fiji</option>
                      <option value="FI">Finland</option>
                      <option value="FR">France</option>
                      <option value="FX">France, Metropolitan</option>
                      <option value="GF">French Guiana</option>
                      <option value="PF">French Polynesia</option>
                      <option value="TF">French Southern Territories</option>
                      <option value="GA">Gabon</option>
                      <option value="GM">Gambia</option>
                      <option value="GE">Georgia</option>
                      <option value="DE">Germany</option>
                      <option value="GH">Ghana</option>
                      <option value="GI">Gibraltar</option>
                      <option value="GB">Great Britain (UK)</option>
                      <option value="GR">Greece</option>
                      <option value="GL">Greenland</option>
                      <option value="GD">Grenada</option>
                      <option value="GP">Guadeloupe</option>
                      <option value="GU">Guam</option>
                      <option value="GT">Guatemala</option>
                      <option value="GN">Guinea</option>
                      <option value="GW">Guinea-Bissau</option>
                      <option value="GY">Guyana</option>
                      <option value="HT">Haiti</option>
                      <option value="HM">Heard and McDonald Islands</option>
                      <option value="HN">Honduras</option>
                      <option value="HK">Hong Kong</option>
                      <option value="HU">Hungary</option>
                      <option value="IS">Iceland</option>
                      <option value="IN">India</option>
                      <option value="ID">Indonesia</option>
                      <option value="IR">Iran</option>
                      <option value="IQ">Iraq</option>
                      <option value="IE">Ireland</option>
                      <option value="IL">Israel</option>
                      <option value="IT">Italy</option>
                      <option value="JM">Jamaica</option>
                      <option value="JP">Japan</option>
                      <option value="JO">Jordan</option>
                      <option value="KZ">Kazakhstan</option>
                      <option value="KE">Kenya</option>
                      <option value="KI">Kiribati</option>
                      <option value="KP">Korea (North)</option>
                      <option value="KR">Korea (South)</option>
                      <option value="KW">Kuwait</option>
                      <option value="KG">Kyrgyzstan</option>
                      <option value="LA">Laos</option>
                      <option value="LV">Latvia</option>
                      <option value="LB">Lebanon</option>
                      <option value="LS">Lesotho</option>
                      <option value="LR">Liberia</option>
                      <option value="LY">Libya</option>
                      <option value="LI">Liechtenstein</option>
                      <option value="LT">Lithuania</option>
                      <option value="LU">Luxembourg</option>
                      <option value="MO">Macau</option>
                      <option value="MK">Macedonia</option>
                      <option value="MG">Madagascar</option>
                      <option value="MW">Malawi</option>
                      <option value="MY">Malaysia</option>
                      <option value="MV">Maldives</option>
                      <option value="ML">Mali</option>
                      <option value="MT">Malta</option>
                      <option value="MH">Marshall Islands</option>
                      <option value="MQ">Martinique</option>
                      <option value="MR">Mauritania</option>
                      <option value="MU">Mauritius</option>
                      <option value="YT">Mayotte</option>
                      <option value="MX">Mexico</option>
                      <option value="FM">Micronesia</option>
                      <option value="MD">Moldova</option>
                      <option value="MC">Monaco</option>
                      <option value="MN">Mongolia</option>
                      <option value="MS">Montserrat</option>
                      <option value="MA">Morocco</option>
                      <option value="MZ">Mozambique</option>
                      <option value="MM">Myanmar</option>
                      <option value="">N/A</option>
                      <option value="NA">Namibia</option>
                      <option value="NR">Nauru</option>
                      <option value="NP">Nepal</option>
                      <option value="NL">Netherlands</option>
                      <option value="AN">Netherlands Antilles</option>
                      <option value="NT">Neutral Zone</option>
                      <option value="NC">New Caledonia</option>
                      <option value="NZ">New Zealand (Aotearoa)</option>
                      <option value="NI">Nicaragua</option>
                      <option value="NE">Niger</option>
                      <option value="NG">Nigeria</option>
                      <option value="NU">Niue</option>
                      <option value="NF">Norfolk Island</option>
                      <option value="MP">Northern Mariana Islands</option>
                      <option value="NO">Norway</option>
                      <option value="OM">Oman</option>
                      <option value="PK">Pakistan</option>
                      <option value="PW">Palau</option>
                      <option value="PA">Panama</option>
                      <option value="PG">Papua New Guinea</option>
                      <option value="PY">Paraguay</option>
                      <option value="PE">Peru</option>
                      <option value="PH">Philippines</option>
                      <option value="PN">Pitcairn</option>
                      <option value="PL">Poland</option>
                      <option value="PT">Portugal</option>
                      <option value="PR">Puerto Rico</option>
                      <option value="QA">Qatar</option>
                      <option value="RE">Reunion</option>
                      <option value="RO">Romania</option>
                      <option value="RU">Russian Federation</option>
                      <option value="RW">Rwanda</option>
                      <option value="GS">S. Georgia and S. Sandwich Isls.</option>
                      <option value="KN">Saint Kitts and Nevis</option>
                      <option value="LC">Saint Lucia</option>
                      <option value="VC">Saint Vincent and the Grenadines</option>
                      <option value="WS">Samoa</option>
                      <option value="SM">San Marino</option>
                      <option value="ST">Sao Tome and Principe</option>
                      <option value="SA">Saudi Arabia</option>
                      <option value="SN">Senegal</option>
                      <option value="SC">Seychelles</option>
                      <option value="SL">Sierra Leone</option>
                      <option value="SG">Singapore</option>
                      <option value="SK">Slovak Republic</option>
                      <option value="SI">Slovenia</option>
                      <option value="SB">Solomon Islands</option>
                      <option value="SO">Somalia</option>
                      <option value="ZA">South Africa</option>
                      <option value="ES">Spain</option>
                      <option value="LK">Sri Lanka</option>
                      <option value="SH">St. Helena</option>
                      <option value="PM">St. Pierre and Miquelon</option>
                      <option value="SD">Sudan</option>
                      <option value="SR">Suriname</option>
                      <option value="SJ">Svalbard and Jan Mayen Islands</option>
                      <option value="SZ">Swaziland</option>
                      <option value="SE">Sweden</option>
                      <option value="CH">Switzerland</option>
                      <option value="SY">Syria</option>
                      <option value="TW">Taiwan</option>
                      <option value="TJ">Tajikistan</option>
                      <option value="TZ">Tanzania</option>
                      <option value="TH">Thailand</option>
                      <option value="TG">Togo</option>
                      <option value="TK">Tokelau</option>
                      <option value="TO">Tonga</option>
                      <option value="TT">Trinidad and Tobago</option>
                      <option value="TN">Tunisia</option>
                      <option value="TR">Turkey</option>
                      <option value="TM">Turkmenistan</option>
                      <option value="TC">Turks and Caicos Islands</option>
                      <option value="TV">Tuvalu</option>
                      <option value="UM">US Minor Outlying Islands</option>
                      <option value="SU">USSR (former)</option>
                      <option value="UG">Uganda</option>
                      <option value="UA">Ukraine</option>
                      <option value="AE">United Arab Emirates</option>
                      <option value="UK">United Kingdom</option>
                      <option value="US" selected="selected">United States</option>
                      <option value="UY">Uruguay</option>
                      <option value="UZ">Uzbekistan</option>
                      <option value="VU">Vanuatu</option>
                      <option value="VA">Vatican City State (Holy See)</option>
                      <option value="VE">Venezuela</option>
                      <option value="VN">Viet Nam</option>
                      <option value="VG">Virgin Islands (British)</option>
                      <option value="VI">Virgin Islands (U.S.)</option>
                      <option value="WF">Wallis and Futuna Islands</option>
                      <option value="EH">Western Sahara</option>
                      <option value="YE">Yemen</option>
                      <option value="YU">Yugoslavia</option>
                      <option value="ZR">Zaire</option>
                      <option value="ZM">Zambia</option>
                      <option value="ZW">Zimbabwe</option>
                    </select>
                    <b>*</b> </td>
                </tr>
                <tr>
                  <td width="97" bgcolor="#00548F" class="page-content"><font color="#FFFFFF"><b>Daytime Phone:</b></font></td>
                  <td width="288" class="page-content">
                    <input name="billing_daytime_phone" type="text" />
                    <b>*</b><br />
      (i.e. (123)555-1212)</td>
                </tr>
                <tr>
                  <td width="97" bgcolor="#00548F" class="page-content"><font color="#FFFFFF"><b>Card Type:</b></font></td>
                  <td width="288" class="page-content">
                    <select name="billing_card_type">
                      <option selected="">Choose Card Type</option>
                      <option value="V">Visa</option>
                      <option value="M">Master Card</option>
                    </select>
                    <b>*</b> </td>
                </tr>
                <tr>
                  <td width="97" bgcolor="#00548F" class="page-content"><font color="#FFFFFF"><b>Name on Card:</b></font></td>
                  <td width="288" class="page-content">
                    <input name="billing_name_on_card" type="text" />
                    <b>*</b> </td>
                </tr>
                <tr>
                  <td width="97" bgcolor="#00548F" class="page-content"><font color="#FFFFFF"><b>Credit Card Number :</b></font></td>
                  <td width="288" class="page-content">
                    <input name="billing_card_number" type="text" />
      *<br />
      (no spaces or dashes) i.e.1234567890121234 (use Visa and 4111111111111111 for testing)</td>
                </tr>
                <tr>
                  <td width="97" bgcolor="#00548F" class="page-content"><font color="#FFFFFF"><b>Expiration Date:</b></font></td>
                  <td width="288" class="page-content">
                    <input name="creditcard_expire" type="text" size="5" />
      (in format: MM/YY)&nbsp; *</td>
                </tr>
                <tr bgcolor="#FFFFFF">
                  <td width="97"><b></b></td>
                  <td width="288" class="page-content">                    <p><b>Your credit information will be sent through a secure and encrypted channel. After submit has been selected, order cannot be changed or cancelled. </b><br />
                        <input name="Submit" type="submit" value="Proceed to confirmation " />                         <font color="#CC0000"> <i> <b><br /> </b> </i></font></p>
                    <p>&nbsp;</p>
                    <p><b>#</b> Your e-mail address will be used only for receipt purposes and to contact you if there is a problem with your order and we cannot reach you by phone. </p>
                  </td>
                </tr>
              </table></td>
            </tr>
          </table>
          </form></td>
        </tr>
      </table>
    <!-- #EndEditable --> </td>
  </tr>
</table>
</body>
<!-- #EndTemplate --></html>

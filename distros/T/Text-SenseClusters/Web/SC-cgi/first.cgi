#!/usr/local/bin/perl -w

# This script mostly upload the required test and 
# training data along with other necessary files. 

use CGI;

$q=new CGI;

print "Content-type: text/html\n\n";

my $host = $ENV{'HTTP_HOST'};

$clustype=$q->param("clustype");

print "<html>
<head>
<title>SenseClusters</title>
</head>
<body>

<!-outermost table which divides the screen in 2 parts-->
<table width=100% height=100% border=1>
<tr>
<td bgcolor=#CFCFCF>

<table width=100% border=0>
<tr>
<td>
<a href=\"http://www.d.umn.edu\"><img src=\"http://$host/SC-htdocs/umdlogo.jpg\" border=0 width=\"100\" height=\"60\"></a>
</td>
<td>
<h1><center>
<a href=\"http://senseclusters.sourceforge.net/\">SenseClusters</a> Web Interface
</center></h1>
<center>
<h3>Clusters text instances based on their contextual similarity ...</h3>
</center>
</td>
</tr>
</table>

</td>
</tr>
<tr>
<td bgcolor=#EDEDED>

<form action=\"second.cgi\" method=\"POST\" enctype=\"multipart/form-data\">
<h3>Step 1: </h3>

<table border=0>
<tr>
<td>
<a href=\"http://$host/SC-htdocs/help.html#test\">TEST File</a> (SENSEVAL-2 Format)
</td>
<td colspan=2>
<input type=\"file\" name=\"testfile\" size=50> 
Required Argument
</td>
</tr>";

if($clustype eq "hclust" || $clustype eq "lsa-hclust")
{
print "
<tr>
<td>
<a href=\"http://$host/SC-htdocs/help.html#scope_test_s2\">TEST Scope</a> 
</td>
<td colspan=2>
<input type=\"text\" name=\"scope_test\" maxlength=5 size=10>
Default scope=complete instance
</td>
</tr>";

print "
<tr>
<td>
<a href=\"http://$host/SC-htdocs/help.html#split_n\">Split TEST</a> 
</td>
<td colspan=2>
<input type=\"text\" name=\"split\" maxlength=2 size=4>
(Do not use if TRAIN file specified)
</td>
</tr>";

print "<tr><td>" . $q->a({-href=>"http://$host/SC-htdocs/help.html#feature_type"},"Features type"), "</td><td>", $q->popup_menu(-name=>'feature', -values=>['bi','coc','tco','uni'], -default=>'bi', -labels=>{bi=>'bigram', coc=>'co-occurrence',tco=>'target co-occurrences', uni=>'unigram'}),"</td><td colspan=2><br></td></tr>";

print "
<tr>
<td colspan=3>
<br>
</td>
</tr>
<tr>
<td>
<a href=\"http://$host/SC-htdocs/help.html#training_train\">TRAIN File</a> (Plain Text Format)
</td>
<td>
<input type=\"file\" name=\"trainfile\" size=50>
</td>
<td>
Default [TRAIN=TEST]
</td>
</tr>";

print "
<tr>
<td>
<a href=\"http://$host/SC-htdocs/help.html#scope_train_s1\">TRAIN Scope</a>
</td>
<td colspan=2>
<input type=\"text\" name=\"scope_train\" maxlength=5 size=10>
Default scope=complete instance
</td>
</tr>";

print "
<tr>
<td>
<a href=\"http://$host/SC-htdocs/help.html#target_target\">TARGET-Word File</a>
</td>
<td>
<input type=\"file\" name=\"target\" size=50>
</td>
<td>";
print "<a href=\"http://$host/SC-htdocs/target.regex\">Default File</a>
</td>
</tr>";

}

elsif($clustype eq "hlclust" || $clustype eq "lsa-hlclust")
{

print "
<tr>
<td>
<a href=\"http://$host/SC-htdocs/help.html#split_n\">Split TEST</a> 
</td>
<td colspan=2>
<input type=\"text\" name=\"split\" maxlength=2 size=4>
(Do not use if TRAIN file specified)
</td>
</tr>";

print "<tr><td>" . $q->a({-href=>"http://$host/SC-htdocs/help.html#feature_type"},"Features type"), "</td><td>", $q->popup_menu(-name=>'feature', -values=>['bi','coc','uni'], -default=>'bi', -labels=>{bi=>'bigram', coc=>'co-occurrence', uni=>'unigram'}),"</td><td colspan=2><br></td></tr>";

print "
<tr>
<td colspan=3>
<br>
</td>
</tr>
<tr>
<td>
<a href=\"http://$host/SC-htdocs/help.html#training_train\">TRAIN File</a> (Plain Text Format)
</td>
<td>
<input type=\"file\" name=\"trainfile\" size=50>
</td>
<td>
Default [TRAIN=TEST]
</td>
</tr>";

}


elsif($clustype eq "wclust")
{
print "<tr><td>" . $q->a({-href=>"http://$host/SC-htdocs/help.html#feature_type"},"Features type"), "</td><td>", $q->popup_menu(-name=>'feature', -values=>['bi','coc'], -default=>'bi', -labels=>{bi=>'bigram', coc=>'co-occurrence'}),"</td><td colspan=2><br></td></tr>";
}

elsif($clustype eq "lsa-fclust")
{
print "<tr><td>" . $q->a({-href=>"http://$host/SC-htdocs/help.html#feature_type"},"Features type"), "</td><td>", $q->popup_menu(-name=>'feature', -values=>['bi','coc', 'uni'], -default=>'bi', -labels=>{bi=>'bigram', coc=>'co-occurrence', uni=>'unigram'}),"</td><td colspan=2><br></td></tr>";
}

print "
<tr>
<td colspan=3>
<br>
</td>
</tr>
";

print "<tr><td><a href=\"http://$host/SC-htdocs/help.html#prefix_pre\">Prefix</a></td>
<td colspan=2>
<input type=\"text\" name=\"prefix\" size=30  maxlength=20> Default=user
</td>
</tr>

<tr>
<td>
<a href=\"http://$host/SC-htdocs/help.html#token_token\">TOKEN File</a> 
</td>
<td>
<input type=\"file\" name=\"token\" size=50>
</td>
<td>
<a href=\"http://$host/SC-htdocs/token.regex\">Default File</a>
</td>
</tr>
";

print "<tr><td>", $q->a({-href=>"http://$host/SC-htdocs/help.html#format_f16_xx"}, "Precision"), "  </td><td colspan=2>", $q->popup_menu(-name=>'precision', -values=>['00','01','02','03','04','05','06','07','08','09','10','11','12','13','14','15'], -default=>'06'), "</td></tr>";

print "
</table>

<br>

<table width=100% cellpadding=5>
<tr>
<td align=right>
<input type=\"reset\" value=\"Clear All\">
</td>
<td align=left>
<input type=\"submit\" value=\"Upload Data\">
</td>
</tr>
</table>

<br>
";

print $q->hidden(-name=>'clustype', -value=>$clustype);

print "
</form>
<a href=\"http://$host/SC-htdocs/help.html\">Help</a>

</td>
</tr>
</table>
</body>
</html>";

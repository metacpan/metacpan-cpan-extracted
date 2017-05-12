#!/usr/local/bin/perl -w

# The starting script for the web-interface.

use CGI;

$q=new CGI;

print "Content-type: text/html\n\n";

my $host = $ENV{'HTTP_HOST'};

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
<h3>Cluster contexts and words based on contextual similarity ...</h3>
</center>
</td>
</tr>
</table>

</td>
</tr>

<tr>
<td bgcolor=#EDEDED>

<form action=\"first.cgi\" method=\"POST\" enctype=\"multipart/form-data\">
<h3><a href=\"http://$host/SC-htdocs/sc_methodology.html\">SenseClusters Native Methodology</a>: </h3>
<table border=0>
<tr>
<td>
<input type=\"radio\" name=\"clustype\" value=\"hclust\" checked> 
</td>
<td>
1. <a href=\"http://$host/SC-htdocs/headword_clust.html\">Target Word Clustering</a> (eg: name or word sense discrimination)
</td>
</tr>

<tr>
<td>
<input type=\"radio\" name=\"clustype\" value=\"hlclust\"> 
</td>
<td>
2. <a href=\"http://$host/SC-htdocs/headless_clust.html\">Headless Clustering</a> (eg: email clustering)
</td>
</tr>

<tr>
<td>
<input type=\"radio\" name=\"clustype\" value=\"wclust\" > 
</td>
<td>
3. <a href=\"http://$host/SC-htdocs/word_clust.html\">Word Clustering</a> (eg: synonym finding)
</td>
</tr>
</table>

<br><br>

<h3><a href=\"http://$host/SC-htdocs/lsa.html\">Latent Semantic Analysis (LSA)</a>: </h3>
<table border=0>
<tr>
<td>
<input type=\"radio\" name=\"clustype\" value=\"lsa-hclust\" > 
</td>
<td>
1. <a href=\"http://$host/SC-htdocs/headword_lsa_clust.html\"> Target Word Clustering</a> 
</td>
</tr>

<tr>
<td>
<input type=\"radio\" name=\"clustype\" value=\"lsa-hlclust\" > 
</td>
<td>
2. <a href=\"http://$host/SC-htdocs/headless_lsa_clust.html\">Headless Clustering</a> 
</td>
</tr>

<tr>
<td>
<input type=\"radio\" name=\"clustype\" value=\"lsa-fclust\" > 
</td>
<td>
3. <a href=\"http://$host/SC-htdocs/feature_clust.html\">Feature Clustering</a>
</td>
</tr>

</table>
<br><br>
";

print "
<table width=100% cellpadding=5>
<tr>
<td>
<input type=\"submit\" value=\"Proceed\">
</td>
</tr>
</table>

<br>

</form>
<a href=\"http://$host/SC-htdocs/help.html\">Help</a>

</td>
</tr>
</table>

</body>
</html>";

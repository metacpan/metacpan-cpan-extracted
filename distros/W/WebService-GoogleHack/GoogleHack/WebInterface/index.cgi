#!/usr/local/bin/perl -w

=head1 WebService::Google-Hack Web Interface

=head1 SYNOPSIS

The WebService::Google-Hack web interface provides an easy to use interface
for some of the features of WebService::Google-Hack.

=head1 DESCRIPTION

To install the interface please follow these steps:

1) Create a directory named ghack in your cgi-bin directory (Where all your cgi files reside). So it should be something like:

/webspace/cgi-bin/ghack

2) Next, copy the file named google_hack.cgi, which is given with the 
distribution of the google-hack package into your cgi-bin/ghack/ directory.

3) Open the index.cgi file.

*Note:
The index.cgi file is in the WebInterface directory of GoogleHack.
For eg: WebService/GoogleHack/WebInterface/.

4) Now, in the index.cgi  file (which is also given in the  WebInterface directory of GoogleHack),

Set the remote_host, and remote_port variables to the correct values.

$remote_host = '';

$remote_port = '';

The remote host will be the IP address of the machine where the google_hack server will be running.
The remote port needs to be the same as the $LOCALPORT variable in ghack_server.pl

5) Set the defaultKey variable to your default Google-API key.

    $defaultKey="XXXXXXXXX";

You should now be able to use the web interface.

=head1 AUTHOR

Ted Pedersen, E<lt>tpederse@d.umn.eduE<gt> 

Pratheepan Raveendranathan, E<lt>rave0029@d.umn.eduE<gt> 

Jason Michelizzi, E<lt>mich0212@d.umn.eduE<gt>

Date 11/08/2004

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003 by Pratheepan Raveendranathan, Ted Pedersen, Jason Michelizzi

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to

The Free Software Foundation, Inc.,
59 Temple Place - Suite 330,
Boston, MA  02111-1307, USA.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

use strict;

##########################################################
# Change to host ip address and port                     #
##########################################################
my $remote_host = '111.111.11.111';
my $remote_port = '32983';

##########################################################
# Change to default API key                              #
##########################################################
my $defaultKey="W3EDt6dQFHIBN/qfbniXjwvaf7SFXh0U";

use CGI;
use Socket;


BEGIN {
    # Our University's webserver uses an ancient version of CGI::Carp
    # so we can't do fatalsToBrowser.
    # The carpout() function lets us modify the format of messages sent to
    # a filehandle (in this case STDERR) to include timestamps
    use CGI::Carp 'carpout';
    carpout(*STDOUT);
}

my $cgi = CGI->new;

# These are the colors of the text when we alternate text colors (when
# showing errors, for example).
my $text_color1 = 'black';
my $text_color2 = '#d03000';


print $cgi->header;

my $action=$cgi->param ('action');
my $type=$cgi->param ('opt');
my $key = $cgi->param ('apikey');

my $words;
my $frequency;
my $numPages;
my $numIterations;
my $scoreType;
my $scoreCutOff;
my $wordS1;
my $wordS2;
my $review;
my $text;

if(!defined($action))
{
    $action="first";
}

if($action eq "first")
{
    showPageStart();
}


if($action eq "Submit")
{
    
    if($type eq "wordcluster")
    {
	
	WordClusters();
    }
    if($type eq "wordcluster2")
    {	
	WordClusters2();
    }
    elsif($type eq "pmi")
    {
	PMI();
    }
    elsif($type eq "review")
    {
	Review();
    } 
    elsif($type eq "words")
    {
	SemanticWords();
    }
    elsif($type eq "phrases")
    {
	SemanticPhrases();
    }
    
}

if($action eq "Generate")
{
  
  #  $words = $cgi->param ('words');;  print $words;
    $words = $cgi->param ('searchString1')." ".$cgi->param ('searchString2');
#    print $words;
    $frequency = $cgi->param ('cutoff');;
    $numPages = $cgi->param ('numres');;
    $numIterations=$cgi->param ('numiters');;;

    if($cgi->param ('apikey') ne "")
    {
	$key=$cgi->param ('apikey'); 
    }
    else
    {
	$key="$defaultKey";
    }

    generateWordCluster();
#$numIterations = $cgi->param ('apikey');;
    
}

if($action eq "Generate2")
{
  
  #  $words = $cgi->param ('words');;  print $words;
    $words = $cgi->param ('searchString1').":".$cgi->param ('searchString2');
    print $words;
    $frequency = $cgi->param ('cutoff');;
    $numPages = $cgi->param ('numres');;
    $numIterations=$cgi->param ('numiters');;;
    $scoreType=$cgi->param ('scoretype');
    $scoreCutOff=$cgi->param ('scorecutoff');

    if($cgi->param ('apikey') ne "")
    {
	$key=$cgi->param ('apikey'); 
    }
    else
    {
	$key="$defaultKey";
    }

    generateWordCluster2();
#$numIterations = $cgi->param ('apikey');;
    
}

if($action eq "PMIMeasure")
{
    
    
    $wordS1 = $cgi->param ('searchString1');
    $wordS2 = $cgi->param ('searchString2');

    if($cgi->param ('apikey') ne "")
    {
	$key=$cgi->param ('apikey'); 
    }
    else
    {
	$key="$defaultKey";
    }

    generatePMI();
#$numIterations = $cgi->param ('apikey');;
    
}

if($action eq "Predict")
{       
    $wordS1 = $cgi->param ('searchString1');
    $wordS2 = $cgi->param ('searchString2');
    $review= $cgi->param ('review');

    if($cgi->param ('apikey') ne "")
    {
	$key=$cgi->param ('apikey'); 
    }
    else
    {
	$key="$defaultKey";
    }

    predictReview();    
}

if($action eq "Semantic")
{       
    $wordS1 = $cgi->param ('searchString1');
    $wordS2 = $cgi->param ('searchString2');
    $text= $cgi->param ('text');

    if($cgi->param ('apikey') ne "")
    {
	$key=$cgi->param ('apikey'); 
    }
    else
    {
	$key="$defaultKey";
    }

    predictSemanticWords();    
}

if($action eq "SemanticPhrases")
{       
    $wordS1 = $cgi->param ('searchString1');
    $wordS2 = $cgi->param ('searchString2');
    $text= $cgi->param ('text');

    if($cgi->param ('apikey') ne "")
    {
	$key=$cgi->param ('apikey'); 
    }
    else
    {
	$key="$defaultKey";
    }

    predictSemanticPhrases();    
}

showPageEnd ();
exit;

# ========= subroutines =========

sub round ($)
{
    my $num = shift;
    my $str = sprintf ("%.4f", $num);
    $str =~ s/\.?0+$//;

    return $str;
}


sub showPageStart
{
    print <<"EOINTRO";
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  <title>Google-Hack</title>
  <link rel="stylesheet" href="sim-style.css" type="text/css" />
</head>
<body>

<br></font><font size="4"><b>
</font><font size="4" > <font face="Arial">G O O G L E
&nbsp; -&nbsp; H A C K&nbsp;&nbsp;</font></b></font>
<br>
<hr></hr>

<form action="index.cgi" method="get" id="queryform" onreset="formReset()">
 <br>
   <label for="word1in" class="leftlabel">Which feature would you like to use?</label>

   <select name="opt">
        <option value="wordcluster"> Sets of Related Words -- Algorithm 1</option>   
	<option value="wordcluster2"> Sets of Related Words -- Algorithm 2</option>
        <option value="pmi">PMI Measure</option> 
	<option value="review"> Semantic Orientation of Review</option>	
	<option value="words"> Semantic Orientation of Words</option>	
	<option value="phrases"> Semantic Orientation of Phrases</option>
                 </select>

 &nbsp; <a href="options.cgi">Learn more about each option</a>

<br />

<br><br>
  <label><b>Google API Key:</b></label>
  <input type="text" name="apikey" value="" > &nbsp;
<br><br>
(Please enter your Google API license key here, if you dont have one you can get it @  <a href="http://www.google.com/apis/"> http://www.google.com/apis</a>. <br>Or to proceed with default google-hack developer\'s key, select the feature that you would like to use and click on  submit.)

 <br>

  <br> 
      <input name="action" type="submit" value="Submit" />  <br>   


<font color="black">
<h3 align="left"><b>Project Information</b></h3>

<a href="http://google-hack.sf.net"> Project Information
</a>
<br>
<a name='Developers'>
<font color="black">
<h3 align="left"><b>Developers</b></h3>

<a href="http://www.d.umn.edu/~tpederse">

Ted Pedersen
</a>, &nbsp;&nbsp;
<a href="http://www.d.umn.edu/~rave0029/research">

Pratheepan Raveendranathan

</a>

EOINTRO
}


sub WordClusters
{
print <<"Word_Clusters";
<br>
<font size="4" > <font face="Arial" color="darkblue"><B>G O O G L E
- H A C K&nbsp;&nbsp;</font></B></font>

<hr></hr>
<form action="index.cgi" method="get" id="queryform" onreset="formReset()">
<h2> Word Clusters --- Algorithm 1 - Baseline Approach </h2>
(Baseline algorithm)
<H2><b> Set Parameters</b> </H2>


<label><b>Top "N" web Pages:</b></label>
Word_Clusters

	print "<select name=\"numres\">\n";

for(my $i=10; $i <= 30; $i=$i+10)
{

       	    print "<option value=\"$i\">";
	    print $i;
	    print "</option>\n";
	
}
	print "</select> (This will be the number of web pages to parse, Defaults to 10, Maximum 50 )<br />\n";

print "<input type=\"hidden\" name=\"apikey\" value=\"$key\">";
print <<"Word_Clusters1";

<br>
<label><b>Frequency Cutoff &nbsp;&nbsp;&nbsp;: </b></label>

Word_Clusters1

	print "<select name=\"cutoff\">\n";

for(my $i=5; $i <= 25; $i++)
{
if($i==5)
{
  print "<option select value=\"$i\">";
     print $i;
     print "</option>\n ";
}
 else
{
     print "<option value=\"$i\">";
     print $i;
     print "</option>\n";
}
	
}
	print "</select> (Words with frequency less than given would not be considered, Max 20)<br />\n";

print <<"Word_Clusters2";
<br><label><b>No of Iterations&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;:</b></label>
Word_Clusters2
	print "<select name=\"numiters\">\n";

for(my $i=1; $i <= 2; $i++)
{

       	    print "<option value=\"$i\">";
	    print $i;
	    print "</option>\n";
	
}
	print "</select> (This will be the number of iterations)<br />\n";

    print <<"Word_Clusters3";
<br>  <label><b>Example&nbsp;&nbsp;</b>&nbsp;&nbsp;(For example, type in "rachel" & "ross", and set the number of web pages to 10, and the frequency cut off to 20)</label>
<br><br> 
(Accepts ONLY single word as input)
<br><br>
  <label><b>Word 1&nbsp;&nbsp;&nbsp;&nbsp;:</b></label>
<input type="text" name="searchString1" value="" > (Enter a word like "toyota") 
<br><br>
<label><b>Word 2&nbsp;&nbsp;&nbsp;&nbsp;:</b></label>
<input type="text" name="searchString2" value=""> (Enter a word like "ford")<br><br>

      <input name="action" type="submit" value="Generate" />


      <input name="action" type="submit" value="Back" />

 </form> 
Word_Clusters3

}

sub generateWordCluster
{
 socket (Server, PF_INET, SOCK_STREAM, getprotobyname ('tcp'));

    my $internet_addr = inet_aton ($remote_host)
	or die "Could not convert $remote_host to an Internet addr: $!\n";
    my $paddr = sockaddr_in ($remote_port, $internet_addr);

    unless (connect (Server, $paddr)) {
	print "<p>Cannot connect to server $remote_host:$remote_port</p>\n";
	close Server;
    }

 select ((select (Server), $|=1)[0]);
 
 $words=~s/\s+/:/g;
 print Server "c\t$key\t$words\t$numPages\t$frequency\t$numIterations\t\015\012\015\012";
 print <<"temp";
<B><p><font face="Arial" size="5" >p r o j e c t  &nbsp; </font> </B>
</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp; <font size="6">&nbsp;</font><font size="4"><b>
</b>&nbsp;</font><font size="4" > <font face="Arial">g o o g l e
&nbsp;&nbsp; - h a c k&nbsp;&nbsp;</font></font></p>

<hr></hr>
temp

 print "\n<B>Google Hack Word Cluster Results for </B>";

            my @terms=();
	    my @temp= split(/:/, $words);
	    
	    foreach my $word (@temp)
	    {
	       if($word ne "")
	       {
		   print "<br>$word";
	       }
	   
	    }

 print "<br><br> Frequency Cutoff: $frequency <br># of Web Pages: $numPages <br># of Iterations: $numIterations<br>" ;

 while (my $line = <Server>) {
     last if $line eq "\015\012";
     print "<br>$line";
     
 }
 
 local $ENV{PATH} = "/usr/local/bin:/usr/bin:/bin:/ghack";
 my $t_osinfo = `uname -a` || "Couldn't get system information: $!";
 # $t_osinfo is tainted.  Use it in a pattern match and $1 will
 # be untainted.
 $t_osinfo =~ /(.*)/;
#    print "<p>HTTP server: $ENV{HTTP_HOST} ($1)</p>\n";
#    print "<p>Google server: $remote_host</p>\n";
 print "<hr />";
 close Server;
}


sub WordClusters2
{
print <<"Word_Clusters";
<br>
<font size="4" > <font face="Arial" color="darkblue"><B>G O O G L E
- H A C K&nbsp;&nbsp;</font></B></font>

<hr></hr>
<form action="index.cgi" method="get" id="queryform" onreset="formReset()">
<h2> Word Clusters --- Algorithm 2 - Beta Version </h2>
<H2><b> Set Parameters</b> </H2>


<label><b>Top "N" web Pages:</b></label>
Word_Clusters

	print "<select name=\"numres\">\n";

for(my $i=10; $i <= 30; $i=$i+10)
{

       	    print "<option value=\"$i\">";
	    print $i;
	    print "</option>\n";
	
}
	print "</select> (This will be the number of web pages to parse, Defaults to 10, Maximum 50 )<br />\n";

print "<input type=\"hidden\" name=\"apikey\" value=\"$key\">";
print <<"Word_Clusters1";

<br>
<label><b>Frequency Cutoff &nbsp;&nbsp;&nbsp;: </b></label>

Word_Clusters1

	print "<select name=\"cutoff\">\n";

for(my $i=5; $i <= 25; $i++)
{
if($i==5)
{
  print "<option select value=\"$i\">";
     print $i;
     print "</option>\n ";
}
 else
{
     print "<option value=\"$i\">";
     print $i;
     print "</option>\n";
}
	
}
	print "</select> (Words with frequency less than given would not be considered, Max 20)<br />\n";

print <<"Word_Clusters1";

<br>
   <label for="word1in" class="leftlabel"><b>Relatedness Score&nbsp;&nbsp;&nbsp;: </b></label>

   <select name="scoretype">
        <option value="1"> Measure 1</option>   
	<option value="2"> Measure 2</option>
        <option value="3"> Measure 3</option> 
                 </select>
 <br>
<br>&nbsp;&nbsp;&nbsp;&nbsp;<font color="darkblue"><b>Measure 1 : </b>log(hits(w1)) + log(hits(w2)) - log(hits(w1w2))<br>&nbsp;&nbsp;&nbsp;&nbsp;<b>Measure 2 : </b>log( hits(w1w2) / (hits(w1) + hits(w2)))<br>&nbsp;&nbsp;&nbsp;&nbsp;<b>Measure 3 : </b>log( hits(w1w2) / (hits(w1) * hits(w2)))</font>
<br />

<br>
<label><b>Relatedness Score Cutoff &nbsp;&nbsp;&nbsp;: </b></label>

Word_Clusters1

	print "<select name=\"scorecutoff\">\n";

for(my $i=60; $i >= 30; $i=$i-5)
{

     print "<option value=\"$i\">";
     print $i;
     print "</option>\n";
}
	print "</select> (Words with relatedness score greater than given would not be considered, Max 60)<br />\n";

print <<"Word_Clusters2";
<br><label><b>No of Iterations&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;:</b></label>
Word_Clusters2
	print "<select name=\"numiters\">\n";

for(my $i=1; $i <= 2; $i++)
{

       	    print "<option value=\"$i\">";
	    print $i;
	    print "</option>\n";
	
}
	print "</select> (This will be the number of iterations)<br />\n";

    print <<"Word_Clusters3";
<br>  <label><b>Example&nbsp;&nbsp;</b>&nbsp;&nbsp;(For example, type in "rachel" & "ross", or "george bush" & "bill clinton" and set the number of web pages to 10, and the frequency cut off to 20)</label>
<br><br> 
(Accepts Uni-Grams or Bi-Grams as input)
<br><br>
  <label><b>Word 1&nbsp;&nbsp;&nbsp;&nbsp;:</b></label>
<input type="text" name="searchString1" value="" > (Enter a word like "toyota") 
<br><br>
<label><b>Word 2&nbsp;&nbsp;&nbsp;&nbsp;:</b></label>
<input type="text" name="searchString2" value=""> (Enter a word like "ford")<br><br>

      <input name="action" type="submit" value="Generate2" />


      <input name="action" type="submit" value="Back" />

 </form> 
Word_Clusters3

}

sub generateWordCluster2
{
 socket (Server, PF_INET, SOCK_STREAM, getprotobyname ('tcp'));

    my $internet_addr = inet_aton ($remote_host)
	or die "Could not convert $remote_host to an Internet addr: $!\n";
    my $paddr = sockaddr_in ($remote_port, $internet_addr);

    unless (connect (Server, $paddr)) {
	print "<p>Cannot connect to server $remote_host:$remote_port</p>\n";
	close Server;
    }

 select ((select (Server), $|=1)[0]);
 
 #$words=~s/\s+/:/g;
 print Server "g\t$key\t$words\t$numPages\t$frequency\t$numIterations\t$scoreType\t$scoreCutOff\t\015\012\015\012";
 print <<"temp";
<B><p><font face="Arial" size="5" >p r o j e c t  &nbsp; </font> </B>
</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp; <font size="6">&nbsp;</font><font size="4"><b>
</b>&nbsp;</font><font size="4" > <font face="Arial">g o o g l e
&nbsp;&nbsp; - h a c k&nbsp;&nbsp;</font></font></p>

<hr></hr>
temp

 print "\n<B>Google Hack Word Cluster Algorithm 2 Results for </B>";

            my @terms=();
	    my @temp= split(/:/, $words);
	    
	    foreach my $word (@temp)
	    {
	       if($word ne "")
	       {
		   print "<br>$word";
	       }
	   
	    }

 print "<br><br> Frequency Cutoff: $frequency <br># of Web Pages: $numPages <br># of Iterations: $numIterations<br>" ;

 while (my $line = <Server>) {
     last if $line eq "\015\012";
     print "<br>$line";
     
 }
 
 local $ENV{PATH} = "/usr/local/bin:/usr/bin:/bin:/ghack";
 my $t_osinfo = `uname -a` || "Couldn't get system information: $!";
 # $t_osinfo is tainted.  Use it in a pattern match and $1 will
 # be untainted.
 $t_osinfo =~ /(.*)/;
#    print "<p>HTTP server: $ENV{HTTP_HOST} ($1)</p>\n";
#    print "<p>Google server: $remote_host</p>\n";
 print "<hr />";
 close Server;
}

sub PMI
{
print <<"PMI";
<B><p><font face="Arial" size="5" >p r o j e c t  &nbsp; </font> </B>
</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp; <font size="6">&nbsp;</font><font size="4"><b>
</b>&nbsp;</font><font size="4" > <font face="Arial">g o o g l e
&nbsp;&nbsp; - h a c k&nbsp;&nbsp;</font></font></p>

<hr></hr>
<form action="index.cgi" method="get"  onreset="formReset()">
<h2> PMI Measure </h2>
(This feature allows you to find the Pointwise Mutual Information measure between two terms)<br><br>
  <label><b>Search String 1:</b></label>
<input type="text" name="searchString1" value="" > (Enter a term like dog) 
<br><br>
<label><b>Search String 2:</b></label>
<input type="text" name="searchString2" value=""> (Enter a term like cat)<br><br>
PMI
print "<input type=\"hidden\" name=\"apikey\" value=\"$key\">";
print <<"PMIR";
      <input name="action" type="submit" value="PMIMeasure" />
      <input name="action" type="submit" value="Back" />

 </form> 
PMIR

}


sub generatePMI
{
 socket (Server, PF_INET, SOCK_STREAM, getprotobyname ('tcp'));

    my $internet_addr = inet_aton ($remote_host)
	or die "Could not convert $remote_host to an Internet addr: $!\n";
    my $paddr = sockaddr_in ($remote_port, $internet_addr);

    unless (connect (Server, $paddr)) {
	print "<p>Cannot connect to server $remote_host:$remote_port</p>\n";
	close Server;
    }

 select ((select (Server), $|=1)[0]);
 
 $wordS1=~s/\s+//g;
 $wordS2=~s/\s+//g;

 print Server "p\t$key\t$wordS1\t$wordS2\015\012\015\012";
 print <<"temp";
<B><p><font face="Arial" size="5" >p r o j e c t  &nbsp; </font> </B>
</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp; <font size="6">&nbsp;</font><font size="4"><b>
</b>&nbsp;</font><font size="4" > <font face="Arial">g o o g l e
&nbsp;&nbsp; - h a c k&nbsp;&nbsp;</font></font></p>

<hr></hr>
temp

 print "\n<B>Google Hack PMI Measure for </B>";

 print "<br>$wordS1 AND $wordS2";

 print "<br>PMI Measure: ";

 while (my $line = <Server>) {
     last if $line eq "\015\012";
     print "<br>$line";
     
 }
 
 local $ENV{PATH} = "/usr/local/bin:/usr/bin:/bin:/ghack";
 my $t_osinfo = `uname -a` || "Couldn't get system information: $!";
 # $t_osinfo is tainted.  Use it in a pattern match and $1 will
 # be untainted.
 $t_osinfo =~ /(.*)/;
#    print "<p>HTTP server: $ENV{HTTP_HOST} ($1)</p>\n";
#    print "<p>Google server: $remote_host</p>\n";
 print "<hr />";
 close Server;
}

sub predictReview
{
 socket (Server, PF_INET, SOCK_STREAM, getprotobyname ('tcp'));

    my $internet_addr = inet_aton ($remote_host)
	or die "Could not convert $remote_host to an Internet addr: $!\n";
    my $paddr = sockaddr_in ($remote_port, $internet_addr);

    unless (connect (Server, $paddr)) {
	print "<p>Cannot connect to server $remote_host:$remote_port</p>\n";
	close Server;
    }

 select ((select (Server), $|=1)[0]);
 
 $wordS1=~s/\s+//g;
 $wordS2=~s/\s+//g;

 $review=~s/\s+/\#/g;

 print Server "r\t$key\t$review\t$wordS1\t$wordS2\015\012\015\012";
 print <<"temp";
<B><p><font face="Arial" size="5" >p r o j e c t  &nbsp; </font> </B>
</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp; <font size="6">&nbsp;</font><font size="4"><b>
</b>&nbsp;</font><font size="4" > <font face="Arial">g o o g l e
&nbsp;&nbsp; - h a c k&nbsp;&nbsp;</font></font></p>

<hr></hr>
temp
$review=~s/\#+/ /g;
 print "\n<B>Review  </B><br><br>";

 print "<br>$review";


 while (my $line = <Server>) {
     last if $line eq "\015\012";
     print "<br>$line";
     
 }
 
 local $ENV{PATH} = "/usr/local/bin:/usr/bin:/bin:/ghack";
 my $t_osinfo = `uname -a` || "Couldn't get system information: $!";
 # $t_osinfo is tainted.  Use it in a pattern match and $1 will
 # be untainted.
 $t_osinfo =~ /(.*)/;
#    print "<p>HTTP server: $ENV{HTTP_HOST} ($1)</p>\n";
#    print "<p>Google server: $remote_host</p>\n";
 print "<hr />";
 close Server;
}


sub Review()
{
    print <<"Review";
<B><p><font face="Arial" size="5" >p r o j e c t  &nbsp; </font> </B>
</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp; <font size="6">&nbsp;</font><font size="4"><b>
</b>&nbsp;</font><font size="4" > <font face="Arial">g o o g l e
&nbsp;&nbsp; - h a c k&nbsp;&nbsp;</font></font></p>

<hr></hr>
<form action="index.cgi" method="get"  onreset="formReset()">
<h2> Semantic Orientation of Review </h2>
  <label><b>Positive Inference&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;:</b></label>
<input type="text" name="searchString1" value="" > 
(Positive inference such as "excellent")
<br><br>
<label><b>Negative Ineference&nbsp;:</b></label>
<input type="text" name="searchString2" value=""> (Negative inference such as "bad")<br><br>


<p>
<textarea name="review" rows="15" cols="100">
Insert you Review Here.
</textarea>
</p>
Review

print "<input type=\"hidden\" name=\"apikey\" value=\"$key\">";
 print <<"Review1";
      <input name="action" type="submit" value="Predict" />
      <input name="action" type="submit" value="Back" />

 </form> 
Review1

}

sub SemanticWords()
{
    print <<"Review";
<B><p><font face="Arial" size="5" >p r o j e c t  &nbsp; </font> </B>
</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp; <font size="6">&nbsp;</font><font size="4"><b>
</b>&nbsp;</font><font size="4" > <font face="Arial">g o o g l e
&nbsp;&nbsp; - h a c k&nbsp;&nbsp;</font></font></p>

<hr></hr>
<form action="index.cgi" method="get"  onreset="formReset()">
<h2> Semantic Orientation of Words </h2>
  <label><b>Positive Inference&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;:</b></label>
<input type="text" name="searchString1" value="" > 
(Positive inference such as "excellent")
<br><br>
<label><b>Negative Ineference&nbsp;:</b></label>
<input type="text" name="searchString2" value=""> (Negative inference such as "bad")<br><br>
<p>
<textarea name="text" rows="15" cols="100">
Insert Text Here.
</textarea>
</p>
Review

print "<input type=\"hidden\" name=\"apikey\" value=\"$key\">";
 print <<"Review1";
      <input name="action" type="submit" value="Semantic" />
      <input name="action" type="submit" value="Back" />

 </form> 
Review1

}

sub SemanticPhrases()
{
    print <<"Review";
<B><p><font face="Arial" size="5" >p r o j e c t  &nbsp; </font> </B>
</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp; <font size="6">&nbsp;</font><font size="4"><b>
</b>&nbsp;</font><font size="4" > <font face="Arial">g o o g l e
&nbsp;&nbsp; - h a c k&nbsp;&nbsp;</font></font></p>

<hr></hr>
<form action="index.cgi" method="get"  onreset="formReset()">
<h2> Semantic Orientation of Phrases </h2>
  <label><b>Positive Inference&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;:</b></label>
<input type="text" name="searchString1" value="" > 
(Positive inference such as "excellent")
<br><br>
<label><b>Negative Ineference&nbsp;:</b></label>
<input type="text" name="searchString2" value=""> (Negative inference such as "bad")<br><br>
<p>
<textarea name="text" rows="15" cols="100">
Insert Text Here.
</textarea>
</p>
Review

print "<input type=\"hidden\" name=\"apikey\" value=\"$key\">";
 print <<"Review1";
      <input name="action" type="submit" value="SemanticPhrases" />
      <input name="action" type="submit" value="Back" />

 </form> 
Review1

}

sub predictSemanticWords
{
 socket (Server, PF_INET, SOCK_STREAM, getprotobyname ('tcp'));

    my $internet_addr = inet_aton ($remote_host)
	or die "Could not convert $remote_host to an Internet addr: $!\n";
    my $paddr = sockaddr_in ($remote_port, $internet_addr);

    unless (connect (Server, $paddr)) {
	print "<p>Cannot connect to server $remote_host:$remote_port</p>\n";
	close Server;
    }

 select ((select (Server), $|=1)[0]);
 
 $wordS1=~s/\s+//g;
 $wordS2=~s/\s+//g;

 $text=~s/\s+/\#/g;

 print Server "s\t$key\t$text\t$wordS1\t$wordS2\015\012\015\012";
 print <<"temp";
<B><p><font face="Arial" size="5" >p r o j e c t  &nbsp; </font> </B>
</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp; <font size="6">&nbsp;</font><font size="4"><b>
</b>&nbsp;</font><font size="4" > <font face="Arial">g o o g l e
&nbsp;&nbsp; - h a c k&nbsp;&nbsp;</font></font></p>

<hr></hr>
temp
$text=~s/\#+/ /g;
 print "\n<B>Text  </B><br><br>";

 print "<br>$text";


 while (my $line = <Server>) {
     last if $line eq "\015\012";
     print "<br>$line";
     
 }
 
 local $ENV{PATH} = "/usr/local/bin:/usr/bin:/bin:/ghack";
 my $t_osinfo = `uname -a` || "Couldn't get system information: $!";
 # $t_osinfo is tainted.  Use it in a pattern match and $1 will
 # be untainted.
 $t_osinfo =~ /(.*)/;
#    print "<p>HTTP server: $ENV{HTTP_HOST} ($1)</p>\n";
#    print "<p>Google server: $remote_host</p>\n";
 print "<hr />";
 close Server;
}



sub predictSemanticPhrases
{
 socket (Server, PF_INET, SOCK_STREAM, getprotobyname ('tcp'));

    my $internet_addr = inet_aton ($remote_host)
	or die "Could not convert $remote_host to an Internet addr: $!\n";
    my $paddr = sockaddr_in ($remote_port, $internet_addr);

    unless (connect (Server, $paddr)) {
	print "<p>Cannot connect to server $remote_host:$remote_port</p>\n";
	close Server;
    }

 select ((select (Server), $|=1)[0]);
 
 $wordS1=~s/\s+//g;
 $wordS2=~s/\s+//g;

 $text=~s/\s+/\#/g;

 print Server "h\t$key\t$text\t$wordS1\t$wordS2\015\012\015\012";
 print <<"temp";
<B><p><font face="Arial" size="5" >p r o j e c t  &nbsp; </font> </B>
</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp; <font size="6">&nbsp;</font><font size="4"><b>
</b>&nbsp;</font><font size="4" > <font face="Arial">g o o g l e
&nbsp;&nbsp; - h a c k&nbsp;&nbsp;</font></font></p>

<hr></hr>
temp
$text=~s/\#+/ /g;
 print "\n<B>Text  </B><br><br>";

 print "<br>$text";


 while (my $line = <Server>) {
     last if $line eq "\015\012";
     print "<br>$line";
     
 }
 
 local $ENV{PATH} = "/usr/local/bin:/usr/bin:/bin:/ghack";
 my $t_osinfo = `uname -a` || "Couldn't get system information: $!";
 # $t_osinfo is tainted.  Use it in a pattern match and $1 will
 # be untainted.
 $t_osinfo =~ /(.*)/;
#    print "<p>HTTP server: $ENV{HTTP_HOST} ($1)</p>\n";
#    print "<p>Google server: $remote_host</p>\n";
 print "<hr />";
 close Server;
}


sub showPageEnd
{
    print <<'ENDOFPAGE';

</body>
</html>
ENDOFPAGE
}

__END__


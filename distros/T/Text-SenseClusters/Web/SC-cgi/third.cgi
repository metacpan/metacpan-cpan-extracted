#!/usr/local/bin/perl -wT

# This is the script for third screen of the web-interface. 

use CGI;

$q=new CGI;

print $q->header;
print $q->start_html("SenseClusters");

$clustype=$q->param("clustype");

$usr_dir=$q->param("usr_dir");
if(!$usr_dir)
{
	error("Error in receiving the user directory name from data_process script.");
}

if($usr_dir =~ m/([\w\d\-_\\\/\: ]+)/)
{
    $usr_dir=$1;
}
else
{
    error($q,"Invalid user directory name!");
}

$prefix=$q->param("prefix");

if(!$prefix)
{
    #open the param_file and read the prefix
    open(PARAM,"<$usr_dir/param_file") || error($q, "Error in opening the PARAM file.");

    my $temp_delimiter = $/;
    $/ = undef;
    my $params = <PARAM>;
    close PARAM;
    $/ = $temp_delimiter;
    
    $params=~/PREFIX=\"(.+?)\"/;
    $prefix = $1;
}

my $host = $ENV{'HTTP_HOST'};

# Context Type #
$context=$q->param("context");

# Space #
$space=$q->param("space");

# Cluster Stopping
$cluststop=$q->param("cluststop");

# Binary #
$binary=$q->param("binary");

# Stop File #
if($q->param("default_stop"))
{
	$stop="$usr_dir/stopfile";
	open(STOP,">$stop") || error($q,"Error in loading the STOP file.");

	open(STOPIN,"<stopfile") || error($q,"Error in opening the default STOP file.");
	while(<STOPIN>)
	{
		print STOP;
	}
	close STOPIN;
}
else
{
	$stopfile=$q->param("stop");
	if($stopfile)
	{
		$stop="$usr_dir/stopfile";
		open(STOP,">$stop") || error($q,"Error in loading the STOP file.");
		while(read($stopfile,$buffer,128))
		{
			print STOP $buffer;
		}
	}
}
close STOP;

# Remove #
$remove=$q->param("remove");
if($remove)
{
    if($remove =~ m/^(\d+)$/)
    {
        $remove=$1;
    }
    else
    {
        error($q,"Invalid Frequency Cutoff value!");
    }
}

# Window #
$window=$q->param("window");
if($window)
{
    if($window =~ m/^(\d+)$/)
    {
        $window=$1;
    }
    else
    {
        error($q,"Invalid Window value!");
    }
}

# Scope #
#$scope=$q->param("scope");

# Statistic #
$stat=$q->param("stat");

# statistic rank
$stat_rank=$q->param("stat_rank");
if($stat_rank)
{
    if($stat_rank =~ m/^(\d+)$/)
    {
        $stat_rank=$1;
    }
    else
    {
        error($q,"Invalid Statistical Rank Cutoff value!");
    }
}

# statistic score
$stat_score=$q->param("stat_score");
if($stat_score)
{
    if($stat_score =~ m/^(\d+\.\d+)$/)
    {
        $stat_score=$1;
    }
    else
    {
        error($q,"Invalid Statistical Score Cutoff value!");
    }
}

#########################
# Writing to PARAM file #
#########################

$param_file="$usr_dir/param_file";
open(PARAM,">>$param_file") || error($q, "Error in opening PARAM file.");

print PARAM "CONTEXT=$context\n";
print PARAM "SPACE=$space\n";

if($binary)
{
	print PARAM "BINARY=ON\n";
}

if(defined $stop)
{
	print PARAM "STOP=stopfile\n";
}
if($remove > 1)
{
	print PARAM "REMOVE=$remove\n";
}
if($window > 2)
{
	print PARAM "WINDOW=$window\n";
}

if($stat ne "none" && $stat)
{
	print PARAM "STAT=$stat\n";
	if($stat_rank)
	{
		print PARAM "STAT_RANK=$stat_rank\n";
	}
	if($stat_score)
	{
		print PARAM "STAT_SCORE=$stat_score\n";
	}
}
close PARAM;

###############################
# Context Vector Options Form #
###############################

print $q->start_form(-action=>'fourth.cgi', -method=>'post');

print "<!-outermost table which divides the screen in 2 parts-->
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
<td bgcolor=#EDEDED>";

print $q->h3("Step 3:");

print "
<table width=100% border=0 cellpadding=3>
<tr>
<td>";

#if($context eq "o2")
#{
    print "Apply ", $q->a({-href=>"http://$host/SC-htdocs/help.html#svd"},"SVD"), " (Following options apply only if this box is checked) </td><td>", $q->checkbox(-name=>'svd',-value=>1,-label=>''), "</td></tr>";

    print "<tr><td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;SVD Reduction Factor ", $q->a({-href=>"http://$host/SC-htdocs/help.html#k_k"}, "K"), " (Integer) </td><td>", $q->textfield(-name=>'k', -size=>5, -value=>300, -maxlength=>5), "</td></tr>";

    print "<tr><td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;SVD Scaling Factor ", $q->a({-href=>"http://$host/SC-htdocs/help.html#rf_rf"},"RF"), " (Integer) </td><td>", $q->textfield(-name=>'rf', -size=>5, -value=>10, -maxlength=>5), "</td></tr>";

    print "<tr><td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;If K and RF set, then Reduction Factor = min(N/RF, K)</td><td><br></td></tr>";

    print "<tr><td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;SVD ", $q->a({-href=>"http://$host/SC-htdocs/help.html#iter_i"}, "Iterations"), " (Integer) </td><td>", $q->textfield(-name=>'iter', -size=>5, -maxlength=>7), "</td></tr>";

#}

if($cluststop eq "nclust")
{
	print "<tr><td colspan=2><br></td></tr><tr><td>", $q->a({-href=>"http://$host/SC-htdocs/help.html#clusters_n"},"#Clusters"), " (Integer) </td><td> ", $q->textfield(-name=>'clusters', -size=>5, -value=>10, -maxlength=>5), "</td></tr>";
}
else
{
	print "<tr><td>", $q->a({-href=>"http://$host/SC-htdocs/help.html#cluststop_cs"}, "Cluster Stopping measures"), " </td><td> ", $q->popup_menu(-name=>'cs_measure', -values=>['all','pk','pk1','pk2','pk3','gap'], -labels=>{all=>'All', pk=>'PK', pk1=>'PK1', pk2=>'PK2', pk3=>'PK3', gap=>'Gap'}, -default=>pk2), "</td><td><br></td></tr>";
}

if($space eq 'vector')
{
    print "<tr><td>", $q->a({-href=>"http://$host/SC-htdocs/help.html#clmethod_cl"}, "Clustering Method"), " </td><td> ", $q->popup_menu(-name=>'clmethod', -values=>['rb', 'rbr', 'direct', 'agglo', 'graph', 'bagglo'], -labels=>{rb=>'Repeated Bisections', rbr=>'Repeated Bisections by K-way Refinement', direct=>'Direct', agglo=>'Agglomerative', graph=>'Graph Based', bagglo=>'Partitional Biased Agglomerative'}, -default=>'rb'), "</td></tr></table>";
}
else
{
    print "<tr><td>", $q->a({-href=>"http://$host/SC-htdocs/help.html#clmethod_cl"}, "Clustering Method"), " </td><td> ", $q->popup_menu(-name=>'clmethod', -values=>['rb', 'rbr', 'direct', 'agglo', 'graph'], -labels=>{rb=>'Repeated Bisections', rbr=>'Repeated Bisections by K-way Refinement', direct=>'Direct', agglo=>'Agglomerative', graph=>'Graph Based'}, -default=>'rb'), "</td></tr></table>";
}

print "<br><table width=100% cellpadding=5>
<tr>
<td align=right>
<input type=\"reset\" value=\"Clear All\">
</td>
<td align=left>
<input type=\"submit\" value=\"Submit\">
</td>
</tr>
</table>";

print $q->hidden(-name=>'usr_dir',-value=>$usr_dir);
print $q->hidden(-name=>'prefix', -value=>$prefix);
print $q->hidden(-name=>'clustype', -value=>$clustype);
print $q->hidden(-name=>'cluststop', -value=>$cluststop);

print $q->end_form;
print $q->p;
print $q->a({-href=>"http://$host/SC-htdocs/help.html"}, "Help");
print $q->end_html;

sub error
{
        my ($q,$reason) = @_;
        print $q->h1("Error"),
        $q->p($q->i($reason)),
        $q->end_html;
        exit;
}

#!/usr/local/bin/perl -wT

# This is the script for fourth screen of the web-interface. 

use CGI;
$CGI::DISABLE_UPLOADS = 0;

$q=new CGI;

# Create the URL for the form-action
my $host = $ENV{'HTTP_HOST'};

print $q->header;
print $q->start_html("SenseClusters");

$clustype=$q->param("clustype");

$usr_dir=$q->param("usr_dir");
if(!$usr_dir)
{
        error("Error in receiving the user directory name from feature_process script.");
}

if($usr_dir =~ m/([\w\d\-_\\\/\: ]+)/)
{
    $usr_dir=$1;
}
else
{
    error($q,"Invalid user directory name!");
}

#open the param_file and read the prefix
open(PARAM,"<$usr_dir/param_file") || error($q, "Error in opening the PARAM file.");

my $temp_delimiter = $/;
$/ = undef;
my $params = <PARAM>;
close PARAM;
$/ = $temp_delimiter;

$params=~/SPACE=(.+)/;
$space = $1;

if($params=~/BINARY=/)
{
    $params=~/BINARY=(.+)/;
    $binary = $1;
}

$prefix=$q->param("prefix");
if(!$prefix)
{
    $params=~/PREFIX=\"(.+?)\"/;
    $prefix = $1;
}


#######
# SVD #
#######

$svd=$q->param("svd");

#####
# K #
#####

$k=$q->param("k");
if($k)
{
    if($k =~ m/^(\d+)$/)
    {
        $k=$1;
    }
    else
    {
        error($q,"Invalid K value!");
    }
}

######
# RF #
######

$rf=$q->param("rf");
if($rf)
{
    if($rf =~ m/^(\d+)$/)
    {
        $rf=$1;
    }
    else
    {
        error($q,"Invalid RF value!");
    }
}

########
# Iter #
########

$iter=$q->param("iter");
if($iter)
{
    if($iter =~ m/^(\d+)$/)
    {
        $iter=$1;
    }
    else
    {
        error($q,"Invalid SVD Iteration value!");
    }
}

# ----------------------------------
# Getting Clustering Option Values 
# ----------------------------------

############
# Clusters #
############

$cluststop = $q->param("cluststop");

if($cluststop eq "nclust")
{
	$clusters=$q->param("clusters");
	if($clusters)
	{
		if($clusters =~ m/^(\d+)$/)
		{
			$clusters=$1;
		}
		else
		{
			error($q,"Invalid Number of Clusters!");
		}

		if($clusters < 1)
		{
			error($q, "#clusters can not be less than 1.");
		}
	}
}
else
{
	$cs_measure = $q->param("cs_measure");
}

############
# Clmethod #
############

$clmethod=$q->param("clmethod");


#########################
# Writing to PARAM file #
#########################

$param_file="$usr_dir/param_file";
open(PARAM,">>$param_file") || error($q, "Error in opening PARAM file.");
if($svd)
{
	print PARAM "SVD=ON\n";
	if($k)
	{
		print PARAM "K=$k\n";
	}
	if($rf)
	{
		print PARAM "RF=$rf\n";
	}
	if($iter)
	{
		print PARAM "ITER=$iter\n";
	}
}

if($cluststop eq "nclust")
{
	print PARAM "CLUSTERS=$clusters\n";
}
else
{
	if($cs_measure eq "all")
	{
		print PARAM "CLUSTSTOP=all\n";
	}
	elsif($cs_measure eq "pk")
	{
		print PARAM "CLUSTSTOP=pk\n";
	}
	elsif($cs_measure eq "pk1")
	{
		print PARAM "CLUSTSTOP=pk1\n";
	}
	elsif($cs_measure eq "pk2")
	{
		print PARAM "CLUSTSTOP=pk2\n";
	}
	elsif($cs_measure eq "pk3")
	{
		print PARAM "CLUSTSTOP=pk3\n";
	}
	elsif($cs_measure eq "gap")
	{
		print PARAM "CLUSTSTOP=gap\n";
	}
}

print PARAM "CLMETHOD=$clmethod\n";

close PARAM;

###################################
# Now the Clustering Options Form #
###################################

print $q->start_form(-action=>'fifth.cgi', -method=>'post', -enctype=>'multipart/form-data');

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

print $q->h3("Step 4: (Last Step)");

print "<table width=100% border=0 cellpadding=3>";

if($clmethod eq 'agglo')
{
    print "<tr><td>Clustering ", $q->a({-href=>"http://$host/SC-htdocs/help.html#crfun_cr"}, "Criteria Function"), " </td><td colspan=2> ", $q->popup_menu(-name=>'crfun', -values=>['i1', 'i2', 'e1', 'g1', 'g1p', 'h1', 'h2', 'slink', 'wslink', 'clink', 'wclink', 'upgma'], -default=>'i2', -labels=>{i1=>'I1 Criterion function',i2=>'I2 Criterion function',e1=>'E1 Criterion function',g1=>'G1 Criterion function',g1p=>'G1\' Criterion function',h1=>'H1 Criterion function',h2=>'H2 Criterion function',slink=>'slink: Single link merging scheme',wslink=>'wslink: Weighted Single link merging scheme',clink=>'clink: Complete link merging scheme',wclink=>'wclink: Weighted Complete link merging scheme',upgma=>'upgma: Group average merging scheme'}), "</td></tr>";
}
else
{
    print "<tr><td>Clustering ", $q->a({-href=>"http://$host/SC-htdocs/help.html#crfun_cr"}, "Criteria Function"), " </td><td colspan=2> ", $q->popup_menu(-name=>'crfun', -values=>['i1', 'i2', 'e1', 'g1', 'g1p', 'h1', 'h2'], -default=>'i2', -labels=>{i1=>'I1 Criterion function',i2=>'I2 Criterion function',e1=>'E1 Criterion function',g1=>'G1 Criterion function',g1p=>'G1\' Criterion function',h1=>'H1 Criterion function',h2=>'H2 Criterion function'}), "</td></tr>";
}

if($space eq 'vector' && $clmethod eq 'graph')
{
    print "<tr><td>", $q->a({-href=>"http://$host/SC-htdocs/help.html#sim_sim"}, "Similarity Measure"), "</td><td colspan=2>", 
$q->popup_menu(-name=>'vsim', -values=>['cos', 'corr', 'dist', 'jacc'], -default=>'cos', -labels=>{cos=>'Cosine', corr=>'Pearson\'s Correlation', dist=>'Euclidean Distance', jacc=>'Jaccard'}), "</td></tr>";
}
elsif($space eq 'vector')
{
    print "<tr><td>", $q->a({-href=>"http://$host/SC-htdocs/help.html#sim_sim"}, "Similarity Measure"), "</td><td colspan=2>", 
$q->popup_menu(-name=>'vsim', -values=>['cos', 'corr'], -default=>'cos', -labels=>{cos=>'Cosine', corr=>'Pearson\'s Correlation'}), "</td></tr>";
}
elsif($space eq 'similarity' && defined $binary)
{
   print "<tr><td>", $q->a({-href=>"http://$host/SC-htdocs/help.html#sim_sim"}, "Similarity Measure"), "</td><td colspan=2>", 
$q->popup_menu(-name=>'ssim', -values=>['cos', 'match', 'jacc', 'over', 'dice'], -labels=>{cos=>'Cosine', match=>'Match', jacc=>'Jaccard', over=>'Overlap', dice=>'Dice'}, -default=>'cos'), "</td></tr>";
}
elsif($space eq 'similarity' && !defined $binary)
{
   print "<tr><td>", $q->a({-href=>"http://$host/SC-htdocs/help.html#sim_sim"}, "Similarity Measure"), "</td><td colspan=2>", 
$q->popup_menu(-name=>'ssim', -values=>['cos'], -labels=>{cos=>'Cosine'}, -default=>'cos'), "</td></tr>";
}

print "<tr><td colspan=3><br></td></tr>";

# evaluation and clustering labeling not applicable for word-clustering
if($clustype ne "wclust" && $clustype ne "lsa-fclust")
{
    print "<tr><td>", $q->a({-href=>"http://$host/SC-htdocs/help.html#eval"}," Evaluate performance of the method"), "</td><td colspan=2>", $q->checkbox(-name=>'eval', -label=>''), "</td></tr>";

    print "<tr><td colspan=3><br></td></tr><tr><td colspan=3><b>Labeling Options:</b></td></tr>";

    print "<tr><td>Load the ", $q->a({-href=>"http://$host/SC-htdocs/help.html#label_stop_label_stopfile"},"STOP file"), " (Perl Regex Format) </td><td>", $q->filefield(-name=>'stop_label', -size=>30);
print "</td><td>";
print $q->checkbox(-name=>'default_stop',-label=>''), " Use ", $q->a({-href=>"http://$host/SC-htdocs/stopfile"}, "Default"),"</td></tr>";

    print "<tr><td>Lower ", $q->a({-href=>"http://$host/SC-htdocs/help.html#label_remove_label_n"},"Frequency Cutoff"), " (Integer) </td><td>", $q->textfield(-name=>'remove', -size=>5,-value=>5, -maxlength=>7), "</td><td> [Use 0 to disable this option]</td></tr>";

    print "<tr><td>", $q->a({-href=>"http://$host/SC-htdocs/help.html#label_window_label_w"},"Window"), " (Integer) </td><td>" , $q->textfield(-name=>'window', -size=>5, -value=>2, -maxlength=>7), "</td><td> [Use 0 to disable this option]</td></tr>";

    print "<tr><td>", $q->a({-href=>"http://$host/SC-htdocs/help.html#label_stat_label_stat"},"Statistical Test"), " of Association </td><td>", $q->popup_menu(-name=>'stat', -labels=>{ll=>"Log-Likelihood", x2=>"Chi-Square", dice=>"Dice", phi=>"Phi", odds=>"Odds Ratio", pmi=>"Point-wise Mutual Information", tmi=>"True Mutual Information", tscore=>"T-Score", leftFisher=>"Left Fishers", rightFisher=>"Right Fishers"}, -values=>['ll', 'x2', 'dice', 'phi', 'odds', 'pmi', 'tmi', 'tscore', 'leftFisher', 'rightFisher'], -default=>'ll'), "</td><td><br></td></tr>";

    print "<tr><td>", $q->a({-href=>"http://$host/SC-htdocs/help.html#label_rank_label_r"},"Statistical Rank"), " Cutoff (Integer) </td><td colspan=2>", $q->textfield(-name=>'stat_rank', size=>5,-value=>10, -maxlength=>7), "</td></tr>";
}    

print "</table>";

print $q->hidden(-name=>'usr_dir',-value=>$usr_dir);
print $q->hidden(-name=>'prefix', -value=>$prefix);
print $q->hidden(-name=>'clustype', -value=>$clustype);

print "<table width=100% cellpadding=5>
<tr>
<td align=right>
<input type=\"reset\" value=\"Clear All\">
</td>
<td align=left>
<input type=\"submit\" value=\"Submit\">
</td>
</tr>
</table>";

print $q->p;

print $q->end_form;

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


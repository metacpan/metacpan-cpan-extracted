#!/usr/local/bin/perl -w

# This is the script for second screen of the web-interface. 

# initialize the error message string
my $err_msg = "";
my $path = "";
my $perl5lib = "";

#open the configuration file (./config.txt) and read the environment variables: PATH and PERL5LIB
open(CONF,"<config.txt") or $err_msg = "Error!! SC-cgi/config.txt not found.";

# to read the complete file in one go
while($config = <CONF>)
{
	# read the PATH settings
	if($config=~/^PATH=(.+)/)
	{
		$path = $1;

		chomp $path;
		$path =~ s/^\s//;
	}

	# read the PERL5LIB settings
	if($config=~/^PERL5LIB=(.+)/)
	{
		$perl5lib = $1;

		chomp $perl5lib;
		$perl5lib =~ s/^\s//;
	}
}

if($path eq "")
{
	$err_msg .= "Error!! PATH value not specified - please initialize the SC-cgi/config.txt file<br>";
}

if($perl5lib eq "")
{
	$err_msg .= "Error!! PERL5LIB value not specified - please initialize the SC-cgi/config.txt file<br>";	
}

# set the ENV variables
$ENV{'PATH'}=$path;
$ENV{'PERL5LIB'}=$perl5lib;

# --------------------------------------------------------------------

use CGI;
$CGI::DISABLE_UPLOADS = 0;

# Create the URL for the form-action
my $host = $ENV{'HTTP_HOST'};

$q=new CGI;

print $q->header;
print $q->start_html("SenseClusters");

# check if error occurred during reading the PATH and PERL5LIB variables
if($err_msg ne "")
{
	error($q, $err_msg);
}

$clustype=$q->param("clustype");

$prefix=$q->param("prefix");
if(!$prefix)
{
	$prefix="user";
}

if($prefix =~ m/^([\w\d_\-]+)$/)
{
    $prefix=$1;
}
else
{
    error($q,"Invalid Prefix value!");
}

$usr_dir="user_data/". $prefix.time();
$status=system("mkdir $usr_dir");
if($status!=0)
{
	error($q,"Can not create the user directory $usr_dir");
}

########################
# Test and Train Scope #
########################

$scope_test=$q->param("scope_test");
if($scope_test)
{
    if($scope_test =~ m/^(\d+)$/)
    {
        $scope_test=$1;
    }
    else
    {
        error($q,"Invalid TEST Scope value!");
    }
}

$scope_train=$q->param("scope_train");
if($scope_train)
{
    if($scope_train =~ m/^(\d+)$/)
    {
        $scope_train=$1;
    }
    else
    {
        error($q,"Invalid TRAIN Scope value!");
    }
}

#format
$precision = $q->param("precision");
$format='f16.' . $precision;

################
# Feature Type #
################

$feature_type=$q->param("feature");

################
# Split Type #
################

$split=$q->param("split");
if($split)
{
    if($split =~ m/^(\d+)$/)
    {
		if($split >= 1 && $split <= 99)
		{
			$split=$1;
		}
		else
		{
			error($q,"The Split value can be between 1 to 99 (inclusive).");
		}
    }
    else
    {
        error($q,"Invalid Split value!");
    }
}

####################
# loading Testfile #
####################

$testfile=$q->param("testfile");

if(!$testfile)
{
        print "Please specify the Testfile.<br>\n";
	exit;
}

$test="$usr_dir/$prefix-test.xml";
open(TEST,">$test") || error($q,"Error in uploading Testfile.");
while(read($testfile,$buffer,1024))
{
	print TEST $buffer;
}
close TEST;

#####################
# loading Trainfile #
#####################

$trainfile=$q->param("trainfile");
if($trainfile)
{
	$train="$usr_dir/$prefix-train.plain";
	open(TRAIN,">$train") || error($q,"Error in uploading Trainfile.");

	seek($trainfile,0,0);
	while(read($trainfile,$buffer,1024))
	{
       		print TRAIN $buffer;
	}
}
close TRAIN;

# Check if both TRAIN and split option specified!
if($trainfile && $split)
{
    error($q,"Split and TRAIN file - both options cannot be used together.");
}

#####################
# Loading Tokenfile #
#####################

$token="$usr_dir/token.regex";
open(TOKOUT,">$token") || error($q,"Error in loading Tokenfile.");

if($q->param("token"))
{
	$tokenfile=$q->param("token");
	while(read($tokenfile,$buffer,128))
	{
        	print TOKOUT $buffer;
	}
}
else
{
    open(TOKIN,"token.regex") || error($q,"Error in opening default token.regex file.");
    while(<TOKIN>)
    {
        print TOKOUT;
    }
    close TOKIN;
}
close TOKOUT;

######################
# Loading Targetfile #
######################
if($clustype eq "hclust" || $clustype eq "lsa-hclust")
{
	if($q->param("target"))
	{
		$target="$usr_dir/target.regex";
		open(TARGET_OUT,">$target") || error($q,"Error in loading Targetfile.");
		
		$targetfile=$q->param("target");
		while(read($targetfile,$buffer,128))
		{
			print TARGET_OUT $buffer;
		}
		close TARGET_OUT;
	}
	else
	{
		$target="$usr_dir/target.regex";
		open(TARGET_OUT,">$target") || error($q,"Error in loading Targetfile.");
		
		open(TARGET_IN,"target.regex") || error($q,"Error in opening default target.regex file.");
		while(<TARGET_IN>)
		{
			print TARGET_OUT;
		}
		close TARGET_IN;
		close TARGET_OUT;
	}
}

#else
#{
#    open(TARGET_IN,"target.regex") || error($q,"Error in opening default target.regex file.");
#    while(<TARGET_IN>)
#    {
#        print TARGET_OUT;
#    }
#    close TARGET_IN;
#}


#########################
# Writing to Param file #
#########################

$param_file="$usr_dir/param_file";
open(PARAM,">$param_file") || error($q,"Error in opening PARAM file.");

# word clustering / lsa options
if($clustype eq "wclust")
{
    print PARAM "WORDCLUST=ON\n";
}
elsif($clustype eq "lsa-fclust")
{
    print PARAM "LSAFEATCLUST=ON\n";
}
elsif($clustype eq "lsa-hclust" || $clustype eq "lsa-hlclust")
{
    print PARAM "LSACONTEXTCLUST=ON\n";
}

print PARAM "TEST=\"$prefix-test.xml\"\n";
if(defined $train)
{
	print PARAM "TRAIN=\"$prefix-train.plain\"\n";
}
print PARAM "TOKEN=\"token.regex\"\n";
if(defined $target)
{
	print PARAM "TARGET=\"target.regex\"\n";
}
if($prefix)
{
	print PARAM "PREFIX=\"$prefix\"\n";
}

print PARAM "FEATURE=$feature_type\n";
print PARAM "FORMAT=$format\n";

if($scope_test)
{
    print PARAM "SCOPE_TEST=$scope_test\n";
}

if($scope_train)
{
    print PARAM "SCOPE_TRAIN=$scope_train\n";
}

if($split)
{
    print PARAM "SPLIT=$split\n";
}

close PARAM;

########################
# Feature Options Form #
########################

print $q->start_form(-action=>'third.cgi', -method=>'post', -enctype=>'multipart/form-data');

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

print $q->h3("Step 2:");
print "
<table width=100% border=0 cellpadding=3>
<tr>
<td>";

if($clustype eq "wclust")
{
    print $q->a({-href=>"http://$host/SC-htdocs/help.html#context_ord"},"Context Vector"), " Type </td><td>", $q->popup_menu(-name=>'context', -values=>['o2'], -labels=>{o2=>'2nd Order'}, -default=>o2), "</td><td><br></td></tr>";

}
elsif($clustype eq "lsa-fclust")
{
    print $q->a({-href=>"http://$host/SC-htdocs/help.html#context_ord"},"Context Vector"), " Type </td><td>", $q->popup_menu(-name=>'context', -values=>['o1'], -labels=>{o1=>'1st Order'}, -default=>o1), "</td><td><br></td></tr>";

}
elsif($feature_type eq "uni" && ($clustype eq "hclust" || $clustype eq "hlclust"))
{
    print $q->a({-href=>"http://$host/SC-htdocs/help.html#context_ord"},"Context Vector"), " Type </td><td>", $q->popup_menu(-name=>'context', -values=>['o1'], -labels=>{o1=>'1st Order'}, -default=>o1), "</td><td><br></td></tr>";
}
elsif($clustype eq "lsa-hclust" || $clustype eq "lsa-hlclust")
{
    print $q->a({-href=>"http://$host/SC-htdocs/help.html#context_ord"},"Context Vector"), " Type </td><td>", $q->popup_menu(-name=>'context', -values=>['o2'], -labels=>{o2=>'2nd Order'}, -default=>o2), "</td><td><br></td></tr>";
}
else
{
    print $q->a({-href=>"http://$host/SC-htdocs/help.html#context_ord"},"Context Vector"), " Type </td><td>", $q->popup_menu(-name=>'context', -values=>['o1', 'o2'], -labels=>{o1=>'1st Order', o2=>'2nd Order'}, -default=>o2), "</td><td><br></td></tr>";
}

print "<tr><td>", $q->a({-href=>"http://$host/SC-htdocs/help.html#space_space"}, "Clustering Space"), " </td><td> ", $q->popup_menu(-name=>'space', -values=>['vector', 'similarity'], -default=>'vector'), "</td><td><br></td></tr>";

print "<tr><td>", $q->a({-href=>"http://$host/SC-htdocs/help.html#cluststop_cs"}, "Cluster Stopping"), " </td><td> ";
print "<input type=\"radio\" name=\"cluststop\" value=\"nclust\" checked> Set manually";
print "<input type=\"radio\" name=\"cluststop\" value=\"measure\" > Use cluster stopping measures";
print "</td><td><br></td></tr>";

print "<tr><td> Use ", $q->a({-href=>"http://$host/SC-htdocs/help.html#binary"}, "Binary Vectors"), "</td><td>",  $q->checkbox(-name=>'binary',-label=>''), "</td><td><br></td></tr><tr><td colspan=3><br></td></tr>";

print "<tr><td>Load the ", $q->a({-href=>"http://$host/SC-htdocs/help.html#stop_stopfile"},"STOP file"), " (Perl Regex Format) </td><td>", $q->filefield(-name=>'stop', -size=>30),"</td><td>";
print $q->checkbox(-name=>'default_stop',-label=>''), " Use ", $q->a({-href=>"http://$host/SC-htdocs/stopfile"}, "Default"),"</td></tr>";

print "<tr><td>Lower ", $q->a({-href=>"http://$host/SC-htdocs/help.html#remove_f"},"Frequency Cutoff"), " (Integer) </td><td>", $q->textfield(-name=>'remove', -size=>5,-value=>5,-maxlength=>7), "</td><td> [Use 0 to disable this option]</td></tr>";

if($feature_type ne "uni")
{
    print "<tr><td>", $q->a({-href=>"http://$host/SC-htdocs/help.html#window_w"},"Window"), " (Integer) </td><td>" , $q->textfield(-name=>'window', -size=>5, -value=>2, -maxlength=>7), "</td><td> [Use 0 to disable this option]</td></tr>";

    print "<tr><td>", $q->a({-href=>"http://$host/SC-htdocs/help.html#stat_stat"},"Statistical Test"), " of Association </td><td>", $q->popup_menu(-name=>'stat', -labels=>{ll=>"Log-Likelihood", x2=>"Chi-Square", dice=>"Dice", phi=>"Phi", odds=>"Odds Ratio", pmi=>"Point-wise Mutual Information", tmi=>"True Mutual Information", tscore=>"T-Score", leftFisher=>"Left Fishers", rightFisher=>"Right Fishers", none=>"None"}, -values=>['ll', 'x2', 'dice', 'phi', 'odds', 'pmi', 'tmi', 'tscore', 'leftFisher', 'rightFisher', 'none'], -default=>'none'), "</td><td><br></td></tr>";

    print "<tr><td>", $q->a({-href=>"http://$host/SC-htdocs/help.html#stat_rank_n"},"Statistical Rank"), " Cutoff (Integer) </td><td>", $q->textfield(-name=>'stat_rank', size=>5, -maxlength=>7), "</td><td><br></td></tr>";

    print "<tr><td>", $q->a({-href=>"http://$host/SC-htdocs/help.html#stat_score_s"},"Statistical Score"), " Cutoff (Real Number) </td><td>", $q->textfield(-name=>'stat_score', size=>10, -maxlength=>7), "</td><td><br></td></tr></table>";

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

print $q->hidden(-name=>'usr_dir', -value=>$usr_dir);
print $q->hidden(-name=>'prefix', -value=>$prefix);
print $q->hidden(-name=>'clustype', -value=>$clustype);

print $q->end_form;

print $q->p;

print $q->a({-href=>"http://$host/SC-htdocs/help.html"},"Help");

print "
</td>
</tr>
</table>";

print $q->end_html;

sub error
{
        my ($q,$reason) = @_;
        print $q->h1("Error"),
        $q->p($q->i($reason)),
        $q->end_html;
        exit;
}


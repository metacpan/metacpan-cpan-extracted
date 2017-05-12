#!/usr/local/bin/perl -wT

# This is the script for fifth screen of the web-interface. 

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

	# read the SC-cgi settings
	if($config=~/^SC-cgi=(.+)/)
	{
		$sc_cgi = $1;

		chomp $sc_cgi;
		$sc_cgi =~ s/^\s//;
	}

	# read the cgi settings
	if($config=~/^cgi=(.+)/)
	{
		$cgi = $1;

		chomp $cgi;
		$cgi =~ s/^\s//;
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

if($sc_cgi eq "")
{
	$err_msg .= "Error!! SC-cgi value not specified - please initialize the SC-cgi/config.txt file<br>";	
}

# set the ENV variables
$ENV{'PATH'}=$path;
$ENV{'PERL5LIB'}=$perl5lib;

# --------------------------------------------------------------------

use CGI;
$CGI::DISABLE_UPLOADS = 0;

$q=new CGI;

# Create the URL for the form-action
my $host = $ENV{'HTTP_HOST'};

print $q->header;
print $q->start_html("SenseClusters");

# check if error occurred during reading the PATH and PERL5LIB variables
if($err_msg ne "")
{
	error($q, $err_msg);
}

$clustype=$q->param("clustype");

$usr_dir=$q->param("usr_dir");
if(!$usr_dir)
{
	error("Error in receiving the user directory name from vector_process script.");
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

$prefix=$q->param("prefix");
if(!$prefix)
{   
    $params=~/PREFIX=\"(.+?)\"/;
    $prefix = $1;
}

#########
# crfun #
#########

$crfun=$q->param("crfun");

######################
# Similarity Measure #
######################

$vsim=$q->param("vsim");

$ssim=$q->param("ssim");

######################
# Labeling Options   # 
######################

#############
# Stop File #
#############

if($q->param("default_stop"))
{
	$label_stop="$usr_dir/label_stopfile";
	open(STOP,">$label_stop") || error($q,"Error in loading the STOP file.");

	open(STOPIN,"<stopfile") || error($q,"Error in opening the default STOP file.");
	while(<STOPIN>)
	{
		print STOP;
	}
	close STOPIN;
}
else
{
	$stoplabelfile=$q->param("stop_label");
	if($stoplabelfile)
	{
		$label_stop="$usr_dir/label_stopfile";
		open(STOP,">$label_stop") || error($q,"Error in loading the STOP file.");
		while(read($stoplabelfile,$buffer,128))
		{
			print STOP $buffer;
		}
	}
}
close STOP;


##########
# Remove #
##########

$label_remove=$q->param("remove");
if($label_remove)
{
    if($label_remove =~ m/^(\d+)$/)
    {
        $label_remove=$1;
    }
    else
    {
        error($q,"Invalid Frequency Cutoff value!");
    }
}

##########
# Window #
##########

$label_window=$q->param("window");
if($label_window)
{
    if($label_window =~ m/^(\d+)$/)
    {
        $label_window=$1;
    }
    else
    {
        error($q,"Invalid Window value!");
    }
}

#############
# Statistic #
#############

$label_stat=$q->param("stat");

# statistic rank
$label_stat_rank=$q->param("stat_rank");
if($label_stat_rank)
{
    if($label_stat_rank =~ m/^(\d+)$/)
    {
        $label_stat_rank=$1;
    }
    else
    {
        error($q,"Invalid Statistical Rank Cutoff value!");
    }
}

############
# Evaluate #
############

$eval=$q->param("eval");

#########################
# Writing to PARAM file #
#########################

$param_file="$usr_dir/param_file";
open(PARAM, ">>$param_file") || error($q, "Error in opening PARAM file.");

print PARAM "CRFUN=$crfun\n";

if($vsim)
{
	print PARAM "SIM=$vsim\n";
}
elsif($ssim)
{
	print PARAM "SIM=$ssim\n";
}
else
{
	print PARAM "SIM=cosine\n";
}

if(defined $label_stop)
{
	print PARAM "LABEL_STOP=label_stopfile\n";
}
if($label_remove > 1)
{
	print PARAM "LABEL_REMOVE=$label_remove\n";
}
if($label_window > 2)
{
	print PARAM "LABEL_WINDOW=$label_window\n";
}
if($label_stat ne "none" && $label_stat)
{
	print PARAM "LABEL_STAT=$label_stat\n";

	if($label_stat_rank)
	{
		print PARAM "LABEL_STAT_RANK=$label_stat_rank\n";
	}
}

if($eval)
{
	print PARAM "EVAL=ON\n";
}

close PARAM;

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

print "<p align=right>", $q->a({-href=>"http://$host/$cgi/SC-cgi/index.cgi"},"Start Over"), $q->br;

$status=system("$sc_cgi/callwrap.pl", $usr_dir);
error($q, "Error in running $sc_cgi/callwrap.pl.\n") unless $status==0;

print $q->end_html;

sub error
{
        my ($q,$reason) = @_;
        print $q->h1("Error"),
        $q->p($q->i($reason)),
        $q->end_html;
        exit;
}


#!/usr/local/bin/perl -w

=head1 NAME

callwrap.pl - [Web Interface] Check user input to Web interface and create discriminate.pl command to run on Web server

=head1 DESCRIPTION

This program constructs the discriminate.pl command that is run by the 
Web server. This program requires that you edit config.txt to fit your 
system. This will point to your PATH, PERL5LIB, and the locations of the 
cgi-bin, SC-cgi and SC-htdocs directories. 

=head1 AUTHOR

 Anagha Kulkarni, University of Minnesota, Duluth

 Ted Pedersen, University of Minnesota, Duluth
 tpederse at d.umn.edu

=head1 COPYRIGHT

Copyright (c) 2004-2008, Anagha Kulkarni and Ted Pedersen

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

=cut

use POSIX ":sys_wait_h";
use CGI;

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

	# read the SC-htdocs settings
	if($config=~/^SC-htdocs=(.+)/)
	{
		$sc_htdocs = $1;

		chomp $sc_htdocs;
		$sc_htdocs =~ s/^\s//;
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

if($sc_htdocs eq "")
{
	$err_msg .= "Error!! SC-htdocs value not specified - please initialize the SC-cgi/config.txt file<br>";	
}

# set the ENV variables
$ENV{'PATH'}=$path;
$ENV{'PERL5LIB'}=$perl5lib;

# --------------------------------------------------------------------

$CGI::DISABLE_UPLOADS = 0;
$q = new CGI;

# check if error occurred during reading the PATH and PERL5LIB variables
if($err_msg ne "")
{
	error($q, $err_msg);
}

# ---------------------------------------------------------
# This script validates user specified parameters and calls 
# the wrapper program. In case if the wrapper fails, it 
# reads the error.log file and displays the errors to the 
# user.
# ---------------------------------------------------------
$clustype = "";

if(!defined $ARGV[0])
{
	error($q, "Please specify the User Directory Path.");
}

$usr_dir=$ARGV[0];

if(!-e $usr_dir)
{
	error($q,"User Directory $usr_dir does not exist.");
}
if(!-d $usr_dir)
{
	error($q, "User Directory $usr_dir is not found.");
}

# enter the user dir
chdir $usr_dir || error($q, "Can not enter the user directory $usr_dir.");

if(!-e "param_file")
{
	error($q, "Can not find the PARAM file in user directory $usr_dir.");
}

open(PARAM,"<param_file") || error($q, "Error in opening the PARAM file.");

# reading the PARAM file
while(<PARAM>)
{
	chomp;
	($name,$value)=split(/\s*=\s*/);
	# making parameter names case insensitive
	$name=~tr/[A-Z]/[a-z]/;
	# in case if the user uses 'file' after
	# test, train, stop, token etc...
	$name=~s/file//;
	$param_hash{$name}=$value;
}

close PARAM;

# validate params and create a parameter string

$param_string="";

# word clustering
if(defined $param_hash{"wordclust"})
{
	$param_string.="--wordclust ";
	$clustype = "wclust";
} 
elsif (defined $param_hash{"lsafeatclust"})
{
	$param_string.="--wordclust --lsa ";
	$clustype = "lsa-fclust";
}
elsif (defined $param_hash{"lsacontextclust"})
{
	$param_string.="--lsa ";
}

# testfile should be defined
if(!defined $param_hash{"test"})
{
	error($q, "TEST file is not specified in the PARAM file.");
}
else
{
	$testfile=$param_hash{"test"};
}

if(defined $param_hash{"split"})
{
	$param_string .="--split $param_hash{'split'} ";
}

if(defined $param_hash{"train"})
{
	$param_string.="--training $param_hash{'train'} ";
}

#test and train scopes
if(defined $param_hash{"scope_test"})
{
	$param_string.="--scope_test $param_hash{'scope_test'} ";
}

    $param_string .= "--format $param_hash{'format'} ";

if(defined $param_hash{"scope_train"})
{
	$param_string.="--scope_train $param_hash{'scope_train'} ";
}

if(defined $param_hash{"token"})
{
	$param_string.="--token $param_hash{'token'} ";
}

if(defined $param_hash{"target"})
{
	$param_string.="--target $param_hash{'target'} ";
}

if(defined $param_hash{"feature"})
{
	$param_string.="--feature $param_hash{'feature'} ";
}

if(defined $param_hash{"stop"}) 
{
	$param_string.="--stop $param_hash{'stop'} ";
}

if(defined $param_hash{"remove"})
{
	$param_string.="--remove $param_hash{'remove'} ";
}

if(defined $param_hash{"window"})
{
	$param_string.="--window $param_hash{'window'} ";
}

if(defined $param_hash{"stat"})
{
	$param_string.="--stat $param_hash{'stat'} ";

	if(defined $param_hash{"stat_score"})
	{
		$param_string.="--stat_score $param_hash{'stat_score'} ";
	}
	if(defined $param_hash{"stat_rank"})
        {
		$param_string.="--stat_rank $param_hash{'stat_rank'} ";
        }
}

if(defined $param_hash{"context"})
{
	$param_string.="--context $param_hash{'context'} ";
}

if(defined $param_hash{"binary"})
{
	$param_string.="--binary ";
}

if(defined $param_hash{"svd"})
{
	$param_string.="--svd ";

	if(defined $param_hash{"k"})
	{
		$param_string.="--k $param_hash{'k'} ";
	}
	if(defined $param_hash{"rf"})
	{
		$param_string.="--rf $param_hash{'rf'} ";
	}
	if(defined $param_hash{"iter"})
	{
		$param_string.="--iter $param_hash{'iter'} ";
	}
}

if(defined $param_hash{"clusters"})
{
	$param_string.="--clusters $param_hash{'clusters'} ";
	$clusters = $param_hash{"clusters"};
	$cluststop = "nclust";
}

if(defined $param_hash{"cluststop"})
{
	$param_string.="--cluststop $param_hash{'cluststop'} ";
	$cluststop = $param_hash{"cluststop"};
}

if(defined $param_hash{"space"})
{
	$param_string.="--space $param_hash{'space'} ";
}
else
{
	$param_string.="--space vector ";
}

if(defined $param_hash{"clmethod"})
{
	$param_string.="--clmethod $param_hash{'clmethod'} ";
}

if(defined $param_hash{"crfun"})
{
	$param_string.="--crfun $param_hash{'crfun'} ";
	$crfun = uc $param_hash{'crfun'};  # for plots
}
else
{
    $crfun = "I2";
}

if(defined $param_hash{"sim"})
{
	$param_string.="--sim $param_hash{'sim'} ";
}

# cluster labeling options
if(defined $param_hash{"label_stop"}) 
{
	$param_string.="--label_stop $param_hash{'label_stop'} ";
}

if(defined $param_hash{"label_remove"})
{
	$param_string.="--label_remove $param_hash{'label_remove'} ";
}

if(defined $param_hash{"label_window"})
{
	$param_string.="--label_window $param_hash{'label_window'} ";
}

if(defined $param_hash{"label_stat"})
{
	$param_string.="--label_stat $param_hash{'label_stat'} ";

	if(defined $param_hash{"label_stat_rank"})
    {
		$param_string.="--label_rank $param_hash{'label_stat_rank'} ";
    }
}

if(defined $param_hash{"label_unique"})
{
	$param_string.="--label_unique ";
}

if(defined $param_hash{"eval"})
{
	$param_string.="--eval ";
}

if(defined $param_hash{"prefix"})
{
	$param_string.="--prefix $param_hash{'prefix'} ";
}

$prefix=$param_hash{'prefix'};
$prefix=~s/^"//;
$prefix=~s/"$//;

$usr_dir_name=$usr_dir;
$usr_dir_name=~s/user_data\///;

print $q->h3("Running SenseClusters' Wrapper Program");
print $q->h4("discriminate.pl $testfile $param_string");
print "This will take a while ... Thank you for your patience.", $q->p;

#$status=system("discriminate.pl $param_string $testfile >& logfile");

# Work-around for Browser Timeout problem #

# Problem:
# For larger input data or for certain combinations of options the discriminate.pl programs
# executes for a long duration. This causes the client browser to timeout or rather the
# connection between the browser and the server to close, in which case 
# though discriminate.pl completes its execution eventually the browser waits infinitely.

# Solution:
# The browser times out because it does not get any response from the server for a long time
# while the discriminate.pl is getting executed.
# So instead of simply waiting for discriminate.pl to complete its execution we keep on sending
# html comments to the browser periodically (every 5 secs.). This communication between the server
# and the client prevents the browser timeout.
# To implement this though we needed back the programs control after starting discriminate.pl's 
# execution and thus we use the 'fork' command to spawn a child process. This spawned child process
# executes discriminate.pl and exits. Whereas the parent process waits for the child to finish and
# keeps sending the html comments to the browser every 5 secs till it learns that the child has exited.
# We also realized that a web-server does not send each response generated to the browser immediately.
# It maintains a kind of buffer which keeps on collecting the responses till it gets full and then
# sends it to the browser. Thus it send data in batches for reducing the n/w traffic. Sending small 
# stubs of html comments can actually prevent the browser timeout but because of this buffering 
# strategy of the web-server we send larger html comments so as to fill the buffer soon and send the
# comments to the browser as soon as possible. 

my $pid = fork;

unless($pid)
{
    $status=system("discriminate.pl $param_string $testfile >& logfile");
    my $val = $status >> 8;
    exit($val);
}

my $res_stat = "";

do
{
    sleep(5);
    print "<!-- .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters .SenseClusters filler-->";
    $cid = waitpid($pid,&WNOHANG);         # check on the status of child and proceed i.e. wait for child in non-blocking mode.
    $res_stat = $? >> 8;
}until($cid == $pid);

# check if the discriminate.pl's ran without any error
if($res_stat==0)
{
    if(defined $param_hash{"svd"})
    {
	if(!-e "lao2")
	{
            $print_note1 = "<b>NOTE: SVD could not be performed on the given data.<br>
			Please refer to the <a href=\"/SC-htdocs/$usr_dir_name/logfile\">logfile</a> for further details.</b><br>";
	    print $print_note1, $q->p;
	}
    }

    # if using cluster stopping measures then check for error.
    # if error has occurred then proceed as if #clusters were set manually. 
    if($cluststop ne "nclust")
    {
	# read the predictions file
	open(PFP,"<$prefix.predictions") || error($q,"Error while opening the file $prefix.predictions");	
	
	my $temp_delimiter = $/;
	$/ = undef;
	
	my $pred_contents = <PFP>;
	
	$/ = $temp_delimiter;
	close PFP;

	# check for errors in the predictions file
	if($pred_contents =~ /ERROR/)
	{
	    $tmp = uc $cluststop;

	    $print_note2 = "<b>NOTE: The cluster stopping measure $tmp could not predict the optimal number of clusters for the given data.<br> 
Therefore, proceeding with the default number of clusters of 2.<br>
Please refer to the <a href=\"/SC-htdocs/$usr_dir_name/logfile\">logfile</a> for further details.</b><br>";
	    print $print_note2, $q->p;

	    $cluststop = "nclust";
	    $clusters = 2; #default number of clusters
	    $predict[0] = $clusters;
	}
    }


  # check the cluststop value
  if($cluststop eq "nclust")
  {
      if($clustype ne "wclust" && $clustype ne "lsa-fclust")
      {
	  $predict[0] = $clusters;

          # create $prefix.clusters.html
          open(CLUST,">$prefix.clusters.html") || error($q, "Error while creating $prefix.clusters.html");
          
          print CLUST $q->start_html("SenseClusters");
          print CLUST "<br>";
          
          # flag to check if the file can be displayed as an xml or has to be displayed as a plain text file
          $well_formed = 1;
          
          # for each cluster:extract the cluster id, form the file name using the prefix and cluster id, extract labels from *.cluster_Labels
          open(FP,"<$prefix.cluster_labels") || error($q,"Error while opening the file $prefix.cluster_labels");
          
          $labels = "";
          
          while(<FP>)
          {
              # create a hyperlink to the cluster file for the descriptive labels
              if(/\(Descriptive\): /)
              {
                  # seperate the cluster id and the labels
                  @tmp = split(/ \(Descriptive\): /);
                  $clusterName = $tmp[0];
                  $labels = $tmp[1];

                  $clusterName =~ /Cluster (.+)/;
                  $cId = $1;
                  
                  # create xml file for each cluster
                  $status=system("cp $prefix.cluster.$cId $prefix.cluster.$cId.xml ");
                  error($q,"cp $prefix.cluster.$cId $prefix.cluster.$cId.xml ") unless $status==0;
                  
                  # check the xml if it is well-formed
                  system("$sc_cgi/testXML.pl $prefix.cluster.$cId.xml >& testXML.$cId.out");
                  
                  # if the xml is Not well-formed or not parsable then the output file not be empty
                  if(-z "testXML.$cId.out")
                  {
                      #create links of each cluster in this html file and point the link to $prefix.cluster.$cId.xml if parsable
                      print CLUST $q->a({-href=>"/SC-htdocs/$usr_dir_name/$prefix.cluster.$cId.xml"},"Cluster $cId (Descriptive):"), " $labels <br><br>";
                  }
                  else
                  {
                      #create links of each cluster in this html file and point the link to $prefix.cluster.$cId if not parsable
                      print CLUST $q->a({-href=>"/SC-htdocs/$usr_dir_name/$prefix.cluster.$cId"},"Cluster $cId (Descriptive):"), " $labels <br><br>";
                      $well_formed = 0;
                  }
              }
              # print the Discriminating labels
              elsif(!m/^\s+$/)
              {
                  print CLUST $_ . "<br><br>";
              }
          }
          close FP;        
          
          print CLUST $q->end_html;
          close CLUST;
          
          #convert the file created by format_clusters with --senseval2 option to xml files
          $status=system("cp $prefix.clusters $prefix.clusters.xml");
          error($q, "Error while converting $prefix.clusters to $prefix.clusters.xml file.") unless $status==0;
      }
  }
  else #cluster stopping used
  {
    # read the predictions file
    open(PFP,"<$prefix.predictions") || error($q,"Error while opening the file $prefix.predictions");	

    # generate plots
    $plot_stat=system("$sc_cgi/create_plots.pl $prefix $crfun >& create_plot_output");
    error($q,"$sc_cgi/create_plots.pl $prefix $crfun ") unless $plot_stat==0;
                  
    $i = 0;
    while($k = <PFP>)
    {
      chomp $k;

      $predict[$i] = $k;

      if($cluststop ne "all" && $cluststop ne "pk")
      {
        $cs_name = $cluststop;
      }
      else
      {
        if($i == 0)
        {
          $cs_name = "pk1";
        }
        if($i == 1)
        {
          $cs_name = "pk2";
        }
        if($i == 2)
        {
          $cs_name = "pk3";
        }
        if($i == 3)
        {
          $cs_name = "gap";
        }
      }

      if($clustype ne "wclust" && $clustype ne "lsa-fclust")
      {
        # create $prefix.clusters.html
        open(CLUST,">$prefix.clusters.$cs_name.html") || error($q, "Error while creating $prefix.clusters.$cs_name.html");
          
        print CLUST $q->start_html("SenseClusters");
        print CLUST "<br>";
        
        # flag to check if the file can be displayed as an xml or has to be displayed as a plain text file
        $well_formed = 1;
        
        # for each cluster:
        # extract the cluster id, form the file name using the prefix and cluster id, extract labels from *.cluster_Labels
        open(FP,"<$prefix.cluster_labels.$cs_name") || error($q,"Error while opening the file $prefix.cluster_labels.$cs_name");
          
        $labels = "";
          
        while(<FP>)
        {
          # create a hyperlink to the cluster file for the descriptive labels
          if(/\(Descriptive\): /)
          {
            # seperate the cluster id and the labels
            @tmp = split(/ \(Descriptive\): /);
            $clusterName = $tmp[0];
            $labels = $tmp[1];
            
            $clusterName =~ /Cluster (.+)/;
            $cId = $1;
            
            # create xml file for each cluster
            $status=system("cp $prefix.$cs_name.cluster.$cId $prefix.$cs_name.cluster.$cId.xml ");
            error($q,"cp $prefix.$cs_name.cluster.$cId $prefix.$cs_name.cluster.$cId.xml ") unless $status==0;
                  
            # check the xml if it is well-formed
            system("$sc_cgi/testXML.pl $prefix.$cs_name.cluster.$cId.xml >& testXML.$cId.out");
                  
            # if the xml is Not well-formed or not parsable then the output file not be empty
            if(-z "testXML.$cId.out")
            {
              #create links of each cluster in this html file and point the link to $prefix.cluster.$cId.xml if parsable
              print CLUST $q->a({-href=>"/SC-htdocs/$usr_dir_name/$prefix.$cs_name.cluster.$cId.xml"},"Cluster $cId (Descriptive):"), " $labels <br><br>";
            }
            else
            {
              #create links of each cluster in this html file and point the link to $prefix.cluster.$cId if not parsable
              print CLUST $q->a({-href=>"/SC-htdocs/$usr_dir_name/$prefix.$cs_name.cluster.$cId"},"Cluster $cId (Descriptive):"), " $labels <br><br>";
              $well_formed = 0;
            }
          }
          # print the Discriminating labels
          elsif(!m/^\s+$/)
          {
            print CLUST $_ . "<br><br>";
          }
        }
        close FP;        
          
        print CLUST $q->end_html;
        close CLUST;
          
        #convert the file created by format_clusters with --senseval2 option to xml files
        $status=system("cp $prefix.clusters.$cs_name  $prefix.clusters.$cs_name.xml");
        error($q, "Error while converting  $prefix.clusters.$cs_name to  $prefix.clusters.$cs_name.xml file.") unless $status==0;
      }

      close FP;
      $i++;
    }
    close PFP;
  }

    print $q->h3("Experiment finished successfully.");
    chdir "../" || error($q, "Can not get out from user directory $usr_dir.");
    
    # creating the tar ball
    $status=system("tar -cvf $usr_dir_name.tar $usr_dir_name >& tar_log");
    error($q, "Error while creating the tar file of results.") unless $status==0;
    $status=system("gzip $usr_dir_name.tar");
    error($q, "Error while zipping the tar file of results.") unless $status==0;
    
    $status=system("mv $usr_dir_name.tar.gz $sc_htdocs/");
    error($q, "Error while moving the tar file.") unless $status==0;
    
    print $q->a({-href=>"/SC-htdocs/$usr_dir_name.tar.gz"},"Download");
    print " the complete tar ball of the result files.", $q->p;
    
    # providing links to result files
    # need to copy files to htdocs first
    
    $status=system("mv $usr_dir_name $sc_htdocs/");
    if($status != 0)
    {
	error($q, "Can not create user directory in /htdocs.");
    }
    
    print $q->a({-href=>"/SC-htdocs/$usr_dir_name"},"Browse");
    print " your experiment directory.", $q->p;
    
    if($cluststop eq "nclust")
    {
	print "Results when using #clusters = $predict[0] (Set manually)<br>";
	    
	# link to the confusion table
	if(defined $param_hash{"eval"})
	{
	    print $q->a({-href=>"/SC-htdocs/$usr_dir_name/$prefix.report"},"Confusion Table"), $q->br;
	}
	
	if($clustype ne "wclust" && $clustype ne "lsa-fclust")
	{
	    # link to the clustering output
	    print $q->a({-href=>"/SC-htdocs/$usr_dir_name/$prefix.clusters.html"},"Instances grouped by Cluster "), $q->br;
	}
	
	#if the xml is Not well-formed or not parsable then the output file will not be empty
	if($well_formed == 1)
	{
	    #create link to $prefix.clusters.xml if parsable
	    print $q->a({-href=>"/SC-htdocs/$usr_dir_name/$prefix.clusters.xml"},"Instances with assigned Cluster "), $q->br;
	}
	else
	{
	    #create link to $prefix.clusters if not parsable
	    print $q->a({-href=>"/SC-htdocs/$usr_dir_name/$prefix.clusters"},"Instances with assigned Cluster "), $q->br;
	}
	
    }
    else # cluster stopping used
    {
	if($cluststop eq "all")
	{
	    $predict_measure[0] = "PK1 measure";
	    $predict_measure[1] = "PK2 measure";		
	    $predict_measure[2] = "PK3 measure";
	    $predict_measure[3] = "Adapted Gap Statistic";
	}
	elsif($cluststop eq "pk")
	{
	    $predict_measure[0] = "PK1 measure";
	    $predict_measure[1] = "PK2 measure";		
	    $predict_measure[2] = "PK3 measure";
	}
	else
	{
	    $predict_measure[0] = uc $cluststop;
	    $predict_measure[0] .= " measure";	
	}
	
	print "<table border=\"1\"><tr>";
	for($i=0; $i<=$#predict; $i++)
	{
	    
	    print "<td>Results when using #clusters = $predict[$i] <br> Predicted by <b>$predict_measure[$i]</b><br>";
		print "=========================<br>";
	    
	    if($cluststop ne "all" && $cluststop ne "pk")
	    {
		$cs_name = $cluststop;
	    }
	    else
	    {
		if($i == 0)
		{
		    $cs_name = "pk1";
		}
		if($i == 1)
		{
		    $cs_name = "pk2";
		}
		if($i == 2)
		{
		    $cs_name = "pk3";
		}
		if($i == 3)
		{
		    $cs_name = "gap";
		}
	    }
	    
	    # link to the confusion table
	    if(defined $param_hash{"eval"})
	    {
		print $q->a({-href=>"/SC-htdocs/$usr_dir_name/$prefix.report.$cs_name"},"Confusion Table"), $q->br;
	    }
	    
	    if($clustype ne "wclust" && $clustype ne "lsa-fclust")
	    {
		# link to the clustering output
		print $q->a({-href=>"/SC-htdocs/$usr_dir_name/$prefix.clusters.$cs_name.html"},"Instances grouped by Cluster "), $q->br;
	    }
	    
	    #if the xml is Not well-formed or not parsable then the output file will not be empty
	    if($well_formed == 1)
	    {
		#create link to $prefix.clusters.xml if parsable
		print $q->a({-href=>"/SC-htdocs/$usr_dir_name/$prefix.clusters.$cs_name.xml"},"Instances with assigned Cluster "), $q->br;
	    }
	    else
	    {
		#create link to $prefix.clusters if not parsable
		print $q->a({-href=>"/SC-htdocs/$usr_dir_name/$prefix.clusters.$cs_name"},"Instances with assigned Cluster "), $q->br;
	    }
	    
	    # plot links
	    $u_cs = uc $cs_name;
	    if($u_cs ne "GAP")
	    {
		print $q->a({-href=>"/SC-htdocs/$usr_dir_name/$prefix.$u_cs.pdf"},"Plot: $u_cs vs. m "), $q->br;
	    }
	    else
	    {
		print $q->a({-href=>"/SC-htdocs/$usr_dir_name/$prefix.Obs-Exp.pdf"},"Plot: Observed($crfun) & Expected($crfun) "), $q->br;
		print $q->a({-href=>"/SC-htdocs/$usr_dir_name/$prefix.$u_cs.pdf"},"Plot: $u_cs vs. m "), $q->br;
	    }
	    
	    print "</td>";
	}
	print "</tr></table><br>";

	# link to the plot of crfun vs m
	print $q->a({-href=>"/SC-htdocs/$usr_dir_name/$prefix.CR.pdf"},"Plot: $crfun vs. m"), $q->br;
    }
    
    # handle the special cases for word-clustering
    if(defined $param_hash{"wordclust"})
    {
	# link to the features file (but the file is named *.rlabel)
	print $q->a({-href=>"/SC-htdocs/$usr_dir_name/$prefix.rlabel"},"Features File"), $q->br;
	
	# link to word vectors (but the file is named *.vectors)
	if(defined $param_hash{"context"} && $param_hash{"context"} =~/o2/)
	{
	    print $q->a({-href=>"/SC-htdocs/$usr_dir_name/$prefix.vectors"},"Word Vectors"), $q->br;
	}
    }
    else
    {
	# link to the features file
	print $q->a({-href=>"/SC-htdocs/$usr_dir_name/$prefix.features"},"Features File"), $q->br;
	
	# link to word vectors
	if(defined $param_hash{"context"} && $param_hash{"context"} =~/o2/)
	{
	    print $q->a({-href=>"/SC-htdocs/$usr_dir_name/$prefix.wordvec"},"Word Vectors"), $q->br;
	}
	
	# link to the context vectors
	print $q->a({-href=>"/SC-htdocs/$usr_dir_name/$prefix.vectors"},"Context Vectors"), $q->br;
    }
    
    # link to the similarity matrix
    if(defined $param_hash{"space"} && $param_hash{"space"} =~/simil/)
    {
	print $q->a({-href=>"/SC-htdocs/$usr_dir_name/$prefix.simat"},"Similarity Matrix"), $q->br;
    }
    
    # link to the parameter file
    print $q->a({-href=>"/SC-htdocs/$usr_dir_name/param_file"},"Parameter File"), $q->br;
}
else
{
    print $q->h3("There was an error while running this experiment.");
    print $q->br;
    
    print "<pre>";
    open(LOG,"<logfile") || error($q,"Can't open the logfile.");
    while(<LOG>)
    {
	print;
	print $q->br;
    }
    close LOG;
    print "</pre>";
}

sub error
{
        my ($q, $reason) = @_;
        print $q->h1("Error"),
        $q->p($q->i($reason)),
        $q->end_html;
        exit;
}

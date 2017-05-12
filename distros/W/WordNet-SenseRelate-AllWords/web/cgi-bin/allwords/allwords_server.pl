#!/usr/bin/perl -w
use warnings;
use strict;

use IO::Socket;
use WordNet::QueryData;
use WordNet::Tools;
use WordNet::SenseRelate::AllWords;
use WordNet::Similarity;
use Getopt::Long;

my $wnlocation = '/usr/local/WordNet-3.0/dict';
my $localhost = '127.0.0.1';
my $localport = 32323;
my $logfile;

my $help;
my $version;
my $client;
my $text;
my @tokens;
my $line;
my @sentences;
my $sentence;
my $temp; # for accessing %options hash

my @context;
my $contextfile="./user_data/tmp_client_input.txt";
my $contextflag=0;
my $stoplistflag=0;
my $leskconfigfile="./user_data/lesk-stoplist.conf";
my $vectorconfigfile="./user_data/vector-stoplist.conf";
my $windowSize;
my $format;
my $scheme;
my $i=0;
my $j=0;


# result variables
my $status; # to store the status of system commands to create 
			#and move directories...
my $val;	# for reading each word after disambiguation


my $ok = GetOptions ('logfile=s' => \$logfile,
			 'wnlocation=s' => \$wnlocation, 	
			 'port=i' => \$localport,
		     help => \$help,
		     version => \$version,
		     );
$ok or exit 1;

if ($help) {
    showUsage ("Long");
    exit;
}

if ($version) {
    print "allwords_server.pl - WordNet::SenseRelate::AllWords web interface server\n";
    print 'Last modified by : $Id: allwords_server.pl,v 1.39 2009/05/27 19:56:57 kvarada Exp $';
    print "\n";
    exit;
}

unless (defined $logfile) {
    print STDERR "The --logfile argument is required. This is the logfile path for allwords_server.pl log\n";
    showUsage ();
    exit 1;
}

my $success = open LFH, ">>$logfile";
if(!$success)
{
	print "\nCannot open $logfile for writing: $!";
}
else
{
	print "\nWriting log in $logfile";
}
	print LFH "WordNet Location => $wnlocation\n";

#. ....................................
#
# Creating WordNet::QueryData object.
#
#......................................

my $qd = WordNet::QueryData->new($wnlocation);
$qd or die "\nCouldn't construct WordNet::QueryData object"; 

print LFH "\nWordNet::QueryData object sucessfully created";

my %options;
my $stopword;
my $stopwordflag=0;
my $istagged=0;
my $showversion=0;
my $usr_dir;
my $tracefilename;
my $resultfilename;
my $doc_base = "../../htdocs/allwords/user_data";

# This is the name of the logfile of AllWords.pm. The file will be 
# stored in directory of the webserver
#
#........................................................................
#
# Compoundifying is done using compoundify method of WordNet::Tools.
#
#........................................................................

my $wntools = WordNet::Tools->new($qd);
$wntools or die "\nCouldn't construct WordNet::Tools object"; 
print LFH "\nWordNet::SenseRelate::Tools object sucessfully created";

my $sock = IO::Socket::INET->new(
		   LocalPort => $localport,
		   Listen => SOMAXCONN,
		   Reuse => 1,
		   Type => SOCK_STREAM
) or die "Could not bind to network port: $! \n";

print LFH "\nSocket created with following details \nLocalHost => $localhost\nLocalPort => $localport\nProto => tcp";

print LFH "\n[Server $0 accepting clients]\n";
while ($client = $sock->accept()){	
   $client->autoflush(1);	
   print LFH "\nClient $client is accepted\n";	
   %options= (wordnet => $qd, wntools => $wntools);
   @sentences=();
   $sentence="";
   $text="";
   $contextflag=0;
   $stoplistflag=0;
   while(defined ($line = <$client>))
   {	
	chomp($line);
	@tokens=split(/:/,$line);
		if( $line =~ /<version information>:/) 
		{
		    # get version information
		    my $qdver = $qd->VERSION ();
			my $wnver = $wntools->hashCode ();
		    my $simver = $WordNet::Similarity::VERSION;
			my $allwordsver = $WordNet::SenseRelate::AllWords::VERSION;
			print LFH "\nv WordNet $wnver";
			print LFH "\nv WordNet::QueryData $qdver";
		    print LFH "\nv WordNet::Similarity $simver";
			print LFH "\nv WordNet::SenseRelate::AllWords $allwordsver";

			print $client "v WordNet $wnver\n";
			print $client "v WordNet::QueryData $qdver\n";
			print $client "v WordNet::Similarity $simver\n";
			print $client "v WordNet::SenseRelate::AllWords $allwordsver\n";
			$showversion=1;
			print LFH "\nShow verrion flag => $showversion";
			close($client);	
			last;
		}
		elsif($line =~ /<start-of-context>/)
		{
			$contextflag=1;
			open (CFH, '>>', "$contextfile") or die "Cannot open $contextfile : $!";				
		} 
		elsif($line =~ /<end-of-context>/)
		{
			$contextflag=0;
			close CFH;
		}
		elsif($contextflag == 1 && $line =~ /<con>/)
	    {
			print CFH $tokens[1];	
			print CFH "\n";
	    }
		elsif ($line =~  /<Document Base>:/)
	    {
			$doc_base=$tokens[1];
			print LFH "\nDocument Base => $doc_base";
	    }
		elsif ($line =~  /<User Directory>:/)
	    {
			$usr_dir="$tokens[1]"."_server";
			print LFH "\nUser Directory => $usr_dir";
			$status=system("mkdir $usr_dir");
			$status == 0 ? print LFH "\n created dir $usr_dir.":print LFH "\nDir already present or error creating dir $usr_dir"; 
			$contextfile="$usr_dir"."/context.txt";
			$tracefilename="$usr_dir"."/trace.txt";
			$resultfilename="$usr_dir"."/results.txt";
			print LFH "\nTrace file name => $tracefilename";
	    }
		elsif ($line =~ /<Contextfile>:/)
		{
			$showversion=0;
			print LFH "\nContextfile => $contextfile";
			open (CFH, '<', "$contextfile") or die "Cannot open $contextfile: $!";				
			while(<CFH>)
			{
				$text=$text.$_;
			}
			$text =~ s/\r+//g;	
			@sentences = split(/\n+/,$text);
			close CFH;
	    }
		elsif ($line =~ /<Window size>:/)
		{
			$windowSize=$tokens[1];
			print LFH "\nWindow Size => $windowSize";
	    }elsif ($line =~ /<Format>:/)
	    {
			$format=$tokens[1];
			$istagged = ($format eq 'tagged') ? 1 : 0;
			print LFH "\nformat => $format";
			$istagged eq 1 ? print LFH "\ntagged text => YES": print LFH "\ntagged text => NO" ;
			$options{wnformat} = 1 if $format eq 'wntagged';
			$options{wnformat} ? print LFH "\nwntagged text => YES": print LFH "\nwntagged text => NO" ;

	    }elsif ($line =~ /<Scheme>:/)
	    {
			$scheme=$tokens[1];
			print LFH "\nscheme => $scheme";
	    }elsif ($line =~ /<trace>:/)
	    {
			$options{trace} = $tokens[1];
	    }elsif ($line =~ /<pairScore>:/)
	    {	
			$options{pairScore} = $tokens[1];
	    }elsif ($line =~ /<forcepos>:/)
	    {	
			$options{forcepos} = 1;
	    }elsif ($line =~ /<nocompoundify>:/)
	    {	
			$options{nocompoundify} = 1;
	    }elsif ($line =~ /<usemono>:/)
	    {	
			$options{usemono} = 1;
	    }elsif ($line =~ /<backoff>:/)
	    {	
			$options{backoff} = 1;
	    }elsif ($line =~ /<measure>:/)
	    {	
			$options{measure} = "WordNet::Similarity::"."$tokens[1]";

		}elsif ($line =~ /<contextScore>:/)
	    {	
			$options{contextScore} = $tokens[1];
	    }elsif ($line =~ /<stoplist>:/)
	    {	
			$options{stoplist} = "$usr_dir/"."$tokens[1]";
	    }elsif($line =~ /<start-of-stoplist>/)
		{
			$stoplistflag=1;
			open (SFH, '>>', "$options{stoplist}") or die "Cannot open $options{stoplist} : $!";				
		} 
		elsif($line =~ /<end-of-stoplist>/)
		{
			$stoplistflag=0;
			close SFH;
		}
	    elsif($stoplistflag == 1 && $line =~ /<stp>/ && defined $tokens[1])
	    {
			print SFH $tokens[1];	
			print SFH "\n";
	    }
		elsif($line eq "<End>\0012")
		{
			last;
		}
   }
if (!$showversion) {
$options{config} = $leskconfigfile if ($options{measure} eq "WordNet::Similarity::lesk");
$options{config} = $vectorconfigfile if ($options{measure} eq "WordNet::Similarity::vector");

print LFH "\nThe options are: \n";
foreach $temp (keys(%options)) 
{ 
	print LFH "$temp=>".$options{$temp} . "\n";
} 	


   my $obj = WordNet::SenseRelate::AllWords->new(%options);
   $obj ? print LFH "\nWordNet::SenseRelate::AllWords object successfully created":print LFH "\nCouldn't construct WordNet::SenseRelate::AllWords object";

   open RFH, '>', $resultfilename or print "Cannot open $resultfilename for writing: $!";
   foreach $sentence (@sentences) {
	   chomp($sentence);
	   @context=split(/ +/,$sentence);

	#.....................................................................
	#
	# This is the call to disambigute the sentence which client has sent
	#
	#.....................................................................

		my @res = $obj->disambiguate (window => $windowSize,
					  scheme => $scheme,
					  tagged => $istagged,
					  context => [@context]);

	#........................................................................
	#
	# AllWords.pm returns words with suffixes attached to it. 
	# If #o is attached, the word is a stopword
	# If #ND is attached the word is not defined in WordNet
	# If #NR is attached no relatedness found with the surrounding words
	# If #IT is attached, the word has invalid tag
	# Otherwise, the chosen sense along with the part of speech is sent to
	# the client
	#
	#........................................................................
	
	print RFH join (' ', @context), "\n";
	print RFH join (' ', @res), "\n";

	print LFH join (' ', @context), "\n";
	print LFH join (' ', @res), "\n";

	print $client join (' ', @context), "\015\012";
	print $client join (' ', @res), "\015\012";
	for($i=0,$j=0; $i<=$#res ; $i++,$j++)
	{
		   my $val;
  		   my $tagindex=index($res[$i],"#");
		   my $tag=substr $res[$i], $tagindex;
		   
		   if($format eq 'raw')
		   {
			if($res[$i] =~ /\_/ && $context[$j] !~ /\_/){
				my $count = ($res[$i] =~ tr/\_//);
				$val=$res[$i];
				$j=$j+$count;
			 }else{
				$val=$context[$j].$tag;
			 }
		   }
		   elsif($format eq 'tagged')
		   {
			 my ($tw,$tt)= ( $context[$j] =~ /(\S+)\/(\S+)/);
			 $val=$tw.$tag;
		   }	
  		   elsif($format eq 'wntagged')
		   {
			 my ($tw,$tt)= split /\#/, $context[$j];
			 $val=$tw.$tag;
		   }	

			if($val =~ /\#o/ )
			{
				print LFH "\n$val : stopword\n";
				print RFH "\n$val : stopword\n";
				print $client "\n$val : stopword\015\012";
			}
			elsif($val =~ /\#ND/) 
			{
				print LFH "\n$val : not in WordNet\n";
				print RFH "\n$val : not in WordNet\n";
				print $client "\n$val : not in WordNet\015\012";
			}
			elsif($val =~ /\#NR/)
			{
				print LFH "\n$val: No relatedness found with the surrounding words\n";
				print RFH "\n$val: No relatedness found with the surrounding words\n";
				print $client "\n$val: No relatedness found with the surrounding words\015\012";

			}
			elsif($val =~ /\#IT/)
			{
				print LFH "\n$val: Invalid Tag\n";
				print RFH "\n$val: Invalid Tag\n";
				print $client "\n$val: Invalid Tag\015\012";

			}
			elsif($val =~ /\#NT/)
			{
				print LFH "\n$val: No Tag\n";
				print RFH "\n$val: No Tag\n";
				print $client "\n$val: No Tag\015\012";
			}

			elsif($val =~ /\#CL/)
			{
				print LFH "\n$val: Closed Class Word\n";
				print RFH "\n$val: Closed Class Word\n";
				print $client "\n$val: Closed Class Word\015\012";
			}
			elsif($val =~ /\#MW/)
			{
				print LFH "\n$val: Missing Word\n";
				print RFH "\n$val: Missing Word\n";
				print $client "\n$val: Missing Word\015\012";
			}
			else
			{
				my ($gloss) = $qd->querySense ($res[$i], "glos");
				print LFH "\n$val : $gloss\n";
				print RFH "\n$val : $gloss\n";
				print $client "\n$val : $gloss\015\012";
			}
		}
		if ($options{trace}) {
				open TFH, '>', $tracefilename or print "Cannot open $tracefilename for writing: $!";
				print TFH join (' ', @res), "\n";
				print $client "<start-of-trace>\015\012";
				print $client join (' ', @res), "\015\012";
				my $tstr = $obj->getTrace();
				print TFH "$tstr \n";
				print $client "$tstr \015\012";
				print $client "<end-of-trace>\015\012";
				print LFH "$tstr \n";
				close TFH;
		}

   	}	
		close RFH;
		close($client);	
	}
}


sub showUsage
{
    my $long = shift;
    print "Usage: allwords_server.pl --logfile FILE \n";
    print "              [--wnlocation WordNet path] [--port PORT] \n";
    print "              | {--help | --version}\n";

    if ($long) {
	print "Options:\n";
	print "\t--logfile FILE             logfile path for allwords.pl log\n";
	print "\t--wnlocation WordNet path  WordNet path\n";
	print "\t--port PORTNUMBER          Specify the port PORTNUMBER for the server to listen on \n";
	print "\t--help                     show this help message\n";
	print "\t--version                  show version information\n";
    }
}

=head1 NAME

allwords_server.pl - [Web] The server for allwords.cgi and version.cgi

=head1 DESCRIPTION

This script implements the backend of the web interface for 
WordNet::SenseRelate::AllWords

This script listens to a port waiting for a request form allwords.cgi
or version.cgi. If disambiguation request is made by allwords.cgi, the
server first gets input options from allwords.cgi. Then it creates 
AllWords object. Using AllWords object and input options disambiguate 
method is called. The result returned by disambiguate is checked and 
appropriate message is sent back to allwords.cgi client. 

Client-Server Communication
The server loads all the required modules and listens to the port 32323. 
The client sends informtation with a preamble to know the server what kind
of input data it is going to get. For example, the client reads the text 
to be disambiguated from the user and sends the context file to the server 
as below

<start-of-context>
context-line 1
context-line 2
context-line 3
.
.
.
<end-of-context>

The tags <start-of-context> and <end-of-context> are not going to conflict 
with the text to be disambiguated as we clean the text before disambiguation
and hence the characters '<' and '>' will be removed from the text.

If the version information is requested, appropriate version information
of the respective components is fetched and is passed to version.cgi client.

If the client requests for trace level, then trace output is fetched calling
getTrace() method of AllWords.pm.

Along with sending all information to the client, the server also stores all 
the input data and result files on the server machine in a unique directory 
for each client. 

=head1 AUTHORS

 Varada Kolhatkar, University of Minnesota, Duluth
 kolha002 at d.umn.edu

 Ted Pedersen, University of Minnesota, Duluth
 tpederse at d.umn.edu

This document last modified by : 
$Id: allwords_server.pl,v 1.39 2009/05/27 19:56:57 kvarada Exp $ 

=head1 SEE ALSO

allwords.cgi, version.cgi, README.web.pod

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008, Varada Kolhatkar, Ted Pedersen, Jason Michelizzi

Permission is granted to copy, distribute and/or modify this document
under the terms of the GNU Free Documentation License, Version 1.2
or any later version published by the Free Software Foundation;
with no Invariant Sections, no Front-Cover Texts, and no Back-Cover
Texts.

Note: a copy of the GNU Free Documentation License is available on
the web at L<http://www.gnu.org/copyleft/fdl.html> and is included in
this distribution as FDL.txt.

=cut

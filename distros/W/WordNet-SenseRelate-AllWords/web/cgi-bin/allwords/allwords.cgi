#!/usr/bin/perl -w
use IO::Socket;
use CGI;
$CGI::DISABLE_UPLOADS = 0;

# Here we connect to the AllWords server
# If you want to use different port for communication, change it here. 

my $remote_host='127.0.0.1';
my $remote_port=32323;
my $proto='tcp';
my $hostname;

my $OK_CHARS='-a-zA-Z0-9_\'\n ';
my ($kidpid, $handle, $line);
my %options;
my $status;
my $filename; 
my $inputfile;
my $stoplistfile;
my $defstoplistfile;
my $stoplistfilename;
my $stoplist;
my $contextfile;
my $contextfilename;
my $tracefilename;


my $traceflag=0;
my $defstop="off";

my $doc_base;
my @tracelevel=();

BEGIN {
    # The carpout() function lets us modify the format of messages sent to
    # a filehandle (in this case STDERR) to include timestamps
    use CGI::Carp 'carpout';
    carpout(*STDOUT);
}

my $cgi = CGI->new;

# print the HTTP header
print $cgi->header;
$hostname=$ENV{'SERVER_NAME'};

my $usr_dir="user_data/". "user".time();
$inputfile="$usr_dir/"."input.txt";
$resultfilename="$usr_dir/"."results.txt";
$tracefilename="$usr_dir"."/trace.txt";
$status=system("mkdir $usr_dir");

if($status!=0)
{
	writetoCGI("Can not create the user directory $usr_dir");
}

$filename="$usr_dir/clientinput.txt";
$defstoplistfile="default-stoplist-raw.txt";

my $text = $cgi->param('text1') if defined $cgi->param('text1');

$contextfile=$cgi->param('contextfile') if defined $cgi->param('contextfile');

if ( (!$text)  && (!$contextfile) ) {
	    writetoCGI("\nPlease use back link to return to original page to enter your text\n");
		print "<p><a href=\"http://$hostname/allwords/allwords.html\">Back</a></p>";
		die "Could not complete the request as no text was entered. \n";
}

my $windowSize = $cgi->param('winsize') if defined $cgi->param('winsize');
my $format = $cgi->param('format') if defined $cgi->param('format');
$options{wnformat} = 1 if $format eq 'wntagged';
my $scheme = $cgi->param('scheme') if defined $cgi->param('scheme');

if ($cgi->param('measure') =~ /lesk/) {
	$options{measure}= "lesk";
}elsif($cgi->param('measure') =~ /path/) {
	$options{measure}= "path";
}elsif($cgi->param('measure') =~ /wup/) {
	$options{measure}= "wup";
}elsif($cgi->param('measure') =~ /lch/) {
	$options{measure}= "lch";
}elsif($cgi->param('measure') =~ /hso/) {
	$options{measure}= "hso";
}elsif($cgi->param('measure') =~ /res/) {
	$options{measure}= "res";
}elsif($cgi->param('measure') =~ /lin/) {
	$options{measure}= "lin";
}elsif($cgi->param('measure') =~ /jcn/) {
	$options{measure}= "jcn";
}elsif($cgi->param('measure') =~ /vector/) {
	$options{measure}= "vector";
}elsif($cgi->param('measure') =~ /vector-pairs/) {
	$options{measure}= "vector-pairs";
}

# Text was considered as a single line before. 
# Allowed \n character in $OK_CHARS to fix that.
# Removing unwanted characters from the raw text. 
# If the text is tagged or wntagged, it is the user's responsibility 
# to clean text and remove unwanted characters

if($text){
	if ($format ne 'tagged' && $format ne 'wntagged') {
		$text = cleanLine($text);
		if ($text !~ /[a-zA-Z0-9]/) {
			   writetoCGI("\nPlease use back link to return to original page to enter your text\n");
			   print "<p><a href=\"http://$hostname/allwords/allwords.html\">Back</a></p>";
			   die "\nSorry. Your text should contain atleast one alphanumeric character\n";
		}
	}
	$contextfilename="default-context-file.txt";
	$context="$usr_dir/"."$contextfilename";
	open CONTEXT,">","$context" or writetoCGI("Error writing contextfile.");
	print CONTEXT $text;
	close CONTEXT;
}
elsif($contextfile){
	$contextfilename = getFileName($contextfile);
	$context="$usr_dir/"."$contextfilename";
	open CONTEXT,">","$context" or writetoCGI("Error in uploading contextfile.");
	while(read($contextfile,$buffer,1024)){
		if ($format ne 'tagged' && $format ne 'wntagged') {
			$text = cleanLine($text);
			if ($buffer !~ /[a-zA-Z0-9]/) {
			    writetoCGI("\nPlease use back link to return to original page to enter your text\n");
				print "<p><a href=\"http://$hostname/allwords/allwords.html\">Back</a></p>";
				die "\nSorry. Your text should contain atleast one alphanumeric character\n";
			}
		}
		print CONTEXT $buffer;
	}
	close CONTEXT;	
}

# If the user uploads his own stoplist as well as keep the default 
# stoplist option checked, the stoplist included by the user will 
# always override the default

$stoplistfile=$cgi->param('stoplist');

if(!$stoplistfile)
{
	$defstop=$cgi->param('defstoplist') if defined $cgi->param('defstoplist');
	if ($defstop eq "on") {
#		$options{stoplist} = "./user_data/$defstoplistfile";
		$options{stoplist} = "$defstoplistfile";
		$status=system("cp ./user_data/$defstoplistfile $usr_dir/$defstoplistfile");
		print "Error while copying the stoplist file." unless $status==0;
	}
}
else{
	$stoplistfilename = getFileName($stoplistfile);
	$stoplist="$usr_dir/"."$stoplistfilename";
#	$options{stoplist} = "$usr_dir/"."$stoplistfilename";
	$options{stoplist} = "$stoplistfilename";
	open STOPLIST,">","$stoplist" or writetoCGI("Error in uploading Testfile.");
	while(read($stoplistfile,$buffer,1024))
	{
		print STOPLIST $buffer;
	}
	close STOPLIST;
}

$options{pairScore} = $cgi->param('pairscore') if defined $cgi->param('pairscore');
$options{contextScore} = $cgi->param('contextscore') if defined $cgi->param('contextscore');
#.............................................................................
#
# storing different tracelevels in an array so that it would be useful to show
# traces of different levels.
#
#..................................................................................
$tracelevel[0] = defined $cgi->param('level1') ? $cgi->param('level1') : 0;
$tracelevel[1] = defined $cgi->param('level2') ? $cgi->param('level2') : 0; 
$tracelevel[2] = defined $cgi->param('level4') ? $cgi->param('level4') : 0; 
$tracelevel[3] = defined $cgi->param('level8') ? $cgi->param('level8') : 0; 
$tracelevel[4] = defined $cgi->param('level16') ? $cgi->param('level16') : 0; 
$tracelevel[5] = defined $cgi->param('level32') ? $cgi->param('level32') : 0; 

foreach $trace (@tracelevel) {
	if( $trace > 0){
			$options{trace}= defined $options{trace} ? ($options{trace} + $trace) : $trace;
	}
}

$options{forcepos} = $cgi->param('forcepos') if defined $cgi->param('forcepos');
$options{nocompoundify} = $cgi->param('nocompoundify') if defined $cgi->param('nocompoundify');
$options{usemono} = $cgi->param('usemono') if defined $cgi->param('usemono');
$options{backoff} = $cgi->param('backoff') if defined $cgi->param('backoff');

$doc_base=$ENV{'DOCUMENT_ROOT'};
open FH, '>', $filename or die "Cannot open $filename for writing: $!";
open IFH, '>', $inputfile or die "Cannot open $inputfile for writing: $!";

print FH "<Document Base>:$ENV{'DOCUMENT_ROOT'}\n";
print IFH "User Directory:$usr_dir\n";

print FH "<Contextfile>:$contextfilename\n";
print IFH "Contextfile:$contextfilename\n";

print FH "<Window size>:$windowSize\n";
print IFH "Window size:$windowSize\n";

print FH "<Format>:$format\n";
print IFH "Format:$format\n";

print FH "<Scheme>:$scheme\n";
print IFH "Scheme:$scheme\n";

while (($key, $value) = each %options) {
	print FH "<$key>:$value\n";
	print IFH "$key:$value\n";
}
close IFH;
close FH;


	# connect to allwords server
	 socket (Server, PF_INET, SOCK_STREAM, getprotobyname ($proto));

	 my $internet_addr = inet_aton ($remote_host) or do {
		 print "<p>Could not convert $remote_host to an IP address: $!</p>\n";
		 die;
			 };

			 my $paddr = sockaddr_in ($remote_port, $internet_addr);

			 unless (connect (Server, $paddr)) {
				 print "<p>Cannot connect to server $remote_host:$remote_port ($!)</p>\n";
			die;
                 }
select ((select (Server), $|=1)[0]);

print "<html>
<head>
<title>AllWords Disambiguation Results</title>
</head>
</html>";

die "can't fork: $!" unless defined($kidpid = fork());
# the if{} block runs only in the parent process
    if ($kidpid)
    {
  	    open RFH, '>', $resultfilename or print "Cannot open $resultfilename for writing: $!";
        # copy the socket to CGI output
		$traceflag=0;
        while (defined ($line = <Server>))
        {
			if( $line =~ /<start-of-trace>/)
			{
				$traceflag=1;
				open TFH, '>', $tracefilename or print "Cannot open $tracefilename for writing: $!";
			}
			elsif( $line =~ /<end-of-trace>/ )
			{
				$traceflag=0;
				close TFH;
			}
			elsif( $traceflag == 1)
			{
				print TFH "$line";
			}
			else
			{
				$line =~ s/</< /g;
				$line =~ s/>/ >/g;
				$line =~ s/\#o|\#NR|\#ND|\#IT|\#NT|\#CL|\#MW//g;
				print RFH $line;
				writetoCGI($line);
			}
        }
		close RFH;
        kill("TERM", $kidpid);                  # send SIGTERM to child
		print "<br><br>";
		if (defined $options{trace}) 
		{
				print $cgi->a({-href=>"/allwords/$usr_dir/trace.txt"},"See Trace output");
				print "<br><br>";
		}
		print $cgi->a({-href=>"/allwords/$usr_dir.tar.gz"},"Download");
		print " the complete tar ball of the result files.", $cgi->p;
		print $cgi->a({-href=>"/allwords/$usr_dir"},"Browse");
		print " your directory.", $cgi->p;
		$status=system("rm -rf $filename");
		if ($status) 
		{
			writetoCGI("\nCould not delete $filename.\n"); 
		}

		$status=system("tar -cvf $usr_dir.tar $usr_dir >& user_data/tar_log");
		if ($status) 
		{
			writetoCGI("\nError while creating the tar file of results.\n"); 
		}

		$status=system("gzip $usr_dir.tar");
		if ($status) 
		{
			writetoCGI("\nError while zipping the tar file of results.\n"); 
		}

		$status=system("mv $usr_dir.tar.gz $doc_base/allwords/user_data/");
		if ($status) 
		{
			writetoCGI("\nError while copying the tar file.\n");
		}

		$status=system("mv $usr_dir $doc_base/allwords/user_data/");
		if ($status) 
		{
			writetoCGI("\nCan not create user directory in $doc_base\n");
		}
    }
    # the else{} block runs only in the child process
    else
    {
		#send context file to the allwords server
		printf Server "<User Directory>:$usr_dir\n";
		open CFH, '<', "$context" or die "can't open context file $context for reading : $!";
		printf Server "<start-of-context>\015\012";

		while (defined ($line = <CFH>))
		{
		     printf Server "<con>:$line\015\012";
		}
		printf Server "<end-of-context>\015\012";
		close CFH;
		#send other options to the allwords server
		open FH, '<', $filename or die "Cannot open $filename for reading: $!";
			#copy CGI input to the socket
		while (defined ($line = <FH>))
		{
			 printf Server $line;
		}
		close FH;

		if(defined $options{stoplist})
		{
			open SFH, '<', "$usr_dir/"."$options{stoplist}" or die "can't open stoplist file $stoplist for reading : $!";
			printf Server "<start-of-stoplist>\015\012";
			while (defined ($line = <SFH>))
			{
				 printf Server "<stp>:$line\015\012";
			}
			printf Server "<end-of-stoplist>\015\012";
			close SFH;
		}
		print Server "<End>\0012\n";
		print "<p><a href=\"http://$hostname/allwords/allwords.html\">Start Over</a></p>";
    }



sub cleanLine
{
    	my $line = shift;
	chomp($line);
	my @words=split(/ +/,$line);
	foreach my $word (@words){
		next if($word eq "i.e." || $word eq "ie." || $word eq "et_al." || $word eq "al.");
		$word =~ s/([A-Z])/\L$1/g;
		if ($word =~ m/_/){
			$word =~ s/[.|!|?|,|;]+$/ /;
		}
		else{
			$word =~ s/[^$OK_CHARS]/ /g;
		}
	}
	return join (' ', @words);
}
	
sub writetoCGI
{
my $output=shift;
print <<EndHTML;
<html><head><title>Results</title></head>
<body>
$output<br>
EndHTML
}

sub getFileName
{
	my $path=shift;
	my $filename;
	my $result = rindex($path, "\/");
	if ($result eq -1) {
		$result = rindex($path, "\\");
	}
	$filename= substr $path, $result+1;
	return $filename;
}


=head1 NAME

allwords.cgi - [Web] CGI script implementing a portion of a web interface
for WordNet::SenseRelate::AllWords

=head1 DESCRIPTION

This script works in conjunction with allwords_server.pl to
provide a web interface for L<WordNet::SenseRelate::AllWords>. The html 
file, htdocs/allwords/allwords.html posts the data entered by the user 
to this script. The input data, in particular, the input context, stoplist
file and various disambiguation options are written in files 
and sent to the server line by line. Then it waits for the server to send 
results. After receiving results, they are displayed to the user. Moreover 
the user_data along with the tarball of result files is moved to 
htdocs/allwords/user_data directory, so that the user can refer to the results 
later.

=head1 AUTHORS

 Varada Kolhatkar, University of Minnesota, Duluth
 kolha002 at d.umn.edu

 Ted Pedersen, University of Minnesota, Duluth
 tpederse at d.umn.edu

This document last modified by : 
$Id: allwords.cgi,v 1.33 2009/05/27 19:56:24 kvarada Exp $

=head1 SEE ALSO

 L<allwords_server.pl> L<README.web.pod>

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

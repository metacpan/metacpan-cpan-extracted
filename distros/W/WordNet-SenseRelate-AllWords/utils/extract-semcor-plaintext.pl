#!/usr/bin/perl
use Getopt::Long;
use File::Spec;

my $key;
my $file;
my $semcor_dir;
my $word;
my $lemma;
my $pos;
my $sense;
my @words;
our $version;
our $help;

my $res = GetOptions (key => \$key, "semcor=s" => \$semcor_dir,
		      "file" => \$file, version => \$version, help => \$help );

unless ($res) {
    showUsage();
    exit 1;
}

if ($help) {
    showUsage("Long");
    exit;
}

if ($version) {
    print "extract-semcor-plaintext.pl - extract plain text from a semcor formatted file\n";
    print 'Last modified by : $Id: extract-semcor-plaintext.pl,v 1.2 2009/05/27 20:45:32 kvarada Exp $';
    print "\n";
    exit;
}

unless (defined $semcor_dir or defined $file) {
    showUsage();
    exit 2;
}

if ($semcor_dir) {
    unless (-e $semcor_dir) {
	print STDERR "Invalid directory '$semcor_dir'\n";
	showUsage();
	exit 3;
    }
}

my @files;
if ($semcor_dir) {
    # get the files we are going to process
    my $gpattern = File::Spec->catdir ($semcor_dir, 'brown1', 'tagfiles');
    $gpattern = File::Spec->catdir ($gpattern, 'br-*');
    @files = glob ($gpattern);
    $gpattern = File::Spec->catdir ($semcor_dir, 'brown2', 'tagfiles');
    $gpattern = File::Spec->catdir ($gpattern, 'br-*');
    push @files, glob ($gpattern);
}
else {
    @files = @ARGV;

    unless (scalar @files) {
	print STDERR "No input files specified\n";
	exit 4;
    }

    foreach my $f (@files) {
        unless (-e $f) {
	    print STDERR "File '$f' does not exist\n";
	    exit 5;
        }
    }
}

my $count=0;
foreach my $f (@files) {
    open (FH, '<', $f) or die "Cannot open $f: $!";
    while(<FH>){
	chomp;
	$sense=undef;
	$pos=undef;
	$word=undef;
	next if( $_ !~ /^<wf/ && $_ !~ /^<punc/);
	if(/^<wf/){
		($sense)=(/wnsn=(\d+)/);
		if(/cmd=ignore/){
			($pos, $word)=(/pos=(\S+)>(\S+)<\S+/);
			if(defined $key){
				$pos="CLOSED";
				$lemma="undef";
			}
		}elsif(/cmd=done/){
			($lemma)=(/lemma=(\S+) /);
			#if(!defined $word){
			#	($word)=(/>(\S+)<\/wf>/);
			#}
			# instead of taking lemma, take the original word. This improves POS accuracy. 
			($word)=(/>(\S+)<\/wf>/);
			if(defined $key){
				if($_ !~ /wnsn/){
					$pos = "CLOSED"; 
					$lemma="undef";
				}else{
					($wnsn)= (/wnsn=(\S+)/);
					if($wnsn !~ /;/ && $wnsn eq "0"){
						$pos = "CLOSED"; 
						$lemma="undef";
					}
				}
			}
			if(!defined $pos){
				($pos) = (/pos=(\S+) /);
			}
		}elsif(/cmd=tag/){	
			($pos,$word)=(/pos=(\S+)>(\S+)<\/wf>/);
			if(defined $key){
				$pos="CLOSED";
				$lemma="undef";
			}
		}
	}elsif(/^<punc/){
		($word)=(/<punc>(\S+)<\/punc>/);
		$pos=$word;
		if(defined $key){
			$pos="CLOSED";
			$lemma="undef";
		}
	}
	if($word eq "." || $word eq "?" || $word eq "!" || $word eq ";"){
		if(defined $key){
			print "$word\/$pos\/$lemma";
		}else{
			print "$word";
		}
		print "\n";
	}else{
		if(defined $key){
			print "$word\/$pos\/$lemma ";
		}else{
			print "$word ";
		}			
	}
	
    }
    close FH;
}

sub showUsage
{
   my $long = shift;
   print "Usage: extract-semcor-plaintext.pl {--semcor DIR | --file FILE [FILE ...]} [--key]\n";
   print "                          | {--help | --version}\n";
	

    if ($long) 
    {
    print <<'EOU';
Options:
   --semcor         name of directory containing Semcor
   --file           one or more semcor-formatted files
   --key            generate a key for scoring purposes from the input
   --help           show this help message
   --version        show version information

EOU
}
}

#!/usr/bin/perl
use Getopt::Long;
use strict;

# closed class words
use constant {CLOSED => 'CLOSED',
	      NOINFO => 'NOINFO'};

my %wnTag = (
    JJ => 'a',
    JJR => 'a',
    JJS => 'a',
    CD => 'a',
    RB => 'r',
    RBR => 'r',
    RBS => 'r',
    RP => 'r',
    WRB => CLOSED,
    CC => CLOSED,
    IN => 'r',
    DT => CLOSED,
    PDT => CLOSED,
    CC => CLOSED,
    'PRP$' => CLOSED,
    PRP => CLOSED,
    WDT => CLOSED,
    'WP$' => CLOSED,
    NN => 'n',
    NNS => 'n',
    NNP => 'n',
    NNPS => 'n',
    PRP => CLOSED,
    WP => CLOSED,
    EX => CLOSED,
    VBP => 'v',
    VB => 'v',
    VBD => 'v',
    VBG => 'v',
    VBN => 'v',
    VBZ => 'v',
    VBP => 'v',
    MD => 'v',
    TO => CLOSED,
    POS => undef,
    UH => CLOSED,
    '.' => undef,
    ':' => undef,
    ',' => undef,
    _ => undef,
    '$' => undef,
    '(' => undef,
    ')' => undef,
    '"' => undef,
    FW => NOINFO,
    SYM => undef,
    LS => undef,
    );

my $help;
my $version;
my $keyf;
my $ansf;
my $instances;

my $ok = GetOptions (
		     'ansfile=s' => \$ansf,	
		     'keyfile=s' => \$keyf,
		     version => \$version,
		     help => \$help,
		     );
$ok or exit 1;

if ($help) {
    showUsage ("Long");
    exit;
}

if ($version) {
    print "extract-semcor-contentwords.pl - extracts content words given an answer file (typically a plain text file\n";
    print "                                 extracted using extract-semcor-plaintext.pl which has been tagged using\n";
    print "                                 using a part of speech tagger) and a key file extracted using\n"; 
    print "                                 extract-semcor-plaintext.pl --key option.\n";
    print 'Last modified by : $Id: extract-semcor-contentwords.pl,v 1.5 2009/05/27 20:48:17 kvarada Exp $';
    print "\n";
    exit;
}



unless (defined $ansf and defined $keyf ) {
    showUsage();
    exit 1;
}


open (KFH, '<', $keyf) or die "Cannot open '$keyf': $!";
my(@key) = <KFH>;
close KFH;

open (AFH, '<', $ansf) or die "Cannot open '$ansf': $!";
my(@ans) = <AFH>;
close AFH;

for(my $i=0;$i<=$#key;$i++){
	chomp($key[$i]);
	chomp($ans[$i]);
	my @words=split(/ /,$key[$i]);
	my @awords=split(/ /,$ans[$i]);
	if($#words == $#awords ){
		for(my $j=0;$j<=$#words;$j++){	
			my ($w,$p,$lemma) = ($words[$j] =~ /(\S+)\/(\S+)\/(\S+)/);
			my ($aw,$ap) = ($awords[$j] =~ /(\S+)\/(\S+)/);
			if($p !~ /CLOSED/){
				print "$lemma#".$wnTag{$ap}." ";
			}
		}
		print "\n";
	}
	else{
		for(my $j=0;$j<=$#words;$j++){	
			printf STDERR "$words[$j] => ";
			printf STDERR "$awords[$j]" if defined $awords[$j];
			printf STDERR "\n";
		}
	}
}

sub showUsage
{
    my $long = shift;
    print "Usage: extract-semcor-contentwords.pl --ansfile FILE  --keyfile FILE | {--help}\n";

    if ($long) 
    {
	print "Options:\n";
       print "\t--ansfile            answer file\n";
       print "\t--keyfile            key file\n";
	print "\t--help               show this help message\n";
    }
}

#!/usr/bin/perl
use Getopt::Long;

# Penn tagset
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
my $file;

my $ok = GetOptions (
		     'file=s' => \$file,	
		     help => \$help,
		     version => \$version,
		     );
$ok or exit 1;

if ($help) {
    showUsage ("Long");
    exit;
}

if ($version) {
    print "convert-PENN-to-WN.pl - script that takes PENN tagged text (format per line: word PENNPOS) and converts it to WordNet tagged text \n";
    print 'Last modified by : $Id: convert-PENN-to-WN.pl,v 1.1 2009/05/25 18:37:30 kvarada Exp $';
    print "\n";
    exit;
}

unless (defined $file ) {
    showUsage();
    exit 1;
}

my $count=0;
open (FH, '<', $file) or die "Cannot open '$keyf': $!";
while(<FH>)
{
	chomp;
	my ($w,$p)=(/(\S+) (\S+)/);	
	if($p =~ /CLOSED/){
		print "$w $p\n";
	}else{
		print "$w ",$wnTag{$p},"\n";
	}
}	

sub showUsage
{
    my $long = shift;
    print "Usage: convert-PENN-to-WN.pl --file FILE | {--help}\n";

    if ($long) 
    {
	print "Options:\n";
       print "\t--file               PENN tagged text file (format per line: word PENNtag)\n";
	print "\t--help               show this help message\n";
    }
}


# Copyright Anders Ardö 1999
# Adopted to also calculate a normalized score by dividing with
# textsize
# Added URL-analysis subroutine

package PosCheck_MPCA_record;

use strict;
use Combine::XWI;
use Combine::LoadTermList;
use Combine::PosMatcher;
use Combine::Config;

my $tm;
#my @sites;
my $log;

#VALIDATE using MPCA classification
use Saa;
my $saa = new Saa();
my $wait=1;
my %MSG=('command'=>'call',
         'object'=>'classify',
         'function'=>'query'
         );
my ($host,$port)=split(':',Combine::Config::Get('MPCAHostPort'));
#my $host = 'localhost';
#my $port = '10203';

sub init_tm {
    # read in ei-thesaurus map
    $tm = new Combine::LoadTermList;
    my $configDir = Combine::Config::Get('configDir');
    $tm->LoadStopWordList("$configDir/stopwords.txt");
    $tm->LoadTermList("$configDir/topicdefinition.txt");

    #sitesOK.txt holds a list of sites that should always be included
    my $asub = "sub siteOK { my (\$url_str)=\@_; my \$x;\n";
    if (open(SITES,"<$configDir/sitesOK.txt")) {
	while(<SITES>) {
	    next if /^\s*#/; # comments
	    next if /^\s*$/; # empty lines
	    chop; 
	    my $pat = $_;
	    $asub .=  "\$x=\'$pat\';(\$url_str=~m|\$x|o) and return 1;\n";
	}
	close(SITES);
    }
    $asub .= "return 0;\n}\n";
    eval($asub);
    $log = Combine::Config::Get('LogHandle');
}
  
sub classify {
    my ($self,$xwi) = @_;
    check($xwi);
}

sub check {
    my ($xwi) = @_;

    # return true (1) if you want to keep the record
    # otherwise return false (0)
    if ( ref($tm) ne 'Combine::LoadTermList' ) { init_tm(); }
    $xwi->url_rewind;
    my $url_str="";
    my $t;
    while ($t = $xwi->url_get) { $url_str .= $t . ", "; }
    
    my $siteOK = &siteOK($url_str);

    my $cutoff_rel=10; #Class score must be above this % to be counted
    my $cutoff_norm=0.002; # normalised cutoff for summed normalised score
#    my $cutoff_norm_class=0.1; # normalised cutoff per class
    my $tot_cutoff=1; # non normalised cuttoff for summed total score
    
    my ($mt,$ht,$tt,$url,$title,$size,$k,$cl,$result);

    ($mt,$ht,$tt,$url,$title,$size) = Combine::PosMatcher::getTextXWI($xwi,0,$tm,1); # no stemming; simple text extraction

#FIX title med simpletexconv i Matcher!!
    my @ant_text=split('\s+',$tt); my $ant_text=$#ant_text + 1;
    if ( $ant_text <= 0 ) { $ant_text = 1; }
    my $text = join(' ', ($title,$mt,$ht,$tt)); #title, meta, headers, text
    my %text_res = Combine::PosMatcher::Match(\$text, $tm);

    my %res; # normalized summed score per class
    my %absres; # un-normalized summed score per class
    my $sumscore=0.0; #Total summed normalised score
    my $totScore=0; #Total summed non-normalised score
    foreach $k (keys %text_res) { 
#	print "T: $k $text_res{$k}\n";
	$res{$k}  = $text_res{$k} / $ant_text;
	$absres{$k}  = $text_res{$k};
	$sumscore += $text_res{$k} / $ant_text;
	$totScore += $text_res{$k};
    }

    my %tres = Combine::PosMatcher::GetTermsM();
    my $score = 0;
    my $class = "";
    foreach $cl (sort { $res{$b}<=>$res{$a}; } keys(%res)) {
	if ( ($totScore >= $tot_cutoff) && 
#	     ($res{$cl} >= $cutoff_norm_class) &&
	     ($sumscore >= $cutoff_norm)) {
	    my $p = 100 * $res{$cl} / $sumscore; #Normalized values
#	    my $p = 100 * $absres{$cl} / $totScore; #Absolute values
	    if ($p >= $cutoff_rel) {
		$score +=$absres{$cl};
		$class .= "$cl($absres{$cl} $res{$cl}), ";
	    }
	}
    }

    $MSG{'content'}="$text";
    my $pca = &send_query(\%MSG);
    if ( ($score > 1) || $siteOK || $pca>0.5) {
      $result=1; # OK

      urlanalys($url_str, $xwi);

      my $rscore = int($sumscore*1000 + 0.5);
      $xwi->topic_add('ALL', $totScore, $rscore,'','Pos');
      foreach $cl (split(', ',$class)) {
	  if ( $cl =~ /^([^\(]+)\(([\d\.]+) ([\d\.]+)\)$/ ) {
#	      print "Check: $cl; $1; $2; $3; $tres{$1};;\n"; ###AAAA
	      $rscore = int($3*1000 + 0.5);
	      $xwi->topic_add($1, $2, $rscore, $tres{$1},'Pos');
	  }
      }
    } else {
      $result=0; # Discard
    }
    my $validate = log($totScore+1.0) + 6.0*$pca;
      $xwi->topic_add('ALLpca', 1000*$pca, $validate+0.5,'','pca');
    if ( (! $siteOK) && ($validate < 4.0) ) { $result=0; } #DISCARD
#    print "$result(siteOK=$siteOK);$score(NORM=$sumscore,UNNORM=$totScore,PCA=$pca,VAL=$validate);$class\n  $url_str\n";
    $log->say("$result(siteOK=$siteOK);$score(NORM=$sumscore,UNNORM=$totScore,PCA=$pca,VAL=$validate);$class");
    return $result;
  }

sub send_query
{
    my $msg=shift;

    # warn "query_client(): before queue()";

    $saa->queue($host, $port, $msg, 
                arb_name => undef, arb => undef) || die($saa->{'err'} . "\n");

    # warn "query_client(): after queue()";

    my($ok, $sent, $received, $pending);
    $received = []; $sent = [];
    while(scalar(@$sent) < 1)
    {
#       ($ok, $sent, $received, $pending) = $saa->process(0.01);
        ($ok, $sent, $received, $pending) = $saa->process(10);
        $ok || die($saa->{'err'} . "\n");
    }
    if($wait)
    {
        while(scalar(@$received) < 1)
        {
#           ($ok, $sent, $received, $pending) = $saa->process(0.01);
            ($ok, $sent, $received, $pending) = $saa->process(10);
            $ok || die($saa->{'err'} . "\n");
        }
    }
    if ($received->[0]->{msg}->{result} ne 'ok') {
        print "$received->[0]->{msg}->{'result-text'}\n";
        return 0.5; ########################??????????????
    }
    return $received->[0]->{msg}->{score};
}

sub urlanalys {
    my ($url, $xwi) = @_;
    my $host; my $path;
  #selurl normalize?
   if ($url =~ m|http://([^/]+)/(.*)$|) {
        $host=$1; $path=$2;
	$host =~ s/:\d+$//;
	$host =~ s/%..$//;
    }
    my %a;
    if ( length($path) <= 1 ) { $a{'top'}=1; }
    elsif ( $path =~ /\/$|index[^\/]+$|welcome[^\/]+$|default[^\/]+$|home[^\/]+$/i) { $a{'start'}=1; }
    if ( ! ($host =~ /^[\d\.]+$/) ) {
	my @dom=split(/\./,$host);
	$a{'domain'}=$dom[$#dom];
	if ( $host =~ /\.edu$|\.ac\.uk$|\.edu\.au$|\.edu\.[a-z][a-z]$/ ) {
	    $a{'univ'}=1;
	} elsif ( $host =~ /\.au\.dk$|\.dtu\.dk$|\.ou\.dk$|\.kvl\.dk$|\.auc\.dk$|\.ku\.dk$|\.nbi\.dk$|\.sdu\.dk$|\.aau\.dk$|\.ruc\.dk$|\.gu\.se$|\.liu\.se$|\.kth\.se$|\.luth\.se$|\.lu\.se$|\.lth\.se$|\.chalmers\.se$|\.su\.se$|\.uu\.se$/ ) {
	    $a{'univ'}=1;
	}
    }
    if ( $path =~ /^~/ ) { $a{'pers'}=1;}
#Also autoclass med termerna nedan
    if ( $path =~ /personal/ ) { $a{'pers'}=1;}
#title =~ homepage
    if ( $path =~ /course|lesson|education|classes|seminar|teaching|learning|training|tutorial|graduate|teacher|lecture/i) { $a{'edu'}=1; }
    if ( $path =~ /product|brochure/i ) { $a{'prod'}=1; }
    if ( $path =~ /research|scien|faculty|project|academic|conference|workshop/i ) { $a{'scien'}=1; }
#go to base url (evt take two last domains and go to that url (eg www.geophys.uniwb.ch -> www.uniwb.ch)
#title =~ university
    if ( $path =~ /abstract|paper|publication|preprint|book|report|\/pubs\/|proceedings|isbn/i ) { $a{'abs'}=1;}

    foreach my $k (keys(%a)) {
	$xwi->robot_add($k,$a{$k});
    }
    return;
}

1;

__END__

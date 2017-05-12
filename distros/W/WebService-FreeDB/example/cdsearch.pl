#!/usr/bin/perl -w

use WebService::FreeDB;
use Data::Dumper;
$usage='cdsearch.pl [options] <keyword> <field>...
  <keyword>:   keyword for search
  <field>:     one or more of fields :artist|title|track|rest
               or categories:blues|classical|country|data|folk|jazz|misc|newage|reggae|rock|soundtrack
               (space sep.)
  or simply put an url of an CD for retrieving
  known options:
  --debug=[0,1,2,3]:   Debug information (default=0)
  -outformat=[std|Dumper|xml]:   Output format of selected discs
';
my $debuglevel = 0;
my $outformat = "std";


while (defined($ARGV[0]) && $ARGV[0] =~ /^-.+$/) {
  my $opt = shift;
  if ($opt =~ /-debug=(\d)/) {
	$debuglevel = $1;
  } elsif ($opt =~ /outformat=(std|dumper|xml)/i) {
	$outformat = $1;
  } else {
	print "unknown option:$opt\n";
	print $usage;
	exit 0;
  }
}
#if a cd-url is submitted - simply get this cd.
if($ARGV[0] =~ /http:\/\/www.freedb.org\/freedb_search_fmt.php/) {
  $cddb = WebService::FreeDB->new(DEBUG=>$debuglevel);
  my %discinfo = $cddb->getdiscinfo($ARGV[0]);
  if ($outformat =~ /Dumper/i) {$cddb->outdumper(\%discinfo)}
  elsif ($outformat =~/std/i) {$cddb->outstd(\%discinfo)}
  elsif ($outformat =~/xml/i) {$cddb->outxml(\%discinfo)}
  else {die "unknown outtype"}
  exit 0;
}
#if we have no further params nothing has to be done
if (!defined($ARGV[1])) {
  print $usage;
  exit 0;
}
$keyword = shift;

# lets analyse fileds and cats submitteed ...
for $arg (@ARGV) {
  if ($arg =~ /^(artist|title|track|rest)$/) {push(@fields,$arg)}
  elsif ($arg =~ /^(blues|classical|country|data|folk|jazz|misc|newage|reggae|rock|soundtrack)$/) {push(@cats,$arg)}
  else {print STDERR "Dont know what you mean:$arg!\n";print STDERR $usage;exit 1;}
}
# 1st lets create a object ...
#$debuglevel = 0; #maybe 0..3
#$keyword = "Fury in the Slaughterhouse"; #setting the keywords ...
#@fields = (artist,rest) # may combination from artist,titel,rest,track
$cddb = WebService::FreeDB->new(DEBUG=>$debuglevel);
#2nd gets a list of discs, which are matching to $keyword in @fields
%discs = $cddb->getdiscs($keyword,\@fields,\@cats);
#3rd asks user to select one or more of the found discs
@selecteddiscs = $cddb->ask4discurls(\%discs);
for my $url (@selecteddiscs) {
  #4th get the discinfo
  my %discinfo = $cddb->getdiscinfo($url);
  #5th prints the discinfo out
  if ($outformat =~ /Dumper/i) {$cddb->outdumper(\%discinfo)}
  elsif ($outformat =~/std/i) {$cddb->outstd(\%discinfo)}
  elsif ($outformat =~/xml/i) {$cddb->outxml(\%discinfo)}
  else {die "unknown outtype"}
}
#6th: We are happy !


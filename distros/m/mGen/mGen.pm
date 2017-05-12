package Bio::mGen;

$|=1;

use base 'Exporter';
@EXPORT    = qw($db_path $base_path $imput_path $fasta_path $cache_path @mGen_urls $mGen_url %gb_division mGen_reload_gene mGet_set mGet_desc mGet_list mGet_fasta mGet_gene mGen_invert_dna mGen_translate_table mGen_codon2aa);
@EXPORT_OK = qw($offset %db);

our $VERSION = '1.03';

our @mGen_urls=(),$mGen_url="";

our $offset = 3*3; # How many codons to use as a index !!! don't forget

open cfg_F,"base_path"; my $line=<cfg_F>; $line=~s/\r?\n//g; close cfg_F;

our $base_path="."; $base_path=$line if ($line ne "");
our $db_path="$base_path/db/";
our $cache_path="$base_path/db/cache/";
our $index_path="$base_path/db/index/";
our $fasta_path="$base_path/db/fasta/";
our $imput_path="$base_path/db/download/";

our $mirrors_url="http://www.cyber-indian.com/bioperl/mGen-mirrors";

if (! -e $db_path) {mkdir($db_path);}
if (! -e $cache_path) {mkdir($cache_path);}
if (! -e $fasta_path) {mkdir($fasta_path);}
if (! -e $index_path) {mkdir($index_path);}
if (! -e $imput_path) {mkdir($imput_path);}

# --- VARs ---

our %gb_division = (
'PRI' => 'primate sequences',
'ROD' => 'rodent sequences',
'MAM' => 'other mammalian sequences',
'VRT' => 'other vertebrate sequences',
'INV' => 'invertebrate sequences',
'PLN' => 'plant, fungal, and algal sequences',
'BCT' => 'bacterial sequences',
'VRL' => 'viral sequences',
'PHG' => 'bacteriophage sequences',
'SYN' => 'synthetic sequences',
'UNA' => 'unannotated sequences',
'EST' => 'EST sequences (expressed sequence tags)',
'PAT' => 'patent sequences',
'STS' => 'STS sequences (sequence tagged sites)',
'GSS' => 'GSS sequences (genome survey sequences)',
'HTG' => 'HTGS sequences (high throughput genomic sequences)',
'HTC' => 'HTC sequences (high throughput cDNA sequences)',);

print; # don't touch or compiler error

# --- SUBs ---

use LWP::Simple;
use Compress::Zlib;

sub file_size{my @s=stat(shift); return $s[7];}

sub mix_url{
if ($#mGen_urls==-1) {my $a=get($mirrors_url); @mGen_urls=split(/\n/,$a); $mGen_url=@mGen_urls[0];}
if ($#mGen_urls>0) {$mGen_url=@mGen_urls[int(rand($#mGen_urls+1))];}
}

sub mGen_reload_gene{
my $as=shift; my $entry="";
mix_url();
$entry=get("http:\/\/$mGen_url\?as=$as");
open entry_F,">$cache_path"."$as\.cache" or die "Error saving $as cache : $gzerrno";
binmode entry_F;
print entry_F $entry;
close entry_F;
}

sub mGet_set{mix_url(); return uncompress(get("http:\/\/$mGen_url\/?as=set"));}

sub mGet_desc{
my $as=shift; my $data,$entry="",$as_,$l,$a,$b,$c,$d;
if (! -e $cache_path."$as\.cache"){mix_url(); $entry=get("http:\/\/$mGen_url\?as=$as&ver=$VERSION"); open entry_F,">$cache_path"."$as\.cache" or die "Error saving $as cache : $gzerrno"; binmode entry_F; print entry_F $entry; close entry_F;}
if ($entry eq "") {open entry_F,"$cache_path"."$as\.cache" or die "Error loading $as cache : $gzerrno"; binmode entry_F; read(entry_F,$entry,file_size($cache_path."$as\.cache")); close entry_F;} if ($entry eq "") {return;}
($entry,$data)=$entry=~/(.*?)\|(.*)/s; ($as_,$a,$b,$c,$d)=split(",",$entry); $l=length($entry);
return uncompress(substr($data,0,$a));
}

sub mGet_list{
my ($as,$gn,)=@_; my $data,$entry="",$as_,$l,$a,$b,$c,$d;
if (! -e $cache_path."$as\.cache"){mix_url(); $entry=get("http:\/\/$mGen_url\?as=$as&ver=$VERSION"); open entry_F,">$cache_path"."$as\.cache" or die "Error saving $as cache : $gzerrno"; binmode entry_F; print entry_F $entry; close entry_F;}
if ($entry eq "") {open entry_F,"$cache_path"."$as\.cache" or die "Error loading $as cache : $gzerrno"; binmode entry_F; read(entry_F,$entry,file_size($cache_path."$as\.cache")); close entry_F;} if ($entry eq "") {return;}
($entry,$data)=$entry=~/(.*?)\|(.*)/s; ($as_,$a,$b,$c,$d)=split(",",$entry); $l=length($entry);
$a=uncompress(substr($data,$a,$b)); ($a,)=$a=~/^.*?\|\n(.*?)$/s;
if ($gn ne "") {($a,)=$a=~/(.*\|.*\|.*\|$gn\|.*)/m;}
return $a;
}

sub mGet_fasta{
my $as=shift; my $data,$entry="",$as_,$l,$a,$b,$c,$d;
if (! -e $cache_path."$as\.cache"){mix_url(); $entry=get("http:\/\/$mGen_url\?as=$as&ver=$VERSION"); open entry_F,">$cache_path"."$as\.cache" or die "Error saving $as cache : $gzerrno"; binmode entry_F; print entry_F $entry; close entry_F;}
if ($entry eq "") {open entry_F,"$cache_path"."$as\.cache" or die "Error loading $as cache : $gzerrno"; binmode entry_F; read(entry_F,$entry,file_size($cache_path."$as\.cache")); close entry_F;} if ($entry eq "") {return;}
($entry,$data)=$entry=~/(.*?)\|(.*)/s; ($as_,$a,$b,$c,$d)=split(",",$entry); $l=length($entry);
$a=uncompress(substr($data,$a+$b,$c)); ($a,)=$a=~/^.*?\|\n(.*?)$/s;
return $a;
}

sub mGet_gene{
my ($as,$gn,)=@_; my $data,$entry="",$as_,$l,$a,$b,$c,$d;
if (! -e $cache_path."$as\.cache"){mix_url(); $entry=get("http:\/\/$mGen_url\?as=$as&ver=$VERSION"); open entry_F,">$cache_path"."$as\.cache" or die "Error saving $as cache : $gzerrno"; binmode entry_F; print entry_F $entry; close entry_F;}
if ($entry eq "") {open entry_F,"$cache_path"."$as\.cache" or die "Error loading $as cache : $gzerrno"; binmode entry_F; read(entry_F,$entry,file_size($cache_path."$as\.cache")); close entry_F;} if ($entry eq "") {return;}
($entry,$data)=$entry=~/(.*?)\|(.*)/s; ($as_,$a,$b,$c,$d)=split(",",$entry); $l=length($entry);
$a=uncompress(substr($data,$a+$b+$c,$d)); ($a,)=$a=~/^.*?\|\n(.*?)$/s;
if ($gn ne "") {($a,)=$a=~/$gn\|(.*)/m;}
return $a;
}

sub crc64 {
use constant EXP => 0xd8000000;
my $text = shift;
my @highCrcTable=256, @lowCrcTable=256;
my $initialized=(); my $low=0, $high=0;
unless($initialized) {
  $initialized = 1;
  for my $i(0..255) {
    my $low_part  = $i;
    my $high_part = 0;
    for my $j(0..7) {
      my $flag = $low_part & 1; # rflag 1 is for all odd pays
      $low_part >>= 1;# um ein bit nach rechts verschieben
      $low_part |= (1 << 31) if $high_part & 1; # bit by bit or with 2147483648 (), if $$parth odd
      $high_part >>= 1; # around a bit after right-shifted
      $high_part ^= EXP if $flag;
    }
    $highCrcTable[$i] = $high_part;
    $lowCrcTable[$i]  = $low_part;
  }
}
foreach (split '', $text) {
  my $shr = ($high & 0xFF) << 24;
  my $tmph = $high >> 8;
  my $tmpl = ($low >> 8) | $shr;
  my $index = ($low ^ (unpack "C", $_)) & 0xFF;
  $high = $tmph ^ $highCrcTable[$index];
  $low  = $tmpl ^ $lowCrcTable[$index];
}
return sprintf("%08X%08X", $high, $low);
}

sub mGen_invert_dna{my $seq=reverse shift; $seq=~tr/ACGTacgt/TGCAtgca/; return $seq;}

#initialising a table
#my ($start,$stop,%aa)=translate_table(11);
#
#print "Start/Stop codons: $start\/$stop, GGG equals $aa{GGG}."\n";
#or
#print codon2aa($seq,$start,%aa);
#
sub mGen_translate_table{
my %translate; my $t = shift;
my %translate_aa = (
'1' => 'FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG',
'2' => 'FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSS**VVVVAAAADDEEGGGG',
'3' => 'FFLLSSSSYY**CCWWTTTTPPPPHHQQRRRRIIMMTTTTNNKKSSRRVVVVAAAADDEEGGGG',
'4' => 'FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG',
'5' => 'FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSSSSVVVVAAAADDEEGGGG',
'6' => 'FFLLSSSSYYQQCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG',
'9' => 'FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNNKSSSSVVVVAAAADDEEGGGG',
'10' => 'FFLLSSSSYY**CCCWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG',
'11' => 'FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG',
'12' => 'FFLLSSSSYY**CC*WLLLSPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG',
'13' => 'FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSSGGVVVVAAAADDEEGGGG',
'14' => 'FFLLSSSSYYY*CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNNKSSSSVVVVAAAADDEEGGGG',
'15' => 'FFLLSSSSYY*QCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG',
'16' => 'FFLLSSSSYY*LCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG',
'21' => 'FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNNKSSSSVVVVAAAADDEEGGGG',
'22' => 'FFLLSS*SYY*LCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG',
'23' => 'FF*LSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG',);
my %translate_start = (
'1' => '---M---------------M---------------M----------------------------',
'2' => '--------------------------------MMMM---------------M------------',
'3' => '----------------------------------MM----------------------------',
'4' => '--MM---------------M------------MMMM---------------M------------',
'5' => '---M----------------------------MMMM---------------M------------',
'6' => '-----------------------------------M----------------------------',
'9' => '-----------------------------------M---------------M------------',
'10' => '-----------------------------------M----------------------------',
'11' => '---M---------------M------------MMMM---------------M------------',
'12' => '-------------------M---------------M----------------------------',
'13' => '---M------------------------------MM---------------M------------',
'14' => '-----------------------------------M----------------------------',
'15' => '-----------------------------------M----------------------------',
'16' => '-----------------------------------M----------------------------',
'21' => '-----------------------------------M---------------M------------',
'22' => '-----------------------------------M----------------------------',
'23' => '--------------------------------M--M---------------M------------',);
my $B1 = "TTTTTTTTTTTTTTTTCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAGGGGGGGGGGGGGGGG";
my $B2 = "TTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGGTTTTCCCCAAAAGGGG";
my $B3 = "TCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAGTCAG";
my $start = "",$stop = "";my $Taa=$translate_aa{$t}, $Ts=$translate_start{$t};
for (my $i=0;$i<64;$i++) {
$translate{substr($B1,$i,1).substr($B2,$i,1).substr($B3,$i,1)}=substr($Taa,$i,1);
if (substr($Ts,$i,1) eq 'M') { if ($start eq "") {$start=substr($B1,$i,1).substr($B2,$i,1).substr($B3,$i,1);} else {$start.="|".substr($B1,$i,1).substr($B2,$i,1).substr($B3,$i,1);}}
if (substr($Taa,$i,1) eq '*') { if ($stop eq "") {$stop=substr($B1,$i,1).substr($B2,$i,1).substr($B3,$i,1);} else {$stop.="|".substr($B1,$i,1).substr($B2,$i,1).substr($B3,$i,1);}}
}
return ($start,$stop,%translate);
}

# ORFing
sub mGen_codon2aa{
my ($seq,$start,%translate)=@_; my $res; $seq =~ s/\r?\n//g;
if ($seq=~/^($start)/) {$res='M';} else {$res=$translate{substr($seq,0,3)};}
for (my $i=3;$i<length($seq);$i+=3) {$res.=$translate{substr($seq,$i,3)};}
return $res;
}

__END__

=head1 NAME

Bio::mGen - a fast and simple gene loading, helping automate BioPerl processes.

=head1 SYNOPSIS

  use Bio::mGen;

  print mGet_set();

or

  print mGet_desc($as);

or

  print mGet_list($as,$gn);

or

  print mGet_gene($as);

or

  print mGet_fasta($as);

or

  print mGet_gene($as,$gn);

or

  my $list=mGet_list($as,$gn);
  my ($prot,$crc,$gene_index,$gn,$size,$range,$list,$pol,$desc,$xtra,)=split(/\|/,$list);
  print "Gene: $gn, Size: $size, Polarity: $pol\nDescription: $desc\n\n";

or

  mGen_reload_gene($as);

or

  print "PRI division => ".$gb_division{PRI}."\n";

or

  print "ACTG inverted is ".mGen_invert_dna('ACTG')."\n";

or

  my ($start,$stop,%aa)=mGen_translate_table(11);
  print "Start/Stop codons: $start \/ $stop, GGG equals $aa{GGG}\n";
  print "ATGGATTACTGA => ".mGen_codon2aa("ATGGATTACTGA",$start,%aa)."\n";

=head1 DESCRIPTION

C<Bio::mGen> This module extracts pre-parsed compressed DNA from "Genbank" and "Refseq" (soon more) databases without draining the NCBI web server resources.
Guaranteed to work faster than any module because of the features: Parse-free, compression ensuring twice twice faster download and reading from local disk, caching leading to instant load next time you use the data, and also mirroring.

=head2 Functions

=over

=item C<get_desc>

Gives AS's Desciption & summary.

=item C<get_list>

List of genes' descriptions for the particular AS, gene name is optinal.

=item C<get_fasta>

Reads particular AS whole sequence in fasta format.

=item C<get_gene>

Reads parsed gene or list of genes for the particular AS. Gene name is optinal - leads to single gene output.

=item C<reload_gene>

Updates the cache file.

=item C<translate_table>

Loads the desirable translation table.

=back

=head1 EXPORTS

C<Bio::mGen> exports the C<$db_path $base_path $imput_path $fasta_path $cache_path @mGen_urls $mGen_url %gb_division> by default, and C<$offset> by non-default.

=head1 AUTHOR

Ivan M Nanev, E<lt>cyber_indian at hotmail.comE<gt>

Bug reports welcome, patches even more welcome.

=cut
